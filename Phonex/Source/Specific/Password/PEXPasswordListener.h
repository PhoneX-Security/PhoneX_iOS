//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXPasswordListener <NSObject>

// the password was set
- (void) passwordSet: (NSString * const) newPassword;

@end