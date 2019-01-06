//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"
#import "PEXTaskFinishedEvent.h"

// Stages for progress monitoring.
typedef enum PEXCertGenStage : NSInteger PEXCertGenStage;
enum PEXCertGenStage : NSInteger {
    PEX_CERT_GEN_STARTED,
    PEX_CERT_GEN_KEYGEN,
    PEX_CERT_GEN_CSR,
    PEX_CERT_OTT,
    PEX_CERT_AUTH_TOKEN,
    PEX_CERT_ENC_CSR,
    PEX_CERT_SOAP_CALL,
    PEX_CERT_VERIFY,
    PEX_CERT_PASSGEN,
    PEX_CERT_SAVE_DONE,
    PEX_CERT_FINISHED
};

// Object used during progress.
@interface PEXCertGenTaskEventProgress : PEXTaskEvent { }
@property (nonatomic) PEXCertGenStage stage;
@property (nonatomic) NSProgress * progress;
- (id) initWithStage: (const PEXCertGenStage) stage;
- (id) initWithStage: (const PEXCertGenStage) stage progress: (NSProgress *) progress;
@end

// Object used to report final state.
@interface PEXLoginTaskEventFinished : PEXTaskFinishedEvent { }
@property (nonatomic) PEXCertGenTaskEventProgress * lastProgress;
@end


