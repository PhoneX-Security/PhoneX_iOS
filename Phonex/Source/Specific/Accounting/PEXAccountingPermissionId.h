//
// Created by Dusan Klinec on 02.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbAccountingPermission;


@interface PEXAccountingPermissionId : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSNumber * permId;
@property(nonatomic) NSNumber * licId;

- (instancetype)initWithLicId:(NSNumber *)licId permId:(NSNumber *)permId;
+ (instancetype)idWithLicId:(NSNumber *)licId permId:(NSNumber *)permId;
- (instancetype)initWithPermission:(PEXDbAccountingPermission *)per;
+ (instancetype)idWithPermission:(PEXDbAccountingPermission *)per;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToId:(PEXAccountingPermissionId *)permissionId;
- (NSUInteger)hash;
- (NSString *)description;

@end