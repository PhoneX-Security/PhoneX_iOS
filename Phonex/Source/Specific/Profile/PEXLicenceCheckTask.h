//
// Created by Matej Oravec on 08/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

@class hr_accountInfoV1Response;
@class PEXSOAPResult;
@class PEXReferenceTime;


@interface PEXLicenceCheckTask : NSObject<PEXTaskListener>
/**
* Specifies whether this task should automatically process application settings set by the server.
* By default set to YES.
*/
@property (nonatomic) BOOL automaticAppSettingsProcessing;

/**
* Specifies whether this task should automatically process account settings set by the server.
* By default set to YES.
*/
@property (nonatomic) BOOL automaticAccountSettingsProcessing;

/**
* Specifies whether this task should automatically process application policy set by the server.
* By default set to YES.
*/
@property (nonatomic) BOOL automaticPolicyProcessing;

/**
 * Should the successful call update reference server time?
 * @default YES
 */
@property (nonatomic) BOOL shouldUpdateReferenceTime;

/**
 * If set to YES, processing app settings is synchronous in this task, otherwise executed on main executor.
 */
@property (nonatomic) BOOL settingsProcessingSync;

/**
 * If set to YES, processing app settings is synchronous in this task, otherwise executed on main executor.
 */
@property (nonatomic) BOOL accountSettingsProcessingSync;

/**
 * If set to YES, processing app policy is synchronous in this task, otherwise executed on licence manager executor.
 */
@property (nonatomic) BOOL policyProcessingSync;

/**
 * SOAP task completion handler.
 */
@property (nonatomic, copy) void(^completionHandler)(PEXLicenceCheckTask *);

/**
 * Completion handler for settings update.
 */
@property (nonatomic, copy) void(^completionSettingsHandler)(PEXLicenceCheckTask *);

/**
 * Completion handler for settings update.
 */
@property (nonatomic, copy) void(^completionAccountSettingsHandler)(PEXLicenceCheckTask *);

/**
 * Completion handler for policy update.
 */
@property (nonatomic, copy) void(^completionPolicyHandler)(PEXLicenceCheckTask *);


/**
 * Result of the last SOAP operation.
 */
@property (nonatomic) PEXSOAPResult * lastResult;
@property (nonatomic) PEXReferenceTime * lastRefTime;


@property (nonatomic) BOOL policyUpdateOK;
@property (nonatomic) BOOL settingsUpdateOK;
@property (nonatomic) BOOL accountSettingsUpdateOK;

/**
* Calls SOAP request for user account information. Synchronous network call.
*
* @param privData  private data object to use for SOAP HTTPS connection initialization & server authentication.
* @param cancelBlock cancel block object to interrupt synchronous request. Optional, may be nil.
* @param res SOAP result object, contains information about error.
* @return account info response. If error / cancellation occurs, response is nil.
*/
-(hr_accountInfoV1Response *) requestUserInfo: (PEXUserPrivate *) privData cancelBlock: (cancel_block) cancelBlock res: (PEXSOAPResult **) res;

@end