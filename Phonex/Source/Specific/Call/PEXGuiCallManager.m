//
//  PEXGuiCallManager.m
//  Phonex
//
//  Created by Matej Oravec on 15/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCallManager.h"

#import "PEXGuiCallController.h"
#import "PEXGuiPreferencesController.h"

#import "PEXDbContact.h"
#import "PEXIncommingCall.h"
#import "PEXService.h"
#import "pexpj.h"
#import "PEXPjManager.h"
#import "PEXGuiKeyboardHolder.h"
#import "PEXOutgoingCall.h"

#import "PEXGuiLoginController.h"
#import "PEXGuiShieldManager.h"
#import "PEXGuiSpecialPriorityManager.h"
#import "PEXLicenceManager.h"
#import "PEXPackageItem.h"
#import "PEXPermissionsUtils.h"
#import "PEXDbAccountingPermission.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXGuiFactory.h"
#import "PEXGrandSelectionManager.h"

@interface PEXGuiCallManager ()

@property (nonatomic) NSRecursiveLock * lock;
@property (nonatomic) PEXGuiCallController * callController;

@property (nonatomic) NSDate *dateOfTheCall;
@property (nonatomic) PEXGuiNotEnoughListener * notEnoughListener;

@end

@implementation PEXGuiCallManager

- (bool) showCall: (PEXPjCall *) callInfo
{
    bool result = false;

    [self.lock lock];

    // checking callController instance because we remember only one instance
    // rather do not show the second controller than reach some evil state
    if ([PEXGuiLoginController instance].landingController)
    {
        // Try to dismiss existing controller if possible.
        if (self.callController){
            DDLogWarn(@"Call controller already exists %@, callEnded: %d", self.callController, [self.callController hasCallEnded]);
            if ([self.callController dismissEverythingIfCallEnded]){
                DDLogVerbose(@"Previous controlled dismissed");
                self.callController = nil;

            } else {
                DDLogVerbose(@"Previous call controller could not be dismissed");
            }
        }

        // Try again.
        if (!self.callController) {
            // destroy all other modal controllers that could overlap the call controller
            [[PEXGuiShieldManager instance] dimissVictims];

            result = [self showInternal:callInfo];
        }
    }
    [self.lock unlock];

    return result;
}

// must be called in lock
- (bool) showInternal: (PEXPjCall *) callInfo
{
    // TODO: async?
    const PEXDbContact * const contact = [self loadContactWithSip:callInfo.remoteSip];
    if (!contact)
        return false;

    PEXIncommingCall * const call = [[PEXIncommingCall alloc] initWithContact:contact pjCall:callInfo];
    self.callController = [[PEXGuiCallController alloc] initWithIncommingCall:call];
    self.callController.isUnlimited = true;

    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       UIViewController * landing = [PEXGuiLoginController instance].landingController;
                       [self.callController prepareOnScreen: landing];
                       [self.callController show: landing];
                   });

    return true;
}

- (bool) showCallOutgoing: (const PEXDbContact * const) contact
{
    bool result = false;

    [self.lock lock];

    NSArray * const permissions =
            [[[PEXService instance] licenceManager] getPermissions:nil
                                                          forPrefix:PEX_PERMISSION_CALLS_PREFIX
                                                       validForDate:nil];

    NSDate *dateOfTheCall = [[[PEXAppState instance] referenceTimeManager] currentTimeSinceReference: [NSDate date]];
    const int64_t maxDuration = [PEXGuiCallManager getMaxDuration:permissions];

    if (maxDuration == 0)
    {
        [self showWhyUserCannotCallPopup];
    }
    else
    {
        result = [self showCallOutgoing:contact withMaxDuration: maxDuration];

        if (result)
            self.dateOfTheCall = dateOfTheCall;
    }

    [self.lock unlock];

    return result;
}

+ (int64_t) getMaxDuration: (NSArray * const) permissions
{
    int64_t result = 0;

    if (permissions && permissions.count) {
        for (const PEXDbAccountingPermission * const permission in permissions) {

            if (![PEXPermissionsUtils isPermissionForCalls:permission.name])
                continue;

            const int64_t value = [permission.value longLongValue];

            if (value == 0)
                continue;

            NSDate * const validFrom = permission.validFrom;

            if (value == -1) {
                result = value;
                break;
            }
            else
            {
                const int64_t available = value - [permission.spent longLongValue];
                if (available >= 0)
                    result += available;
            }
        }
    }

    return result;
}

- (bool) showCallOutgoing: (const PEXDbContact * const) contact
          withMaxDuration: (const int64_t) maxDuration
{
    bool result = false;

    // checking callController instance because we remember only one instance
    // rather do not show the second controller than reach some evil state
    if ([PEXGuiLoginController instance].landingController && !self.callController)
    {
        result = [self showInternalOutgoing:contact withMaxDuration:maxDuration];
    }

    return result;
}

// must be called in lock
- (bool) showInternalOutgoing: (const PEXDbContact * const) contact
              withMaxDuration: (const int64_t) maxDuration
{
    bool result = false;

    PEXOutgoingCall * const call = [[PEXOutgoingCall alloc] initWithContact:contact];
    self.callController = [[PEXGuiCallController alloc] initWithOutgoingCall:call];

    if (maxDuration == -1)
        self.callController.isUnlimited = true;
    else
    {
        self.callController.isUnlimited = false;
        self.callController.maxCallDurationInSeconds = maxDuration;
    }

    UIViewController * const landing = [PEXGuiLoginController instance].landingController;

    if (landing)
    {

    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       UIViewController * landing = [PEXGuiLoginController instance].landingController;
                       [self.callController prepareOnScreen:landing];
                       [self.callController show:landing];
                   });

        result = true;
    }

    return result;
}

- (void) bringTheCallToFront
{
    [self.lock lock];

    if (self.callController)
    {
        [self.callController bringTofront];
    }

    [self.lock unlock];
}

- (void)callTimeWasConsumed:(const int64_t)consumedTimeInSeconds
{
    NSDate *timeOfTheCall;
    if (self.dateOfTheCall && ![self.dateOfTheCall isEqualToDate:[NSDate distantFuture]])
        timeOfTheCall = [self.dateOfTheCall copy];

    [[[PEXService instance] licenceManager] permissionsValuesWereConsumedAsync:consumedTimeInSeconds
                                                                   validForDate:timeOfTheCall
                                                                      forPrefix:PEX_PERMISSION_CALLS_PREFIX];
}

- (void) callTimeWasSynchronized: (const int64_t) remainingTime
{
    // TODO
    // do not react for now

    /*
    if (remainingTime == -1)
        [self.callController setIsUnlimitedPost: true];
    else
    {
        self.callController.maxCallDurationInSeconds = remainingTime;
        [self.callController setIsUnlimitedPost: false];
    }
    */
}


// not nice
- (void) unsetCallController
{
    [self.lock lock];

    self.callController = nil;

    [self.lock unlock];
}

- (void) unsetCallController: (PEXGuiCallController *) thisOne
{
    [self.lock lock];

    if (self.callController == thisOne) {
        self.callController = nil;
    }

    [self.lock unlock];
}

- (PEXDbContact *) loadContactWithSip: (NSString * const) sip
{
    PEXDbCursor * const cursor =
            [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
            projection:[PEXDbContact getLightProjection]
            selection:[PEXDbContact getWhereForSip]
            selectionArgs:[PEXDbContact getWhereForSipArgs:sip]
            sortOrder:nil];

    PEXDbContact * result = nil;
    if ([cursor moveToNext])
    {
        result = [PEXDbContact contactFromCursor:cursor];
    }

    return result;
}

-(void) showWhyUserCannotCallPopup{
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *landing = [PEXGuiLoginController instance].landingController;
        weakSelf.notEnoughListener = [[PEXGuiNotEnoughListener alloc] init];
        weakSelf.notEnoughListener.parent = landing;

        weakSelf.notEnoughListener.dialog = [PEXGuiFactory showBinaryDialog:landing
                                                 withText:PEXStrU(@"txt_not_enough_minutes_to_spend")
                                                 listener:weakSelf.notEnoughListener
                                            primaryAction:PEXStrU(@"L_buy")
                                          secondaryAction:nil];
    });
}

+ (PEXGuiCallManager *) instance
{
    static PEXGuiCallManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiCallManager alloc] init];
    });

    return instance;
}

@end
