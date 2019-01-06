//
// Created by Dusan Klinec on 15.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRestRequester.h"

typedef void (^PEXRecoveryCodeApplyFinished)(NSNumber * status, NSString * statusText, NSString * newPasswd);
typedef void (^PEXRecoveryCodeApplyFailed)(void);


@interface PEXApplyRecoveryCodeTask : PEXRestRequester
@property(nonatomic, readonly) NSError * loadError;

/**
 * Input parameters to the task.
 */
@property(nonatomic) NSString * dstUser;
@property(nonatomic) NSString * dstUserResource;
@property(nonatomic) NSString * recoveryCode;

/**
 * Main action method, performs the request.
 * Async call.
 */
- (bool) applyRecoveryCode: (PEXRecoveryCodeApplyFinished)completion
              errorHandler: (PEXRecoveryCodeApplyFailed)errorHandler;
@end