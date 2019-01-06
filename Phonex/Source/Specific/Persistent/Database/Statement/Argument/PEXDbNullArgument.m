//
// Created by Dusan Klinec on 30.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <sqlite3.h>
#import "PEXDbNullArgument.h"
#import "PEXDbStatement.h"


@implementation PEXDbNullArgument {

}

- (int) addToStatement: (PEXDbStatement * const) statement at:(const int) position
{
    return sqlite3_bind_null(statement.statement, position);
}

@end