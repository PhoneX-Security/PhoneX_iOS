//
// Created by Matej Oravec on 22/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbStatement.h"


@implementation PEXDbStatement {
}

- (sqlite3_stmt *) statement { return _statement; }
- (void) statement: (sqlite3_stmt * const) statement { _statement = statement; }

- (void) finalize
{
    [self finalizeInternal];
}

- (void) finalizeInternal
{
    if (_statement != nil)
    {
        sqlite3_finalize(_statement);
        _statement = nil;
    }
}

- (void) dealloc
{
    [self finalizeInternal];
}

@end