//
// Created by Matej Oravec on 03/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    TOUCH_ID_STATUS_IOS8_PLUS_NEEDED,
    TOUCH_ID_STATUS_NOT_AVAILABLE,
    TOUCH_ID_STATUS_NOT_USED,
    TOUCH_ID_STATUS_SET_AND_USED
} PEXTouchIdStatus;

@class LAError;

@interface PEXTouchId : NSObject

- (void)requestTouchIdWithMessageAsync:(NSString *const)message
                             onSuccess:(void (^)(void))onSuccess
                             onFailure: (void (^)(const NSError * const error)) onFailure;
- (void)hideTouchIdRequest;

+ (PEXTouchId *) instance;

+ (PEXTouchIdStatus) getTouchIdStatus;
+ (void) checkTouchIdDeviceStatusAndAdjustSetting;
+ (void) setByUserInApp: (const bool) set;



@end