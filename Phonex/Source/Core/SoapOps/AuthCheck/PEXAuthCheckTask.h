    //
// Created by Dusan Klinec on 20.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCertGenParams.h"
#import "PEXUserPrivate.h"
#import "PEXTaskContainer.h"
#import "PhoenixPortServiceSvc.h"

// Define ID of the Cert Gen tasks.
typedef enum PEXAuthCheckTaskID : NSInteger {
    PACT_KEYGEN=0,
    PACT_SOAP,
    PACT_FINISH,
    PACT_MAX
} PEXAuthCheckTaskID;

@interface PEXAuthCheckTask : PEXTaskContainer
@property (nonatomic) PEXCertGenParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@property (nonatomic) hr_authCheckV3Response * response;
@end