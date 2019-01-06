//
// Created by Matej Oravec on 23/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <sqlite3.h>
#import "PEXDbTextArgument.h"
#import "PEXDbStatement.h"

@interface PEXDbTextArgument ()

@property (nonatomic) NSString * text;

@end

@implementation PEXDbTextArgument {

}

- (id)initWithString:(NSString *const)text
{
    self = [super init];

    self.text = text;

    return self;
}

- (int) addToStatement: (PEXDbStatement * const) statement at:(const int) position
{
    char const * utf8Encoded = [self.text UTF8String];
    return sqlite3_bind_text(statement.statement, position, utf8Encoded, strlen(utf8Encoded), nil);
}

@end