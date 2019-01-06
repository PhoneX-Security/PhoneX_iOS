//
//  PEXCredentials.m
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXCredentials.h"
#import "PEXUtils.h"

@implementation PEXCredentials
- (instancetype)initWithPassword:(NSString *)password username:(NSString *)username {
    self = [super init];
    if (self) {
        self.password = password;
        self.username = username;
    }

    return self;
}

+ (instancetype)credentialsWithPassword:(NSString *)password username:(NSString *)username {
    return [[self alloc] initWithPassword:password username:username];
}


- (BOOL)isMissingData {
    return [PEXUtils isEmpty:_username] || [PEXUtils isEmpty:_password];
}

@end
