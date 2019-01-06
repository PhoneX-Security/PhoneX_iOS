//
//  PEXAppNotificationCenter.m
//  Phonex
//
//  Created by Matej Oravec on 28/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAppNotificationCenter.h"
#import "PEXUtils.h"
#import "PEXGuiToneHelper.h"
#import "PEXGuiTone.h"
#import "PEXResSounds.h"

@interface PEXAppNotificationCenter ()

@property (nonatomic) UILocalNotification * contactsNotification;

@property (nonatomic) UILocalNotification * licenceUpdateNotification;

@property (nonatomic) UILocalNotification * unreadMessageNotification;
@property (nonatomic) UILocalNotification * missedCallNotification;

@property (nonatomic) UILocalNotification * incommingCallNotification;
@property (nonatomic) UILocalNotification * outgoingCallNotification;

@property (nonatomic) UILocalNotification * ongoingCallNotification;

@property (nonatomic) UILocalNotification * attentionNotification;

@property (nonatomic) UILocalNotification * recoveryEmailNotification;

@property (nonatomic) NSRecursiveLock *lock;

@property (nonatomic) UILocalNotification * appStartedInBackgroundNotification;

@property (nonatomic) volatile BOOL incomingNotificationActive;
@property (nonatomic) NSMutableArray * preparedCallNotifications;

@end

@implementation PEXAppNotificationCenter

- (void) showAttentionNotification
{
    [self.lock lock];

    if (self.attentionNotification) {
        [self forceHideAttentionNotification];
    }

    self.attentionNotification = [self showBannerNotification:PEXStr(@"L_app_requires_attention")];
    [PEXGuiNotificationCenter playMessageNotificationSound];

    [self.lock unlock];
}

- (void) hideAttentionNotification
{
    [self.lock lock];
    if (self.attentionNotification) {
        [self forceHideAttentionNotification];
    }
    [self.lock unlock];
}

- (void) forceHideAttentionNotification
{
    [self hideBannerNotification:self.attentionNotification];
    self.attentionNotification = nil;
}

- (void) showAppStartedInBackgroundNotification
{
    [self.lock lock];
    if (!self.appStartedInBackgroundNotification) {
        self.appStartedInBackgroundNotification = [self showBannerNotification:PEXStr(@"L_app_started")];
        //[PEXGuiNotificationCenter playMessageNotificationSound];
    }
    [self.lock unlock];
}

- (void) hideAppStartedInBackgroundNotification
{
    [self.lock lock];
    if (self.appStartedInBackgroundNotification)
    {
        [self hideBannerNotification:self.appStartedInBackgroundNotification];
        self.appStartedInBackgroundNotification = nil;
    }
    [self.lock unlock];
}

- (void) showIncommingCallNotification{
    self.incomingNotificationActive = YES;
    [self showIncommingCallNotificationInternal];
}

- (void) showIncommingCallNotificationInternal
{
    if (![PEXAppNotificationCenter areNotificationsAllowed] || !self.incomingNotificationActive){
        return;
    }

    NSString * soundResource = nil;
    PEXGuiTone * tone = [PEXAppNotificationCenter getIncomingCallTone];
    if (tone != nil){
        soundResource = [tone getToneResource];
    }

    const BOOL repeatSound = [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION
                                                                    defaultValue: PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION_DEFAULT];

    const BOOL vibrationsAllowed = [PEXAppNotificationCenter areVibrationNotificationsAllowed];
    const BOOL extraVibrations = [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_APPLICATION_VIBRATE_ON_CALL
                                                                        defaultValue: PEX_PREF_APPLICATION_VIBRATE_ON_CALL_DEFAULT];

    // Prepare multiple notifications so they are repeated once ringing tone finishes.
    PEXGuiTone * vibTone = [PEXGuiToneHelper getNotificationToneById:PEX_NOTIFICATION_VIBRATION];
    const BOOL repeatSoundWithAlert = vibrationsAllowed && extraVibrations && vibTone != nil;

    @synchronized (self.preparedCallNotifications) {
        NSDate * startDate = [NSDate date];
        double duration = tone == nil ? 0.0 : [tone getToneDuration];

        // Pre-generate notifications so it fills one whole minute with ringing.
        double ringingDuration = duration+1.0;
        NSUInteger repetitions = (NSUInteger)floor(60.0 / ringingDuration);
        DDLogVerbose(@"Going to schedule next %lu sound notifications, gap: %0.2fs", (unsigned long) repetitions, 60.0-ringingDuration*repetitions);

        for(NSUInteger i=0; repeatSound && duration > 0.5 && i<repetitions; i++){
            UILocalNotification * const localNotification = [[UILocalNotification alloc] init];

            // When vibrations are active, notification has to have an alert name, otherwise vibration notification
            // would have cancel sound notification.
            if (repeatSoundWithAlert) {
                localNotification.alertBody = PEXStr(@"L_incomming_call_repeated");
            }

            if (soundResource) {
                localNotification.soundName = soundResource;
            }

            [localNotification setFireDate:[startDate dateByAddingTimeInterval:(i+1)*ringingDuration+1.5]];
            localNotification.timeZone = [NSTimeZone defaultTimeZone];
            localNotification.repeatCalendar = [NSCalendar currentCalendar];
            localNotification.repeatInterval = NSCalendarUnitMinute;
            localNotification.userInfo = @{@"type":@"ringing"};

            [self.preparedCallNotifications addObject:localNotification];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }

        // Pre-generate vibration notifications, repeat all the time.
        for(int i=0; vibrationsAllowed && extraVibrations && vibTone != nil && i<30; i++){
            UILocalNotification * const localNotification = [[UILocalNotification alloc] init];
            localNotification.soundName = [vibTone getToneResource];

            [localNotification setFireDate:[startDate dateByAddingTimeInterval:(i+1)*(2)]];
            localNotification.timeZone = [NSTimeZone defaultTimeZone];
            localNotification.repeatCalendar = [NSCalendar currentCalendar];
            localNotification.repeatInterval = NSCalendarUnitMinute;
            localNotification.hasAction = NO;
            localNotification.userInfo = @{@"type":@"vibration"};

            [self.preparedCallNotifications addObject:localNotification];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
    }

    [self showCallNotification:&_incommingCallNotification title:PEXStr(@"L_incomming_call") soundName:soundResource];
}

- (void) hideIncommingCallNotification
{
    // Cancel all prepared notifications.
    @synchronized (self.preparedCallNotifications) {
        for(UILocalNotification * notif in self.preparedCallNotifications){
            [self hideBannerNotification:notif];
        }
        [self.preparedCallNotifications removeAllObjects];
    }

    [self hideIncommingCallNotificationInternal];
}

- (void) hideIncommingCallNotificationInternal{
    [self hideCallNotification:&_incommingCallNotification];
}

- (void) showOngoingCallNotification
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    [self showCallNotification:&_ongoingCallNotification title:PEXStr(@"L_ongoing_call") soundName:nil];
}

- (void) hideOngoingCallNotification
{
    [self hideCallNotification:&_ongoingCallNotification];
}

- (void) showOutgoingCallNotification
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    [self showCallNotification:&_outgoingCallNotification title:PEXStr(@"L_outgoing_call") soundName:nil];
}

- (void) hideOutgoingCallNotification
{
    [self hideCallNotification:&_outgoingCallNotification];
}

- (void) showCallNotification: (UILocalNotification * __strong *) notification
                        title: (NSString * const) title
                    soundName: (NSString * const) soundName
{
    *notification = [self showBannerNotification:title withSoundName:soundName];
}

- (void) hideCallNotification: (UILocalNotification * __strong *) notification
{
    [self hideBannerNotification:*notification];
    *notification = nil;
}

- (void) allNotifications: (const int) count
{
    [self setBadgeCount:count];
}

- (void) allRepeatNotify{ /* do nothing */ }

- (void)licenceUpdateNotifications:(const int)count
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_NOTIFICATION_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_licenceUpdateNotification
                          for:count
                   withTitile:[NSString stringWithFormat:@"%@", PEXStr(@"L_licence_update")]
                    withSound:soundResource];
}

- (BOOL)showRecoveryEmailNotificationIfNotAlready
{
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    if ([prefs getBoolPrefForKey:PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SHOWN defaultValue:NO]){
        return NO;
    }

    if ([self showRecoveryEmailNotification]){
        [prefs setBoolPrefForKey:PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SHOWN value:YES];
        return YES;
    }

    return NO;
}

- (BOOL)showRecoveryEmailNotification
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return NO;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_NOTIFICATION_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_recoveryEmailNotification
                          for:1
                   withTitile:[NSString stringWithFormat:@"%@", PEXStr(@"L_recovery_email_notification")]
                    withSound:soundResource];

    return YES;
}

- (void) hideRecoveryEmailNotification
{
    [self hideCallNotification:&_recoveryEmailNotification];
}

- (void) callLogNotifications:(const int)count
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_MISSED_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_missedCallNotification
                          for:count
                   withTitile:[NSString stringWithFormat:@"%@ (%d)", PEXStr(@"L_missed_call"), count ]
                    withSound:soundResource];
}

- (void) messageNotifications:(const int)count
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_MESSAGE_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_unreadMessageNotification
                          for:count
                   withTitile:[NSString stringWithFormat:@"%@ (%d)", PEXStr(@"L_unread_message"), count ]
                    withSound:soundResource];
}

- (void) messageRepeatNotify:(const int)count
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_MESSAGE_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_unreadMessageNotification
                          for:count
                   withTitile:[NSString stringWithFormat:@"%@ (%d)", PEXStr(@"L_unread_message"), count ]
                    withSound:soundResource];
}

- (void)contactNotificationCountChanged:(const int)count
{
    if (![PEXAppNotificationCenter areNotificationsAllowed]){
        return;
    }

    NSString * soundResource = nil;
    if ([PEXAppNotificationCenter areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_NOTIFICATION_TONE defaultValue:nil];
        PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
        soundResource = [tone getToneResource];
    }

    [self executeNotification:&_contactsNotification
                          for:count
                   withTitile:[NSString stringWithFormat:@"%@ (%d)", PEXStr(@"L_contact_requests"), count ]
                    withSound:soundResource];
}

- (void) recoveryMailNotificationCountChanged: (const int) count
{
    [self showRecoveryEmailNotificationIfNotAlready];
}

- (void) executeNotification:(UILocalNotification * __strong * const) notification
                         for:(const int) count
                  withTitile:(NSString * const) title
                   withSound:(NSString * const) sound
{
    [self hideBannerNotification:*notification];
    *notification = ((count > 0) ? [self showBannerNotification:title withSoundName:sound] : nil);
}

- (UILocalNotification *) showBannerNotification: (NSString * const) title
{
    return [self showBannerNotification:title withSoundName:nil];
}

- (UILocalNotification *) showBannerNotification: (NSString * const) title withSoundName: (NSString * const) soundName
{
    UILocalNotification * const localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = title;

    if (soundName) {
        localNotification.soundName = soundName;
    }

    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];

    return localNotification;
}

- (void) hideBannerNotification: (UILocalNotification * const) notification
{
    if (notification)
        [[UIApplication sharedApplication] cancelLocalNotification:notification];
}

- (void) register
{
    [[PEXGNFC instance] registerToAllAndSet:self];
    [[PEXGNFC instance] registerToMessagesAndSet:self];
    [[PEXGNFC instance] registerToCallLogsAndSet:self];
    [[PEXGNFC instance] registerToLicenceUpdateAndSet:self];
    [[PEXGNFC instance] registerToContactNotificationsAndSet:self];
    [[PEXGNFC instance] registerToRecoveryMailNotificationsAndSet:self];
}

- (void) setBadgeCount: (const int) count
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

- (void) unregister
{
    [[PEXGNFC instance] unregisterForAll:self];
    [[PEXGNFC instance] unregisterForMessages:self];
    [[PEXGNFC instance] unregisterForCallLogs:self];
    [[PEXGNFC instance] unregisterForLicenceUpdate:self];
    [[PEXGNFC instance] unregisterForContactNotifications:self];
    [[PEXGNFC instance] unregisterForRecoveryMailNotifications:self];
    [self reset];
}

- (void) reset
{
    // TODO remove all banner notifications
    [self setBadgeCount:0];

    [self resetNotification:&_unreadMessageNotification];
    [self resetNotification:&_missedCallNotification];
    [self resetNotification:&_contactsNotification];

    [self resetNotification:&_incommingCallNotification];
    [self resetNotification:&_outgoingCallNotification];
    [self resetNotification:&_ongoingCallNotification];

    [self resetNotification:&_licenceUpdateNotification];
    [self resetNotification:&_recoveryEmailNotification];

    // Cancel all scheduled notifications.
    @synchronized (self.preparedCallNotifications) {
        for(UILocalNotification * notif in self.preparedCallNotifications){
            [self hideBannerNotification:notif];
        }
        [self.preparedCallNotifications removeAllObjects];
    }

    // Clean leftovers.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void) resetNotification: (UILocalNotification * __strong * const) notification
{
    [self hideBannerNotification:*notification];
    *notification = nil;
}

- (id) init
{
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc] init];
        self.incomingNotificationActive = NO;
        self.preparedCallNotifications = [[NSMutableArray alloc] init];
    }

    return self;

    /*
    UIApplication * const application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    */

    return self;
}

+ (PEXAppNotificationCenter *) instance
{
    static PEXAppNotificationCenter * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXAppNotificationCenter alloc] init];
    });

    return instance;
}

+ (BOOL) areNotificationsAllowed{
    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND
                                                                      defaultValue:@(0)];

    const uint64_t current = [PEXUtils currentTimeMillis];
    const uint64_t valueInt = (uint64_t)[value longLongValue];
    return value == nil || valueInt <= current;
}

+ (BOOL) areSoundNotificationsAllowed{
    if (![self areNotificationsAllowed]){
        return NO;
    }

    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_SOUND_MILLISECOND
                                                                      defaultValue:@(0)];

    const uint64_t current = [PEXUtils currentTimeMillis];
    const uint64_t valueInt = (uint64_t)[value longLongValue];
    return value == nil || valueInt <= current;
}

+ (BOOL) areVibrationNotificationsAllowed{
    if (![self areNotificationsAllowed]){
        return NO;
    }

    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_VIBRATIONS_MILLISECOND
                                                                      defaultValue:@(0)];

    const uint64_t current = [PEXUtils currentTimeMillis];
    const uint64_t valueInt = (uint64_t)[value longLongValue];
    return value == nil || valueInt <= current;
}

+ (PEXGuiTone *)getIncomingCallTone {
    PEXGuiTone * tone = nil;
    if ([self areSoundNotificationsAllowed]){
        NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_CALL_TONE defaultValue:nil];
        tone = [PEXGuiToneHelper getRingToneById:value];
    }

    return tone;
}

@end
