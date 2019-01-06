//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXUser : NSObject

@property (nonatomic) NSString *email;

- (BOOL)isEqualToUser:(PEXUser *)user;

- (NSUInteger)hash;

@end