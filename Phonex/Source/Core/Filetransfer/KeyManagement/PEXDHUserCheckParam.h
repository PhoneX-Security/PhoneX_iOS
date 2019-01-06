//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXDHUserCheckParam : NSObject <NSCoding, NSCopying>
/**
* User identifier for certificate refresh.
*/
@property(nonatomic) NSString * user;

/**
* Force user certificate check on the server side.
* If set to NO and certificate was checked recently, it won't be checked again.
*/
@property(nonatomic) BOOL forceRecheck;

- (instancetype)initWithUser:(NSString *)user;
+ (instancetype)paramWithUser:(NSString *)user;
- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck;
+ (instancetype)paramWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToParam:(PEXDHUserCheckParam *)param;
- (NSUInteger)hash;
- (NSString *)description;
@end