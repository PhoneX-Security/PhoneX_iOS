//
// Created by Matej Oravec on 21/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class hr_authCheckV3Response;
@class PEXDbUserProfile;
@class hr_accountInfoV1Response;

extern NSString * const PEX_LICENCE_TYPE_TRIAL;
extern NSString * const PEX_LICENCE_TYPE_FULL;

@interface PEXLicenceInfo : NSObject <NSCopying>

- (id) initWithDbUserProfile: (const PEXDbUserProfile * const) profile;
- (id) initWithV3Response: (const hr_authCheckV3Response * const) response;
- (id) initWithV1Response: (const hr_accountInfoV1Response * const) response;

@property (nonatomic) NSString * licenseType;
@property (nonatomic) NSDate * licenseIssuedOn;
@property (nonatomic) NSDate * licenseExpiresOn;
@property (nonatomic, assign) bool licenseExpired;

- (NSString *) getLicenseTypeHumanString;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToLicenceInfo:(PEXLicenceInfo *)info;

- (NSUInteger)hash;

- (id)copyWithZone:(NSZone *)zone;

@end