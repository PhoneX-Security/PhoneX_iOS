//
//  PEXAppNotificationCenter.h
//  Phonex
//
//  Created by Matej Oravec on 28/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PEXANFC PEXAppNotificationCenter

@interface PEXAppNotificationCenter : NSObject<
        PEXGuiAllNotificationsListener,
        PEXGuiCallLogNotificationsListener,
        PEXGuiMessageNotificationsListener,
        PEXGuiLicenceUpdateNotificationsListener,
        PEXGuiContactNotificationsListener,
        PEXGuiRecoveryMailNotificationsListener>

+ (PEXAppNotificationCenter *) instance;

- (void) showAttentionNotification;
- (void) hideAttentionNotification;

- (void) showAppStartedInBackgroundNotification;
- (void) hideAppStartedInBackgroundNotification;

- (void) showOngoingCallNotification;
- (void) hideOngoingCallNotification;
- (void) showIncommingCallNotification;
- (void) hideIncommingCallNotification;
- (void) showOutgoingCallNotification;
- (void) hideOutgoingCallNotification;
- (BOOL) showRecoveryEmailNotificationIfNotAlready;
- (BOOL) showRecoveryEmailNotification;
- (void) hideRecoveryEmailNotification;

- (void) reset;
- (void) register;
- (void) unregister;

+ (BOOL) areNotificationsAllowed;
+ (BOOL) areSoundNotificationsAllowed;
+ (BOOL) areVibrationNotificationsAllowed;
+ (PEXGuiTone *) getIncomingCallTone;

@end
