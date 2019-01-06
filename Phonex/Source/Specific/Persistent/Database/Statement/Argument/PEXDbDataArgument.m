//
// Created by Matej Oravec on 23/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <sqlite3.h>
#import "PEXDbDataArgument.h"
#import "PEXDbStatement.h"

@interface PEXDbDataArgument ()

@property (nonatomic) NSData * data;

@end

@implementation PEXDbDataArgument {

}

- (id)initWithData:(NSData *const)data
{
    self = [super init];

    self.data = data;

    return self;
}

- (int) addToStatement: (PEXDbStatement * const) statement at:(const int) position
{
    return sqlite3_bind_blob(statement.statement, position, [self.data bytes], self.data.length, nil);
}

@end