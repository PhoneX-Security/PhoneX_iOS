//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXChangePasswordParams.h"
#import "PEXTaskContainer.h"
#import "PEXUserPrivate.h"

#define PEX_PASSWORD_MIN_LENGTH 8

FOUNDATION_EXPORT NSString * const PEXPassChangeErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXPassChangeErrorNotAuthorized;
FOUNDATION_EXPORT NSInteger const PEXPassChangeErrorServerCall;

// Define ID of the Cert Gen tasks.
typedef enum PEXChangePasswordTaskID : NSInteger {
    PEX_CHANGEPASS_OTT=0,
    PEX_CHANGEPASS_GENSOAP,
    PEX_CHANGEPASS_SOAP,
    PEX_CHANGEPASS_KEYGEN,
    PEX_CHANGEPASS_REKEY,
    PEX_CHANGEPASS_MAX
} PEXChangePasswordTaskID;

@interface PEXChangePasswordTask : PEXTaskContainer
@property (nonatomic) PEXChangePasswordParams * params;

/**
* Used to do SOAP with.
* Has to be initialized correctly prior calling this.
*/
@property (nonatomic) PEXUserPrivate * privData;

/**
* New derived passwords will be stored here, if requested.
*/
@property (nonatomic) PEXUserPrivate * nwPrivData;
@end