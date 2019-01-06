//
// Created by Matej Oravec on 28/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbContentProvider.h"
#import "PEXDbContentProvider_Protected.h"
#import "PEXDatabase.h"
#import "PEXDbUri.h"
#import "PEXDbContentValues.h"
#import "PEXDbTextArgument.h"
#import "PEXDbNumberArgument.h"
#import "PEXDbDataArgument.h"
#import "PEXURIMatcher.h"
#import "PEXContentObserver.h"
#import "PEXDbNullArgument.h"
#import "PEXService.h"

@interface PEXDbContentProvider ()

@property (nonatomic) NSMutableArray * observers;
@property (nonatomic) NSMutableArray * observersInsert;
@property (nonatomic) NSMutableArray * observersDelete;
@property (nonatomic) NSMutableArray * observersUpdate;

@property (nonatomic) NSLock * volatile observersLock;

@end

@implementation PEXDbContentProvider {

}

- (id)init
{
    self = [super init];

    self.observersLock = [[NSLock alloc] init];
    self.observers = [[NSMutableArray alloc] init];
    self.observersInsert = [[NSMutableArray alloc] init];
    self.observersDelete = [[NSMutableArray alloc] init];
    self.observersUpdate = [[NSMutableArray alloc] init];

    return self;
}

// Returns default table name for the registered URI based on its ID.
-(NSString *) getTableFromID: (int) uriID
{
    [NSException raise:@"abstract" format:@"abstract"];
    return nil;
}

// Resolves URI to table name, if found. Exception is thrown otherwise.
-(NSString *) getTableFromURIOrThrow: (const PEXDbUri * const) uri {
    int uriID = [self getURIId:uri];
    if (uriID == PEXURIMatcher_URI_NOT_FOUND){
        [NSException raise:@"IllegalArgumentException" format:@"URI not found"];
    }

    NSString * tableName = [self getTableFromID:uriID];
    return tableName;
}

// PROJECTION QUERIES
- (PEXDbCursor *) query: (const PEXDbUri * const) uri
             projection: (const NSArray * const) projection
              selection: (NSString * const) selection
          selectionArgs: (const NSArray * const) selectionArgs
              sortOrder: (NSString * const) sortOrder
{
    if (projection == nil || projection.count == 0){
        [NSException raise:@"IllegalArgumentException" format:@"Projection cannot be empty"];
    }

    NSString * tableName = [self getTableFromURIOrThrow:uri];
    NSMutableString * const query = [[NSMutableString alloc] initWithString:@"SELECT "];
    [query appendString:projection[0]];

    for (NSUInteger i = 1; i < projection.count; ++i)
    {
        [query appendString:@", "];
        [query appendString:projection[i]];
    }

    [query appendString:@" FROM "];
    [query appendString:tableName];

    if (selection != nil) {
        [query appendString:@" "];
        [query appendString:selection];
    }

    if (sortOrder != nil) {
        [query appendString:@" "];
        [query appendString:sortOrder];
    }

    return [self queryRaw:query selectionArgs:selectionArgs];
}

- (PEXDbCursor *) queryRaw: (NSString * const) query selectionArgs: (const NSArray * const) selectionArgs{
    NSMutableArray * argList = [[NSMutableArray alloc] initWithCapacity:selectionArgs.count];
    [self addSelectionArgs:selectionArgs to:argList];

    return [PEXDatabase prepareCursor:[query UTF8String] arguments: argList];
}

- (const PEXDbUri * const) insert: (const PEXDbUri * const) uri
      contentValues:(const PEXDbContentValues * const)contentValues
{
    NSString * tableName = [self getTableFromURIOrThrow:uri];
    NSMutableString * const query = [[NSMutableString alloc] initWithString:@"INSERT INTO "];
    [query appendString:tableName];
    [query appendString:@" ("];

    NSArray * const keyList = [[contentValues keySet] allObjects];
    NSMutableArray * argList = [[NSMutableArray alloc] initWithCapacity:keyList.count];

    // the first column
    [self addSqlArg:keyList[0]
      contentValues:contentValues
            argList:argList query:query];

    NSMutableString * const preparedArgs = [[NSMutableString alloc] initWithString:@"?"];

    // other columns if any
    for (NSUInteger i = 1; i < keyList.count; ++i)
    {
        [query appendString:@", "];

        [self addSqlArg:keyList[i]
          contentValues:contentValues
                argList:argList query:query];

        [preparedArgs appendString:@", ?"];
    }

    // final string appendings
    [query appendString:@") VALUES ("];
    [query appendString:preparedArgs];
    [query appendString:@")"];

    // TODO return generated keys
    const bool insertSuccess = [PEXDatabase executePrepared:[query UTF8String] arguments:argList];

    if (insertSuccess)
    {
        const PEXDbUri * const resultUri =
            [[PEXDbUri alloc] initWithURI:uri
                                    andID:[PEXDatabase idOfLastInsertedRow]];

        [self dispatchChangeAsyncInsert:true withUri:resultUri];
        return resultUri;
    } else {
        DDLogError(@"Insert was not successful, uri=%@", uri);
    }

    return nil;
}

- (bool) update:(const PEXDbUri * const) uri
  ContentValues: (const PEXDbContentValues * const)contentValues
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs
{
    return [self updateEx:uri ContentValues:contentValues selection:selection selectionArgs:selectionArgs] >= 0;
}

- (int) updateEx:(const PEXDbUri * const) uri
  ContentValues: (const PEXDbContentValues * const)contentValues
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs
{
    static NSString * const UPDATE_VALUE_ASSIGN = @"=?";
    NSString * tableName = [self getTableFromURIOrThrow:uri];
    NSMutableString * const query = [[NSMutableString alloc] initWithString:@"UPDATE "];
    [query appendString:tableName];
    [query appendString:@" SET "];

    NSArray * const keyList = [[contentValues keySet] allObjects];
    NSMutableArray * argList = [[NSMutableArray alloc] initWithCapacity:keyList.count + selectionArgs.count];

    // the first column
    [self addSqlArg:keyList[0]
      contentValues:contentValues
            argList:argList query:query];
    [query appendString:UPDATE_VALUE_ASSIGN];

    // other columns if any
    for (NSUInteger i = 1; i < keyList.count; ++i)
    {
        [query appendString:@","];

        [self addSqlArg:keyList[i]
          contentValues:contentValues
                argList:argList query:query];

        [query appendString:UPDATE_VALUE_ASSIGN];
    }

    if (selection)
    {
        [query appendString:@" "];
        [query appendString:selection];

        [self addSelectionArgs:selectionArgs to:argList];
    }

    const int result = [PEXDatabase executePreparedEx:[query UTF8String] arguments:argList];

    if (result >= 0)
    {
        [self dispatchChangeAsyncUpdate:true withUri:uri];
    }

    return result;
}

- (bool) delete:(const PEXDbUri * const) uri
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const ) selectionArgs
{
    return [self deleteEx:uri selection:selection selectionArgs:selectionArgs] >= 0;
}

- (int) deleteEx:(const PEXDbUri * const) uri
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const ) selectionArgs
{
    NSString * tableName = [self getTableFromURIOrThrow:uri];
    NSMutableString * const query = [[NSMutableString alloc] initWithString:@"DELETE FROM "];
    [query appendString:tableName];
    [query appendString:@" "];

    NSMutableArray * argList = [[NSMutableArray alloc] initWithCapacity: selectionArgs.count];

    if (selection)
    {
        [query appendString:selection];
        [self addSelectionArgs:selectionArgs to:argList];
    }

    const int result = [PEXDatabase executePreparedEx:[query UTF8String] arguments:argList];

    if (result >= 0)
    {
        [self dispatchChangeAsyncDelete:true withUri:uri];
    }

    return result;
}

// TODO do it with transactions or multiplerow insert
- (bool) bulk:(const PEXDbUri * const) uri
       insert:(const NSArray * const)contentValuesArray
{
    bool result = true;
    for (PEXDbContentValues * const cv in contentValuesArray)
    {
        if (![self insert:uri contentValues:cv])
        {
            result = false;
            break;
        }
    }

    return result;
}

- (bool) testDatabaseRead: (int *) pStatus{
    return [[PEXDatabase instance] testDatabaseRead:pStatus];
}

- (void) addSelectionArgs: (const NSArray * const) selectionArgs
                       to: (NSMutableArray * const) argList
{
    if (selectionArgs) {
        for (id currentSelectionArg in selectionArgs) {
            NSString * selectionArg = nil;
            if ([currentSelectionArg isKindOfClass:[NSString class]]) {
                selectionArg = (NSString *const) currentSelectionArg;
                [argList addObject:[[PEXDbTextArgument alloc] initWithString:selectionArg]];
                continue;

            } else if ([currentSelectionArg isKindOfClass:[NSNumber class]]){
                NSNumber * numArg = (NSNumber *const) currentSelectionArg;
                [argList addObject:[[PEXDbNumberArgument alloc] initWithNumber:numArg]];
                continue;

            } else {
                DDLogWarn(@"Implicit string conversion in query, obj=%@", currentSelectionArg);
                selectionArg = [currentSelectionArg description];
                [argList addObject:[[PEXDbTextArgument alloc] initWithString:selectionArg]];
                continue;
            }
        }
    }
}


- (void) addSqlArg: (NSString * const) key
     contentValues: (const PEXDbContentValues * const)contentValues
           argList: (NSMutableArray * const) argList
             query: (NSMutableString * const) query
{
    id value = [contentValues get:key];
    const Class valueClass = [value class];

    if ([value isKindOfClass:[NSString class]])
    {
        [argList addObject:[[PEXDbTextArgument alloc] initWithString:value]];
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        [argList addObject:[[PEXDbNumberArgument alloc] initWithNumber:value]];
    }
    else if ([value isKindOfClass:[NSData class]])
    {
        [argList addObject:[[PEXDbDataArgument alloc] initWithData:value]];
    }
    else if ([value isKindOfClass:[NSNull class]])
    {
        [argList addObject:[[PEXDbNullArgument alloc] init]];
    }
    else
    {
        [NSException raise:@"Invalid value type" format:@"key: %@ for valueType: %@", key, valueClass];
    }

    [query appendString:key];
}

// Resolves URI to our identifier.
-(int) getURIId: (const PEXDbUri * const) uri
{
    [NSException raise:@"abstract" format:@"abstract"];
    return 0;
}

// OBSERVING SECTION

- (void) unregisterAll
{
    [self.observersLock lock];
    [self.observers removeAllObjects];
    [self.observersDelete removeAllObjects];
    [self.observersInsert removeAllObjects];
    [self.observersUpdate removeAllObjects];
    [self.observersLock unlock];
}


#define PEX_GENERATE_REGISTER_OBSERVER(xyz) - (void) registerObserver##xyz :(id<PEXContentObserver>) observer\
{\
    [self.observersLock lock];\
    [self.observers##xyz addObject:observer];\
    [self.observersLock unlock];\
}

PEX_GENERATE_REGISTER_OBSERVER(Update)
PEX_GENERATE_REGISTER_OBSERVER(Delete)
PEX_GENERATE_REGISTER_OBSERVER(Insert)
PEX_GENERATE_REGISTER_OBSERVER()


#define PEX_GENERATE_UNREGISTER_OBSERVER(xyz) - (void) unregisterObserver##xyz :(id<PEXContentObserver>) observer\
{\
    [self.observersLock lock];\
    [self.observers##xyz removeObject:observer];\
    [self.observersLock unlock];\
}

PEX_GENERATE_UNREGISTER_OBSERVER(Update)
PEX_GENERATE_UNREGISTER_OBSERVER(Delete)
PEX_GENERATE_UNREGISTER_OBSERVER(Insert)
PEX_GENERATE_UNREGISTER_OBSERVER()

#define PEX_GENERATE_DISPATCH_CHANGE(xyz) - (void) dispatchChange##xyz :(const bool) selfChange withUri: (const PEXUri * const) uri\
{\
    NSArray * copy; \
    NSArray * copy##xyz; \
    [self.observersLock lock];\
    copy = [[NSArray alloc] initWithArray:self.observers];                \
    copy##xyz = [[NSArray alloc] initWithArray:self.observers##xyz];                \
    [self.observersLock unlock];\
                    \
\
    for (id<PEXContentObserver> observer in copy )\
    {\
        [observer dispatchChange :selfChange uri:uri];\
    }\
\
    for (id<PEXContentObserver> observer in copy##xyz )\
    {\
        [observer dispatchChange##xyz :selfChange uri:uri];\
    }\
}

PEX_GENERATE_DISPATCH_CHANGE(Update)
PEX_GENERATE_DISPATCH_CHANGE(Delete)
PEX_GENERATE_DISPATCH_CHANGE(Insert)
//PEX_GENERATE_DISPATCH_CHANGE()

#define PEX_GENERATE_DISPATCH_CHANGE_ASYNC(xyz) - (void) dispatchChangeAsync##xyz :(const bool) selfChange withUri: (const PEXUri * const) uri\
{                                                                                                 \
    [PEXService executeOnGlobalQueueWithName:nil async:YES block: ^(void)                         \
    {                                                                                             \
       [self dispatchChange##xyz :selfChange withUri:uri];                                        \
    }];                                                                                           \
}

PEX_GENERATE_DISPATCH_CHANGE_ASYNC(Update)
PEX_GENERATE_DISPATCH_CHANGE_ASYNC(Delete)
PEX_GENERATE_DISPATCH_CHANGE_ASYNC(Insert)
//PEX_GENERATE_DISPATCH_CHANGE_ASYNC()

@end