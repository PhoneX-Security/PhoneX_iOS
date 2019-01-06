//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"
#import "PEXCertGenParams.h"
#import "PEXTaskContainer.h"
#import "PEXCertGenTaskState.h"
#import "PEXUserPrivate.h"

// Define ID of the Cert Gen tasks.
typedef enum PEXCertGenTaskID : NSInteger {
    PCGT_KEYGEN=0,
    PCGT_CSRGEN,
    PCGT_OTT,
    PCGT_AuthHash,
    PCGT_EncCSR,
    PCGT_SOAPSIGN,
    PCGT_VERIFY,
    PCGT_PEMPASSGEN,
    PCGT_STORE,
    PCGT_MAX
} PEXCertGenTaskID;

@interface PEXCertGenTask : PEXTaskContainer
@property (atomic) PEXCertGenTaskState * state;
@property (nonatomic) PEXCertGenParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@end