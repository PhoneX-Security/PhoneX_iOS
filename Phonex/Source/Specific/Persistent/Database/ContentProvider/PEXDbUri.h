//
// Created by Matej Oravec on 26/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXUri.h"

@interface PEXDbUri : PEXUri
@property (nonatomic, readonly) NSNumber * itemId;

- (instancetype)initWithTableName:(NSString *) tableName;
- (instancetype)initWithTableName:(NSString *) tableName isBase: (BOOL) base;
- (instancetype)initWithTableName:(NSString *) tableName andID: (int64_t) id;

- (instancetype)initWithURI:(const PEXUri * const) uri;
- (instancetype)initWithURI:(const PEXUri * const) uri andID: (int64_t) id;

- (BOOL) matchesBase:(const PEXUri *const)aUri;
- (BOOL) matches: (const PEXUri * const) aUri;
- (NSString *) uri2string;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToDbUri:(PEXDbUri *)uri;
- (NSUInteger)hash;
@end