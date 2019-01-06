//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

@class PEXSOAPResult;
@class hr_accountSettingsUpdateV1Response;


@interface PEXAccountSettingsTask : NSObject<PEXTaskListener>
@property (nonatomic) NSNumber * loggedOut;
@property (nonatomic) NSNumber * muteUntilMilli;
@property (nonatomic) NSNumber * muteSoundUntilMilli;
@property (nonatomic) NSString * recoveryEmail;

@property (nonatomic, weak) PEXUserPrivate * privData;
@property (nonatomic, copy) cancel_block cancelBlock;

@property (nonatomic) int retryCount;
@property (nonatomic) int curRetry;

/**
 * SOAP task completion handler.
 */
@property (nonatomic, copy) void(^completionHandler)(PEXAccountSettingsTask *);

/**
 * Result of the last SOAP operation.
 */
@property (nonatomic) PEXSOAPResult * lastResult;

/**
 * Last response from the request.
 */
@property (nonatomic) hr_accountSettingsUpdateV1Response *lastResponse;

/**
* Calls SOAP request for user account information. Synchronous network call.
*
* @param privData  private data object to use for SOAP HTTPS connection initialization & server authentication.
* @param cancelBlock cancel block object to interrupt synchronous request. Optional, may be nil.
* @param res SOAP result object, contains information about error.
* @return account info response. If error / cancellation occurs, response is nil.
*/
-(hr_accountSettingsUpdateV1Response *) request: (PEXUserPrivate *) privData
                                    cancelBlock: (cancel_block) cancelBlock
                                            res: (PEXSOAPResult **) res;

/**
 * Performs request with set retry count.
 * Calls completion handler when finishes.
 */
-(void) requestWithRetryCount;
@end