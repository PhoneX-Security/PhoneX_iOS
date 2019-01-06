//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXUser.h"


@implementation PEXUser {

}

- (BOOL)isEqualToUser:(PEXUser *)user
{
    if (self == user)
        return YES;
    if (user == nil)
        return NO;
    return !(self.email != user.email && ![self.email isEqualToString:user.email]);
}

- (NSUInteger)hash
{
    return [self.email hash];
}

@end