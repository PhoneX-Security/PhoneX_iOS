//
// Created by Matej Oravec on 23/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <sqlite3.h>
#import "PEXDbNumberArgument.h"
#import "PEXDbStatement.h"

@interface PEXDbNumberArgument ()

@property (nonatomic) NSNumber * number;

@end

@implementation PEXDbNumberArgument {

}

- (id)initWithNumber:(NSNumber *const)number
{
    self = [super init];

    self.number = number;

    return self;
}

// TODO seek better solution ... find the Ring
- (int) addToStatement: (PEXDbStatement * const) statement at:(const int) position
{
    int result = 0;
    const char * const type = [self.number objCType];

    // initWIthLongLOng isnt so easy
    // The function may get a NSNumber inited with Long Long but here it will
    // look like int when inited with a value from interval [-1, 12]
    // http://stackoverflow.com/questions/15983048/objective-c-nsnumber-numberwithlonglong-creates-integer

    if (strcmp(type, [self doubleType]) == 0)
    {
        result = sqlite3_bind_double(statement.statement, position, self.number.doubleValue);
    }
    else if (strcmp(type, [self intType]) == 0)
    {
        result = sqlite3_bind_int(statement.statement, position, self.number.intValue);
    }
    else if (strcmp(type, [self int64Type]) == 0)
    {
        result = sqlite3_bind_int64(statement.statement, position, self.number.longLongValue);
    }
    else if (strcmp(type, [self boolType]) == 0)
    {
        result = sqlite3_bind_int(statement.statement, position, self.number.boolValue);
    }
    else
    {
        [NSException raise:@"Invalid NSNumber type" format:@"number type: %s", [self.number objCType]];
    }

    return result;
}

// TODO the following look like a crap
// Author

- (const char * const) doubleType
{
    static const char * result;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[[NSNumber alloc] initWithDouble:1.2] objCType];
    });

    return result;
}

- (const char *) intType
{
    static const char * result;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[[NSNumber alloc] initWithInt:1] objCType];
    });

    return result;
}

- (const char *)int64Type
{
    static const char * result;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // must be out of interval [-1, 12] ... see addToStatement
        result = [[[NSNumber alloc] initWithLongLong:100LL] objCType];
    });

    return result;
}

- (const char *) boolType
{
    static const char * result;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[[NSNumber alloc] initWithBool:true] objCType];
    });

    return result;
}

@end