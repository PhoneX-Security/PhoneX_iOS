//
//  PEXChatCenter.m
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiNotificationCenter.h"

#import "PEXDbMessage.h"
#import "PEXDbCallLog.h"
#import "PEXMessageManager.h"
#import "PEXCallLogManager.h"

#import "PEXGuiPinLockManager.h"
#import "PEXGuiNotificationCounterView.h"
#import "PEXContactNotificationManager.h"
#import "PEXUtils.h"
#import "PEXGuiTone.h"
#import "PEXGuiToneHelper.h"

#import <AudioToolbox/AudioToolbox.h>

void playMessageNotificationSound()
{
    // http://iphonedevwiki.net/index.php/AudioServices
    // AudioServicesPlaySystemSound is not used anymore as it does not obey
    // Do Not Disturb mode. It plays and vibrates on DND mode enabled.
    //AudioServicesPlaySystemSound(1007);
}

@interface PEXGuiNotificationCenter ()
{
    @private
    bool _currentChatNotifiesFromBackground;
    bool _contactNotificationsVisible;

    int _messageNotificationsCount;
    int _callLogNotificationsCount;
    int _licenceUpdateNotificationsCount;
    int _contactNotificationsCount;
    int _recoveryMailNotificationsCount;
}

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * messageListeners;
@property (nonatomic) NSMutableArray * callLogListeners;
@property (nonatomic) NSMutableArray * licenceUpdateListeners;
@property (nonatomic) NSMutableArray * contactNotificationListeners;
@property (nonatomic) NSMutableArray * recoveryMailNotificationListeners;
@property (nonatomic) NSMutableArray * allListeners;

@end

@implementation PEXGuiNotificationCenter

+ (void) playMessageNotificationSound
{
    playMessageNotificationSound();
}

+ (bool) isActiveAndBeyondPinLock
{
    return ([[PEXAppState instance] isAppActive] && [[PEXGuiPinLockManager instance] beyondPinLock]);
}

- (void) setCurrentChatSip: (NSString *) currentChatSip
{
    [self.lock lock];
    _currentChatSip = currentChatSip;
    // more efficient with respect to relevant sip
    if ((_messageNotificationsCount > 0) && [PEXGNFC isActiveAndBeyondPinLock])
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [PEXMessageManager readAllForSip: currentChatSip];
        });
    [self.lock unlock];
}

/*
- (void) setCallLogIsVisible:(const bool) callLogIsVisible
{
    [self.lock lock];
    _callLogIsVisible = callLogIsVisible;
    if (callLogIsVisible && (_callLogNotificationsCount > 0))
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [PEXCallLogManager seeAll];
        });
    [self.lock unlock];
}
*/

- (void) unsetCurrentChatSip
{
    [self.lock lock];
    _currentChatSip = nil;
    [self.lock unlock];
}

- (void) reset
{
    _currentChatNotifiesFromBackground = false;
    _contactNotificationsVisible = false;
    _messageNotificationsCount = 0;
    _callLogNotificationsCount = 0;
    _licenceUpdateNotificationsCount = 0;
    _contactNotificationsCount = 0;
    _recoveryMailNotificationsCount = 0;
    _currentChatSip = nil;
    //_callLogIsVisible = false;
}

- (void) unload
{
    [self.lock lock];
    [self reset];
    [self.messageListeners removeAllObjects];
    [self.callLogListeners removeAllObjects];
    [self.licenceUpdateListeners removeAllObjects];
    [self.contactNotificationListeners removeAllObjects];
    [self.recoveryMailNotificationListeners removeAllObjects];
    [self.allListeners removeAllObjects];
    [self.lock unlock];
}

- (void) unregisterForMessages: (id<PEXGuiMessageNotificationsListener>) listener
{
    [self.lock lock];
    [self.messageListeners removeObject:listener];
    [self.lock unlock];
}

- (void) unregisterForCallLogs: (id<PEXGuiCallLogNotificationsListener>) listener
{
    [self.lock lock];
    [self.callLogListeners removeObject:listener];
    [self.lock unlock];
}

- (void) unregisterForLicenceUpdate: (id<PEXGuiLicenceUpdateNotificationsListener>) listener
{
    [self.lock lock];
    [self.licenceUpdateListeners removeObject:listener];
    [self.lock unlock];
}

- (void) unregisterForAll: (id<PEXGuiAllNotificationsListener>) listener
{
    [self.lock lock];
    [self.allListeners removeObject:listener];
    [self.lock unlock];
}

- (void)unregisterForContactNotifications:(PEXGuiNotificationCounterView *)listener
{
    [self.lock lock];
    [self.contactNotificationListeners removeObject:listener];
    [self.lock unlock];
}

- (void)unregisterForRecoveryMailNotifications:(id<PEXGuiRecoveryMailNotificationsListener>)listener
{
    [self.lock lock];
    [self.recoveryMailNotificationListeners removeObject:listener];
    [self.lock unlock];
}

- (int) messageNotificationCount
{
    return _messageNotificationsCount;
}

- (int) callLogNotificationCount
{
    return _callLogNotificationsCount;
}

- (bool) increaseMessageNorificationAsync: (NSString * const) chatSip
                               forMessage: (const PEXDbMessage * const) message
{
    bool result = false;

    const bool activeAndBeyondPinLock = [PEXGNFC isActiveAndBeyondPinLock];
    [self.lock lock];

    if ([chatSip isEqualToString:self.currentChatSip] && !activeAndBeyondPinLock)
    {
        _currentChatNotifiesFromBackground = true;
    }

    if (![chatSip isEqualToString:self.currentChatSip] || !activeAndBeyondPinLock)
    {
        playMessageNotificationSound();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            ++_messageNotificationsCount;
            [self notifyMessageListeners];
            [self.lock unlock];
        });

        result = true;
    }

    [self.lock unlock];
    return result;
}

- (void) repeatMessageNorificationAsync: (NSString * const) chatSip
{
    const bool activeAndBeyondPinLock = [PEXGNFC isActiveAndBeyondPinLock];
    [self.lock lock];

    if ([chatSip isEqualToString:self.currentChatSip] && !activeAndBeyondPinLock)
    {
        _currentChatNotifiesFromBackground = true;
    }

    if (![chatSip isEqualToString:self.currentChatSip] || !activeAndBeyondPinLock)
    {
        playMessageNotificationSound();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            [self notifyMessageListenersRepeat];
            [self.lock unlock];
        });
    }
    [self.lock unlock];
}



- (void) goingToForeground
{
    [self.lock lock];

    if (_currentChatNotifiesFromBackground)
        [PEXMessageManager readAllForSip: _currentChatSip];

    [self seeAllContactNotificationsIfPossible];

    [self.lock unlock];
}

- (void) contactNotificationsWereShown
{
    [self.lock lock];
    _contactNotificationsVisible = true;
    // more efficient with respect to relevant sip
    if ((_contactNotificationsCount > 0) && [PEXGNFC isActiveAndBeyondPinLock])
        [self seeAllContactNotificationsIfPossible];
    [self.lock unlock];
}

- (void) contactNotificationsWereHidden
{
    [self.lock lock];
    _contactNotificationsVisible = false;
    [self.lock unlock];
}

- (void) seeAllContactNotificationsIfPossible
{
    if (_contactNotificationsVisible)
        [PEXContactNotificationManager seeAllNotificationsAsync];
}

- (bool) notifyContactNorificationAsyncBy: (const int) count
{
    bool result = false;
    [self.lock lock];


    if (!_contactNotificationsVisible || ![PEXGNFC isActiveAndBeyondPinLock])
    {
        playMessageNotificationSound();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            _contactNotificationsCount = count;
            [self notifyContactNotificationListeners];
            [self.lock unlock];
        });

        result = true;
    }

    [self.lock unlock];
    return result;
}

- (bool) setContactNorificationAsyncFor: (const int) count
{
    bool result = false;
    [self.lock lock];


    if (!_contactNotificationsVisible)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            _contactNotificationsCount = count;
            [self notifyContactNotificationListeners];
            [self.lock unlock];
        });

        result = true;
    }

    [self.lock unlock];
    return result;
}

- (void) unsetContactNorificationAsync
{
    [self.lock lock];

    if (_contactNotificationsCount > 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];

            if (_contactNotificationsCount > 0)
            {
                _contactNotificationsCount = 0;
                [self notifyContactNotificationListeners];
            }
            [self.lock unlock];
        });
    }

    [self.lock unlock];
}


- (void) decreaseMessageNorificationAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
            --_messageNotificationsCount;
            [self notifyMessageListeners];
        [self.lock unlock];
    });
}

- (bool) increaseCallLogNorificationAsync
{
    bool result = false;
    [self.lock lock];

    playMessageNotificationSound();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        ++_callLogNotificationsCount;
        [self notifyCallLogListeners];
        [self.lock unlock];
    });

    result = true;

    [self.lock unlock];
    return result;
}

- (void) setLicenceUpdateNorificationAsync
{
    [self.lock lock];

    playMessageNotificationSound();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        _licenceUpdateNotificationsCount = 1;
        [self notifyLicenceUpdateListeners];
        [self.lock unlock];
    });

    [self.lock unlock];
}

- (void) unsetLicenceUpdateNorificationAsync
{
    // TODO permission notifications
    /*
    [self.lock lock];

    if (_licenceUpdateNotificationsCount > 0)
    {
        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                                                      value:true];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            _licenceUpdateNotificationsCount = 0;
            [self notifyLicenceUpdateListeners];
            [self.lock unlock];
        });
    }

    [self.lock unlock];
     */
}

- (void)setRecoveryMailNotificationAsync {
    [self.lock lock];

    BOOL seen = [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SEEN defaultValue:NO];
    if (!seen) {
        playMessageNotificationSound();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            _recoveryMailNotificationsCount = 1;
            [self notifyRecoveryMailNotificationListeners];
            [self.lock unlock];
        });
    }

    [self.lock unlock];
}

- (void)unsetRecoveryMailNotificationAsync {
    [self.lock lock];

    if (_recoveryMailNotificationsCount > 0)
    {
        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SEEN value:true];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            _recoveryMailNotificationsCount = 0;
            [self notifyRecoveryMailNotificationListeners];
            [self.lock unlock];
        });
    }

    [self.lock unlock];
}

- (void) seeAllCallLogNotifications
{
    [self.lock lock];

    if (_callLogNotificationsCount > 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [PEXCallLogManager seeAll];
        });
    }

    [self.lock unlock];
}

- (void) decreaseCallLogNorificationAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
            --_callLogNotificationsCount;
            [self notifyCallLogListeners];
        [self.lock unlock];
    });
}

- (void) notifyMessageListeners
{
    for (id<PEXGuiMessageNotificationsListener> listener in self.messageListeners)
    {
        [listener messageNotifications:_messageNotificationsCount];
    }

    [self notifyAllListeners];
}

- (void) notifyCallLogListeners
{
    for (id<PEXGuiCallLogNotificationsListener> listener in self.callLogListeners)
    {
        [listener callLogNotifications:_callLogNotificationsCount];
    }

    [self notifyAllListeners];
}

- (void) notifyMessageListenersRepeat
{
    for (id<PEXGuiMessageNotificationsListener> listener in self.messageListeners)
    {
        [listener messageRepeatNotify:_messageNotificationsCount];
    }

    [self notifyAllListenersRepeat];
}

- (void) notifyLicenceUpdateListeners
{
    for (id<PEXGuiLicenceUpdateNotificationsListener> listener in self.licenceUpdateListeners)
    {
        [listener licenceUpdateNotifications:_licenceUpdateNotificationsCount];
    }

    [self notifyAllListeners];
}

- (void) notifyContactNotificationListeners
{
    for (id<PEXGuiContactNotificationsListener> listener in self.contactNotificationListeners)
    {
        [listener contactNotificationCountChanged:_contactNotificationsCount];
    }

    [self notifyAllListeners];
}

- (void) notifyRecoveryMailNotificationListeners
{
    for (id<PEXGuiRecoveryMailNotificationsListener> listener in self.recoveryMailNotificationListeners)
    {
        [listener recoveryMailNotificationCountChanged:_recoveryMailNotificationsCount];
    }

    [self notifyAllListeners];
}

- (void) notifyAllListeners
{
    const int count = [self allCount];
    for (id<PEXGuiAllNotificationsListener> listener in self.allListeners)
    {
        [listener allNotifications:count];
    }
}

- (void) notifyAllListenersRepeat
{
    for (id<PEXGuiAllNotificationsListener> listener in self.allListeners)
    {
        [listener allRepeatNotify];
    }
}

- (void) registerToMessagesAndSet: (id<PEXGuiMessageNotificationsListener>) listener
{
    [self.lock lock];
    [self.messageListeners addObject:listener];
    [listener messageNotifications:_messageNotificationsCount];
    [self.lock unlock];
}

- (void) registerToCallLogsAndSet: (id<PEXGuiCallLogNotificationsListener>) listener
{
    [self.lock lock];
    [self.callLogListeners addObject:listener];
    [listener callLogNotifications:_callLogNotificationsCount];
    [self.lock unlock];
}

- (void) registerToLicenceUpdateAndSet: (id<PEXGuiLicenceUpdateNotificationsListener>) listener
{
    [self.lock lock];
    [self.licenceUpdateListeners addObject:listener];
    [listener licenceUpdateNotifications:_licenceUpdateNotificationsCount];
    [self.lock unlock];
}

- (void) registerToAllAndSet: (id<PEXGuiAllNotificationsListener>) listener
{
    [self.lock lock];
    [self.allListeners addObject:listener];
    [listener allNotifications:[self allCount]];
    [self.lock unlock];
}

- (void)registerToContactNotificationsAndSet:(id<PEXGuiContactNotificationsListener>)listener
{
    [self.lock lock];
    [self.contactNotificationListeners addObject:listener];
    [listener contactNotificationCountChanged:_contactNotificationsCount];
    [self.lock unlock];
}

- (void)registerToRecoveryMailNotificationsAndSet:(id<PEXGuiRecoveryMailNotificationsListener>)listener
{
    [self.lock lock];
    [self.recoveryMailNotificationListeners addObject:listener];
    [listener recoveryMailNotificationCountChanged:_recoveryMailNotificationsCount];
    [self.lock unlock];
}

- (int) allCount
{
    return _callLogNotificationsCount + _messageNotificationsCount +
            _licenceUpdateNotificationsCount + _contactNotificationsCount +
            _recoveryMailNotificationsCount;
}

////////////////

+ (PEXGuiNotificationCenter *) instance
{
    static PEXGuiNotificationCenter * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiNotificationCenter alloc] init];
    });

    return instance;
}

+ (bool) messageNotifies: (const PEXDbMessage * const) message
{
    return (message &&
            (message.isOutgoing.integerValue == 0) &&
            (message.read.integerValue == 0));
}

+ (bool) callLogNotifies: (const PEXDbCallLog * const) callLog
{
    const int typeValue = (int)[callLog.type integerValue];
    return (((typeValue == PEX_DBCLOG_TYPE_MISSED) || (typeValue == PEX_DBCLOG_TYPE_VOICEMAIL))
            && !callLog.seenByUser);
}

- (id) init
{
    self = [super init];

    [self reset];
    self.lock = [[NSLock alloc] init];
    self.messageListeners = [[NSMutableArray alloc] init];
    self.callLogListeners = [[NSMutableArray alloc] init];
    self.licenceUpdateListeners = [[NSMutableArray alloc] init];
    self.allListeners = [[NSMutableArray alloc] init];
    self.contactNotificationListeners = [[NSMutableArray alloc] init];
    self.recoveryMailNotificationListeners = [[NSMutableArray alloc] init];

    return self;
}

@end
