//
//  PEXChatCenter.h
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbCallLog;
@class PEXDbMessage;
@class PEXGuiTone;

#define PEXGNFC PEXGuiNotificationCenter

@protocol PEXGuiMessageNotificationsListener <NSObject>

- (void) messageNotifications: (const int) count;
- (void) messageRepeatNotify:(const int)count;

@end

@protocol PEXGuiLicenceUpdateNotificationsListener <NSObject>

- (void) licenceUpdateNotifications: (const int) count;

@end

@protocol PEXGuiCallLogNotificationsListener <NSObject>

- (void) callLogNotifications: (const int) count;

@end

@protocol PEXGuiContactNotificationsListener <NSObject>

- (void) contactNotificationCountChanged: (const int) count;

@end

@protocol PEXGuiRecoveryMailNotificationsListener <NSObject>

- (void) recoveryMailNotificationCountChanged: (const int) count;

@end

@protocol PEXGuiAllNotificationsListener <NSObject>

- (void) allNotifications: (const int) count;
- (void) allRepeatNotify;

@end

@interface PEXGuiNotificationCenter : NSObject

@property (nonatomic) NSString * currentChatSip;
//@property (nonatomic, assign) bool callLogIsVisible;

+ (void) playMessageNotificationSound;

- (void) unsetCurrentChatSip;
//- (void) setCallLogIsVisible:(const bool) callLogIsVisible;

- (void) registerToMessagesAndSet: (id<PEXGuiMessageNotificationsListener>) listener;
- (void) registerToCallLogsAndSet: (id<PEXGuiCallLogNotificationsListener>) listener;
- (void) registerToLicenceUpdateAndSet: (id<PEXGuiLicenceUpdateNotificationsListener>) listener;
- (void) registerToAllAndSet: (id<PEXGuiAllNotificationsListener>) listener;

- (void) unregisterForMessages: (id<PEXGuiMessageNotificationsListener>) listener;
- (void) unregisterForCallLogs: (id<PEXGuiCallLogNotificationsListener>) listener;
- (void) unregisterForLicenceUpdate: (id<PEXGuiLicenceUpdateNotificationsListener>) listener;
- (void) unregisterForAll: (id<PEXGuiAllNotificationsListener>) listener;

+ (PEXGuiNotificationCenter *) instance;
+ (bool) messageNotifies: (const PEXDbMessage * const) message;
+ (bool) callLogNotifies: (const PEXDbCallLog * const) callLog;

- (void) goingToForeground;

- (void) contactNotificationsWereShown;
- (void) contactNotificationsWereHidden;

- (void) unload;
- (bool) increaseMessageNorificationAsync: (NSString * const) chatSip
                               forMessage: (const PEXDbMessage * const) message;
- (bool) increaseCallLogNorificationAsync;

- (void) decreaseMessageNorificationAsync;
- (void) decreaseCallLogNorificationAsync;

- (bool) notifyContactNorificationAsyncBy: (const int) count;
- (bool) setContactNorificationAsyncFor: (const int) count;
- (void) unsetContactNorificationAsync;

- (void) setLicenceUpdateNorificationAsync;
- (void) unsetLicenceUpdateNorificationAsync;

- (void) setRecoveryMailNotificationAsync;
- (void) unsetRecoveryMailNotificationAsync;

- (void) notifyAllListeners;

- (void) seeAllCallLogNotifications;

- (void) repeatMessageNorificationAsync: (NSString * const) chatSip;

- (void)registerToContactNotificationsAndSet:(id<PEXGuiContactNotificationsListener>)view;
- (void)unregisterForContactNotifications:(id<PEXGuiContactNotificationsListener>)view;

- (void)registerToRecoveryMailNotificationsAndSet:(id<PEXGuiRecoveryMailNotificationsListener>)listener;
- (void)unregisterForRecoveryMailNotifications:(id<PEXGuiRecoveryMailNotificationsListener>)listener;
@end
