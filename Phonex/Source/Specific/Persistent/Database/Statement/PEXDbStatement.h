//
// Created by Matej Oravec on 22/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>


@interface PEXDbStatement : NSObject
{
@private
    sqlite3_stmt * _statement;
}

- (void) finalize;

- (sqlite3_stmt *) statement;
- (void) statement: (sqlite3_stmt * const) statement;

@end