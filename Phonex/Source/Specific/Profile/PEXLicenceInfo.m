//
// Created by Matej Oravec on 21/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLicenceInfo.h"
#import "PEXDBUserProfile.h"

#import "hr.h"

NSString * const PEX_LICENCE_TYPE_TRIAL_STRING = @"trial";
NSString * const PEX_LICENCE_TYPE_FULL_STRING = @"full";


@implementation PEXLicenceInfo {

}

- (id) initWithDbUserProfile: (const PEXDbUserProfile * const) profile
{
    self = [super init];

    self.licenseType = profile.licenseType;
    self.licenseIssuedOn = profile.licenseIssuedOn;
    self.licenseExpiresOn = profile.licenseExpiresOn;
    self.licenseExpired = profile.licenseExpired;

    return self;
}

- (id) initWithV3Response: (const hr_authCheckV3Response * const) response
{
    self = [super init];

    self.licenseExpiresOn = response.accountExpires;
    self.licenseIssuedOn = response.accountIssued;
    self.licenseType = response.licenseType;
    self.licenseExpired = [PEXDateUtils date:response.accountExpires isOlderThan:response.serverTime];

    return self;
}

- (id) initWithV1Response: (const hr_accountInfoV1Response * const) response
{
    self = [super init];

    self.licenseExpiresOn = response.accountExpires;
    self.licenseIssuedOn = response.accountIssued;
    self.licenseType = response.licenseType;
    self.licenseExpired = [PEXDateUtils date:response.accountExpires isOlderThan:response.serverTime];

    return self;
}

- (NSString *)description
{
    return
            [NSString stringWithFormat:@"Licence Information:\ntype = %@\nissued on = %@\nexpires on = %@\nexpired = %d",
                            self.licenseType, self.licenseIssuedOn.description,
                            self.licenseExpiresOn.description, self.licenseExpired];
}

- (bool) isTrial
{
    return [self.licenseType isEqualToString:PEX_LICENCE_TYPE_TRIAL_STRING];
}

- (NSString *) getLicenseTypeHumanString
{
    return (self.licenseExpired ?
            PEXStr(@"L_license_type_expired") :

                ([self.licenseType isEqualToString:PEX_LICENCE_TYPE_FULL_STRING] ?
                        PEXStr(@"L_license_type_full") :
                        PEXStr(@"L_license_type_trial")));
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToLicenceInfo:other];
}

- (BOOL)isEqualToLicenceInfo:(PEXLicenceInfo *)info
{
    if (self == info)
        return YES;
    if (info == nil)
        return NO;
    if (self.licenseType != info.licenseType && ![self.licenseType isEqualToString:info.licenseType])
        return NO;
    if (self.licenseIssuedOn != info.licenseIssuedOn && ![self.licenseIssuedOn isEqualToDate:info.licenseIssuedOn])
        return NO;
    if (self.licenseExpiresOn != info.licenseExpiresOn && ![self.licenseExpiresOn isEqualToDate:info.licenseExpiresOn])
        return NO;
    if (self.licenseExpired != info.licenseExpired)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.licenseType hash];
    hash = hash * 31u + [self.licenseIssuedOn hash];
    hash = hash * 31u + [self.licenseExpiresOn hash];
    hash = hash * 31u + self.licenseExpired;
    return hash;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXLicenceInfo *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.licenseType = self.licenseType;
        copy.licenseIssuedOn = self.licenseIssuedOn;
        copy.licenseExpiresOn = self.licenseExpiresOn;
        copy.licenseExpired = self.licenseExpired;
    }

    return copy;
}


@end