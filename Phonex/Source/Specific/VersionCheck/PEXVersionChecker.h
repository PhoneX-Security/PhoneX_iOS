//
// Created by Dusan Klinec on 23.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;
@class PEXVersionChecker;

typedef void (^OnNewVersionAvailableBlock)(BOOL afterUpdate, uint64_t versionCode,
        NSString * versionName, NSString * releaseNotes, PEXVersionChecker * checker);

FOUNDATION_EXPORT NSString  * PEXVCheckErrorDomain;
FOUNDATION_EXPORT const NSInteger   PEXVcheckGenericError;
FOUNDATION_EXPORT const NSInteger   PEXVcheckNotConnectedError;
FOUNDATION_EXPORT const NSInteger   PEXVcheckInvalidResponseError;
FOUNDATION_EXPORT const NSInteger   PEXVcheckCancelledError;
FOUNDATION_EXPORT const NSInteger   PEXVcheckTimedOutError;

@interface PEXVersionChecker : NSObject
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic) NSString * versionName;
@property(nonatomic, copy) OnNewVersionAvailableBlock onNewVersionBlock;

-(void) doRegister;
-(void) doUnregister;
-(void) quit;

-(void) checkVersion;

/**
* Use this call to store number of ignored version.
* After calling this no dialog will be invoked on this version.
*/
+(void) ignoreThisVersion: (uint64_t) vcode;

/**
* Do not show What's new again if update happens within 15 mins.
*/
+(void) setUpdateTime;

/**
 * Opens update URL, directing user to the AppStore record with the application.
 */
+(void) openUpdateWindow;

/**
 * Postpones update. First call to this call delays next update prompt by 3 hours. If this is clicked again,
 * next update prompt will show 24 hours later.
 */
+(void) updateLater: (uint64_t) vcode;

-(BOOL) showWhatsNewInCurrentVersion;
@end