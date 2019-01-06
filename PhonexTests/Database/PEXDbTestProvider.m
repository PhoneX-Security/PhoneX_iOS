//
// Created by Matej Oravec on 27/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbTestProvider.h"
#import "PEXDbContentProvider_Protected.h"
#import "PEXURIMatcher.h"
#import "PEXDbTestEntity.h"


#define PEX_URIID_TESTENTITY 9
#define PEX_URIID_TESTENTITY_ID 10

@implementation PEXDbTestProvider {

}

// Resolves URI to our identifier.
-(int) getURIId: (const PEXDbUri * const) uri{
    // Static URI matching initialization.
    static PEXURIMatcher * uriMatcher = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        uriMatcher = [[PEXURIMatcher alloc] init];

        // Add our DB models and supported URIs here.
        // Has to be done manually. This design is OK for now.
        // Later, if necessary, this can be refactored to register/unregister design.
        //
        // TestEntity
        [uriMatcher addURI:[PEXDbTestEntity getURI]     idx:PEX_URIID_TESTENTITY];
        [uriMatcher addURI:[PEXDbTestEntity getURIBase] idx:PEX_URIID_TESTENTITY_ID];
    });

    // Call matcher on given URI.
    return [uriMatcher match:uri];
}

// Returns default table name for the registered URI based on its ID.
-(NSString *) getTableFromID: (int) uriID {
    switch(uriID){
        case PEX_URIID_TESTENTITY:
        case PEX_URIID_TESTENTITY_ID:
            return @TESTENTITY_TABLE_NAME;
        default:
            return nil;
    }
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


@end