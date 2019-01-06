//
// Created by Dusan Klinec on 18.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXSoapAdditions.h"
#import "hr.h"
#import "USAdditions.h"

@implementation PEXSoapAdditions {}

+(NSString *) authCheckToString: (hr_authCheckV3Response *) resp{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([resp class])];
    [description appendFormat:@"resp.authHashValid=%@", hr_trueFalse_stringFromEnum(resp.authHashValid)];
    [description appendFormat:@", resp.certValid=%@", hr_trueFalseNA_stringFromEnum(resp.certValid)];
    [description appendFormat:@", resp.certStatus=%@", hr_certificateStatus_stringFromEnum(resp.certStatus)];
    [description appendFormat:@", resp.forcePasswordChange=%@", hr_trueFalse_stringFromEnum(resp.forcePasswordChange)];
    [description appendFormat:@", resp.errCode=%@", resp.errCode];
    [description appendFormat:@", resp.storedFilesNum=%@", resp.storedFilesNum];
    [description appendFormat:@", resp.serverTime=%@", resp.serverTime];
    [description appendFormat:@", resp.licenseType=%@", resp.licenseType];
    [description appendFormat:@", resp.accountIssued=%@", resp.accountIssued];
    [description appendFormat:@", resp.accountExpires=%@", resp.accountExpires];
    [description appendFormat:@", resp.firstAuthCheckDate=%@", resp.firstAuthCheckDate];
    [description appendFormat:@", resp.lastAuthCheckDate=%@", resp.lastAuthCheckDate];
    [description appendFormat:@", resp.firstLoginDate=%@", resp.firstLoginDate];
    [description appendFormat:@", resp.firstUserAddDate=%@", resp.firstUserAddDate];
    [description appendFormat:@", resp.accountLastActivity=%@", resp.accountLastActivity];
    [description appendFormat:@", resp.accountLastPassChange=%@", resp.accountLastPassChange];
    [description appendFormat:@", resp.accountDisabled=%d", resp.accountDisabled == nil ? NO : resp.accountDisabled.boolValue];
    [description appendFormat:@", resp.auxVersion=%@", resp.auxVersion];
    [description appendFormat:@", resp.auxJSON=%@", resp.auxJSON];
    [description appendString:@">"];
    return description;
}


@end