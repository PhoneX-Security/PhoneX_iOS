//
// Created by Matej Oravec on 28/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXUri : NSObject <NSCoding>

- (BOOL) matchesBase:(const PEXUri *const)aUri;
- (BOOL) matches: (const PEXUri * const)aUri;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToUri:(const PEXUri * const)uri;
- (NSUInteger)hash;
- (NSString *)description;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *) uri2string;
- (NSString *) baseUri2string;
@end