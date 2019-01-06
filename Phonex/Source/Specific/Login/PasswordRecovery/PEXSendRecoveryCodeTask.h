//
// Created by Dusan Klinec on 15.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRestRequester.h"

typedef void (^PEXRecoveryCodeSendFinished)(NSNumber * status, NSString * statusText, NSNumber * validTo);
typedef void (^PEXRecoveryCodeSendFailed)(void);

@interface PEXSendRecoveryCodeTask : PEXRestRequester
@property(nonatomic, readonly) NSError * loadError;

/**
 * Input parameters to the task.
 */
@property(nonatomic) NSString * dstUser;
@property(nonatomic) NSString * dstUserResource;

/**
 * Main action method, performs the request.
 * Async call.
 */
- (bool) sendRecoveryCode: (PEXRecoveryCodeSendFinished)completion
             errorHandler: (PEXRecoveryCodeSendFailed)errorHandler;
@end