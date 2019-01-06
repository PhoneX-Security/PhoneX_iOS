//
// Created by Matej Oravec on 03/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTouchId.h"

#import <LocalAuthentication/LocalAuthentication.h>

@interface PEXTouchId()

@property (nonatomic) NSLock * showLock;

@property (nonatomic) LAContext * myContext;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation PEXTouchId {

}

+ (void) checkTouchIdDeviceStatusAndAdjustSetting
{
    if (![self isTouchIdOnDeviceAvailable:nil]/* && [self isSetByUserInApp]*/)
        [self setByUserInApp:false];
    else
        [self setByUserInApp:[self isSetByUserInApp]];
}

- (id) init
{
    self = [super init];

    self.showLock = [[NSLock alloc] init];
    self.queue = dispatch_queue_create("touch_requests_queue", nil);

    return self;
}

+ (PEXTouchId *) instance
{
    static PEXTouchId * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXTouchId alloc] init];
    });

    return instance;
}

- (void)hideTouchIdRequest
{
    self.myContext = nil;
}

- (void)requestTouchIdWithMessageAsync:(NSString *const)message
                             onSuccess:(void (^)(void))onSuccess
                             onFailure: (void (^)(const NSError * const error)) onFailure
{
    dispatch_async(self.queue, ^{

        [self.showLock lock];

        self.myContext = [[LAContext alloc] init];
        self.myContext.localizedFallbackTitle = PEXStr(@"B_continue");

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                           localizedReason:message
                                     reply:^(BOOL success, NSError *error) {
                                         if (success) {
                                             if (onSuccess)
                                                 onSuccess();
                                         } else {
                                             if (onFailure)
                                                 onFailure(error);
                                         }

                                         dispatch_sync(self.queue, ^{
                                             self.myContext = nil;
                                             [self.showLock unlock];
                                         });
                                     }];
        });
    });
}

// STATIC

+ (void) setByUserInApp: (const bool) set
{
    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_USE_TOUCH_ID_KEY value:set];
}

+ (bool) isSetByUserInApp
{
    return [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_TOUCH_ID_KEY
                                                  defaultValue:PEX_PREF_USE_TOUCH_ID_DEFAULT];
}

+ (PEXTouchIdStatus) getTouchIdStatus
{
    PEXTouchIdStatus deviceStatus;
    if (![self isTouchIdOnDeviceAvailable:&deviceStatus])
        return deviceStatus;

    const bool setInApp = [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_TOUCH_ID_KEY
                                                                 defaultValue:PEX_PREF_USE_TOUCH_ID_DEFAULT];

    return setInApp ? TOUCH_ID_STATUS_SET_AND_USED : TOUCH_ID_STATUS_NOT_USED;
}

+ (bool)isTouchIdOnDeviceAvailable: (PEXTouchIdStatus * const) outTouchIdStatus
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
    {
        if (outTouchIdStatus)
            *outTouchIdStatus = TOUCH_ID_STATUS_IOS8_PLUS_NEEDED;

        return false;
    }

    LAContext * const context = [[LAContext alloc] init];
    NSError * authError = nil;
    const bool available = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError];

    if (!available || authError)
    {
        if (outTouchIdStatus)
            *outTouchIdStatus = TOUCH_ID_STATUS_NOT_AVAILABLE;

        return false;
    }

    return true;
}

@end