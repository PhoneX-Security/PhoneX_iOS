//
// Created by Dusan Klinec on 13.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPreferenceChangedListener.h"
#import "PEXGuiPreferencesNotificationsController.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiPoint.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiTicker.h"
#import "PEXGuiTimeUtils.h"
#import "PEXUtils.h"
#import "PEXGuiDialogBinaryListener.h"
#import "PEXMuteNotificationExecutor.h"
#import "PEXGuiTonesExecutor.h"
#import "PEXGuiTone.h"
#import "PEXResSounds.h"
#import "PEXGuiToneHelper.h"

@interface PEXGuiPreferencesNotificationsController () <PEXGuiDialogBinaryListener>

@property (nonatomic) NSLock * lock;

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiDetailView * disableAllNotificationsView;
@property (nonatomic) PEXGuiDetailView * disableSoundNotificationsView;
@property (nonatomic) PEXGuiDetailView * soundRingtoneView;
@property (nonatomic) PEXGuiDetailView * messageNotificationToneView;
@property (nonatomic) PEXGuiDetailView * missedCallToneView;
@property (nonatomic) PEXGuiDetailView * notificationToneView;
@property (nonatomic) PEXGuiDetailView * disableVibrationsView;
@property (nonatomic) PEXGuiPoint * lineFirst;

@property (nonatomic) PEXGuiTicker * repeatSoundNotification;
@property (nonatomic) PEXGuiTicker * vibrateForCalls;
@property (nonatomic) PEXGuiPoint * lineSecond;

@end

@implementation PEXGuiPreferencesNotificationsController {

}

- (id) init
{
    self = [super init ];

    self.lock = [[NSLock alloc] init];

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"NotificationsPreferences";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{

        self.disableAllNotificationsView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.disableAllNotificationsView];

        self.disableSoundNotificationsView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.disableSoundNotificationsView];

        self.lineFirst = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineFirst];

        self.soundRingtoneView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.soundRingtoneView];

        self.messageNotificationToneView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.messageNotificationToneView];

        self.missedCallToneView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.missedCallToneView];

        self.notificationToneView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.notificationToneView];

        self.lineSecond = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineSecond];

        self.disableVibrationsView = [[PEXGuiDetailView alloc] init];
//        [self.linearView addView:self.disableVibrationsView];

        self.repeatSoundNotification = [[PEXGuiTicker alloc] initWithDisplayTitle:YES];
        [self.linearView addView:self.repeatSoundNotification];

        self.vibrateForCalls = [[PEXGuiTicker alloc] initWithDisplayTitle:YES];
        [self.linearView addView:self.vibrateForCalls];
    }];
}


- (void) initContent
{
    [super initContent];

    [self.disableAllNotificationsView setName:PEXStrU(@"L_disable_notifications")];
    [self.disableSoundNotificationsView setName:PEXStrU(@"L_disable_sound_notifications")];
    [self.disableVibrationsView setName:PEXStrU(@"L_disable_vibrations")];

    [self.soundRingtoneView setName:PEXStrU(@"L_call_ringtone")];
    [self.messageNotificationToneView setName:PEXStrU(@"L_message_tone")];
    [self.missedCallToneView setName:PEXStrU(@"L_missed_call_tone")];
    [self.notificationToneView setName:PEXStrU(@"L_notification_tone")];

    [self.repeatSoundNotification setLabel:PEXStrU(@"L_repeat_sound_notification")];
    [self.repeatSoundNotification setTitle:PEXStrU(@"L_repeat_sound_notification_title")];
    [self.vibrateForCalls setLabel:PEXStrU(@"L_vibrate_calls_notification")];
    [self.vibrateForCalls setTitle:PEXStrU(@"L_vibrate_calls_notification_title")];

    [self.lock lock];

    [[PEXAppPreferences instance] addListener:self];
    [self reload];

    [self.lock unlock];
}

- (void)preferenceChangedForKey:(NSString *const)key
{
    [self.lock lock];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self reload];
    });
    [self.lock unlock];
}

- (void) reload
{
    [self loadMuteNotificationsPeriodView];
    [self loadMuteSoundPeriodView];
    [self loadMuteVibrationsPeriodView];

    [self loadCallTone];
    [self loadMissedTone];
    [self loadMessageTone];
    [self loadNotificationTone];

    [self loadRepeatSoundNotification];
    [self loadVibrateForCall];
}

-(void) loadMuteNotificationsPeriodView
{
    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND
                                                                      defaultValue:@(0)];

    NSString * label = nil;
    uint64_t current = [PEXUtils currentTimeMillis];
    uint64_t valueInt = (uint64_t)[value longLongValue];
    BOOL notifsMuted = YES;

    if (value == nil || valueInt <= current) {
        label = PEXStr(@"L_mute_disabled");
        notifsMuted = NO;
    } else if (valueInt >= current+2ll*PEX_YEAR_IN_SECONDS*1000ll) {
        label = PEXStr(@"L_until_enabled");
    } else {
        NSDate *date = [PEXUtils dateFromMillis:(uint64_t) [value longLongValue]];
        label = [PEXDateUtils dateToFullDateString:date];
    }

    [self.disableAllNotificationsView setValue:label];
    [self.disableSoundNotificationsView setEnabledLook:!notifsMuted];
    [self.disableVibrationsView setEnabledLook:!notifsMuted];
}

-(void) loadMuteSoundPeriodView
{
    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_SOUND_MILLISECOND
                                                                      defaultValue:@(0)];

    NSString * label = nil;
    uint64_t current = [PEXUtils currentTimeMillis];
    uint64_t valueInt = (uint64_t)[value longLongValue];

    if (value == nil || valueInt <= current) {
        label = PEXStr(@"L_mute_disabled");
    } else if (valueInt >= current+2ll*PEX_YEAR_IN_SECONDS*1000ll) {
        label = PEXStr(@"L_until_enabled");
    } else {
        NSDate *date = [PEXUtils dateFromMillis:(uint64_t) [value longLongValue]];
        label = [PEXDateUtils dateToFullDateString:date];
    }

    [self.disableSoundNotificationsView setValue:label];
}

-(void) loadMuteVibrationsPeriodView
{
    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_VIBRATIONS_MILLISECOND
                                                                      defaultValue:@(0)];

    NSString * label = nil;
    uint64_t current = [PEXUtils currentTimeMillis];
    uint64_t valueInt = (uint64_t)[value longLongValue];

    if (value == nil || valueInt <= current) {
        label = PEXStr(@"L_mute_disabled");
    } else if (valueInt >= current+2ll*PEX_YEAR_IN_SECONDS*1000ll) {
        label = PEXStr(@"L_until_enabled");
    } else {
        NSDate *date = [PEXUtils dateFromMillis:(uint64_t) [value longLongValue]];
        label = [PEXDateUtils dateToFullDateString:date];
    }

    [self.disableVibrationsView setValue:label];
}

-(void) loadCallTone {
    NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_CALL_TONE defaultValue:nil];
    PEXGuiTone * tone = [PEXGuiToneHelper getRingToneById:value];
    [self.soundRingtoneView setValue:tone.toneName];
}

-(void) loadMissedTone {
    NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_MISSED_TONE defaultValue:nil];
    PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
    [self.missedCallToneView setValue:tone.toneName];
}

-(void) loadMessageTone {
    NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_MESSAGE_TONE defaultValue:nil];
    PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
    [self.messageNotificationToneView setValue:tone.toneName];
}

-(void) loadNotificationTone {
    NSString * const value = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_APPLICATION_NOTIFICATION_TONE defaultValue:nil];
    PEXGuiTone * tone = [PEXGuiToneHelper getNotificationToneById:value];
    [self.notificationToneView setValue:tone.toneName];
}

- (void) loadRepeatSoundNotification
{
    [self.repeatSoundNotification setChecked:
            [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION
                                                   defaultValue: PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION_DEFAULT]];
}

- (void) loadVibrateForCall
{
    [self.vibrateForCalls setChecked:
            [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_APPLICATION_VIBRATE_ON_CALL
                                                   defaultValue: PEX_PREF_APPLICATION_VIBRATE_ON_CALL_DEFAULT]];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.disableAllNotificationsView];
    [PEXGVU scaleHorizontally:self.disableSoundNotificationsView];
    [PEXGVU scaleHorizontally:self.disableVibrationsView];

    [PEXGVU scaleHorizontally:self.soundRingtoneView];
    [PEXGVU scaleHorizontally:self.messageNotificationToneView];
    [PEXGVU scaleHorizontally:self.missedCallToneView];
    [PEXGVU scaleHorizontally:self.notificationToneView];

    [PEXGVU scaleHorizontally:self.repeatSoundNotification];
    [PEXGVU scaleHorizontally:self.vibrateForCalls];

    [PEXGVU scaleHorizontally:self.lineFirst];
    [PEXGVU scaleHorizontally:self.lineSecond];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.disableAllNotificationsView addAction:self action:@selector(showMuteNotificationsInternal)];
    [self.disableSoundNotificationsView addAction:self action:@selector(showMuteSoundInternal)];
    [self.disableVibrationsView addAction:self action:@selector(showMuteVibrationsInternal)];

    [self.soundRingtoneView addAction:self action:@selector(showCallToneInternal)];
    [self.messageNotificationToneView addAction:self action:@selector(showMessageToneInternal)];
    [self.missedCallToneView addAction:self action:@selector(showMissedCallToneInternal)];
    [self.notificationToneView addAction:self action:@selector(showNotificationToneInternal)];

    [self.repeatSoundNotification addAction:self action:@selector(repeatSoundNotificationInternal)];
    [self.vibrateForCalls addAction:self action:@selector(vibrateOnCallInternal)];
}

- (void) showMuteNotificationsInternal
{
    PEXMuteNotificationExecutor * const executor = [[PEXMuteNotificationExecutor alloc]
            initWithParentController:self prefKey:PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND];

    [executor show];
}

- (void) showMuteVibrationsInternal
{
    PEXMuteNotificationExecutor * const executor = [[PEXMuteNotificationExecutor alloc]
            initWithParentController:self prefKey:PEX_PREF_APPLICATION_MUTE_VIBRATIONS_MILLISECOND];
    [executor show];
}

- (void) showMuteSoundInternal
{
    PEXMuteNotificationExecutor * const executor = [[PEXMuteNotificationExecutor alloc]
            initWithParentController:self prefKey:PEX_PREF_APPLICATION_MUTE_SOUND_MILLISECOND];
    [executor show];
}

- (void) showCallToneInternal {
    PEXGuiTonesExecutor * const executor = [[PEXGuiTonesExecutor alloc]
            initWithParentController:self
                            toneList:[PEXGuiToneHelper getRingtones]
                             prefKey:PEX_PREF_APPLICATION_CALL_TONE];
    [executor show];
}

- (void) showMessageToneInternal {
    PEXGuiTonesExecutor * const executor = [[PEXGuiTonesExecutor alloc]
            initWithParentController:self
                            toneList:[PEXGuiToneHelper getNotifications]
                             prefKey:PEX_PREF_APPLICATION_MESSAGE_TONE];
    [executor show];
}

- (void) showMissedCallToneInternal {
    PEXGuiTonesExecutor * const executor = [[PEXGuiTonesExecutor alloc]
            initWithParentController:self
                            toneList:[PEXGuiToneHelper getNotifications]
                             prefKey:PEX_PREF_APPLICATION_MISSED_TONE];
    [executor show];
}

- (void) showNotificationToneInternal {
    PEXGuiTonesExecutor * const executor = [[PEXGuiTonesExecutor alloc]
            initWithParentController:self
                            toneList:[PEXGuiToneHelper getNotifications]
                             prefKey:PEX_PREF_APPLICATION_NOTIFICATION_TONE];
    [executor show];
}

- (void) repeatSoundNotificationInternal
{
    const bool isChecked = [self.repeatSoundNotification isChecked];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION
                                                      value:!isChecked];
    });
}

- (void) vibrateOnCallInternal
{
    const bool isChecked = [self.vibrateForCalls isChecked];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_APPLICATION_VIBRATE_ON_CALL
                                                      value:!isChecked];
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [self.lock lock];

    [[PEXAppPreferences instance] removeListener:self];

    [self.lock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)secondaryButtonClicked {

}

- (void)primaryButtonClicked {

}


@end