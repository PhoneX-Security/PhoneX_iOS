//
//  PEXIncommingCall.m
//  Phonex
//
//  Created by Matej Oravec on 25/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXIncommingCall.h"
#import "PEXCall_Protected.h"
#import "PEXGuiTone.h"
#import "PEXGuiToneHelper.h"
#import "PEXApplicationStateChange.h"
#import "PEXUtils.h"

#import <AVFoundation/AVFoundation.h>

const static double PEX_VIBRATION_TIMER = 4.0;

@interface PEXIncommingCall ()

@property (nonatomic) PEXPjCall * pjCall;

@property (nonatomic, retain) AVAudioPlayer * player;

@property (atomic) BOOL callHandled;
@property (atomic) BOOL ringingStarted;
@property (assign) BOOL vibrationsStarted;
@property (atomic) BOOL notificationPosted;
@property (atomic) BOOL observerRegistered;

@property (nonatomic) NSRecursiveLock * vibrationLock;
@property (nonatomic) NSTimer * vibrationTimer;
@property (nonatomic) volatile BOOL vibrationsActive;

@end

@implementation PEXIncommingCall

- (id) initWithContact: (const PEXDbContact * const) contact
                pjCall: (PEXPjCall * const) pjCall
{
    self = [super initWithContact:contact];

    self.pjCall = pjCall;
    _callId = pjCall.callId;

    // Register on app state changes - on app becomes active.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];
    self.observerRegistered = YES;

    NSURL * soundUrl = nil;
    PEXGuiTone * tone = [PEXAppNotificationCenter getIncomingCallTone];
    if (tone != nil){
        soundUrl = tone.toneUrl;
        AVAudioPlayer * const player = [[AVAudioPlayer alloc] initWithContentsOfURL: soundUrl error: nil];
        player.numberOfLoops = -1;
        player.currentTime = 0;
        player.volume = 1.0;
        self.player = player;
    }

    self.callHandled = NO;
    self.ringingStarted = NO;
    self.notificationPosted = NO;
    self.vibrationsStarted = NO;
    self.vibrationsActive = NO;
    self.vibrationLock = [[NSRecursiveLock alloc] init];

    return self;
}

- (void)dealloc {
    [self doUnregister];
}

// i.e. pick up (it is already ringing)
- (void) start
{
    [self started];

    // start ringing
    // TODO presenttation module start also ringing
    
    [self ringing];

    PEXService * svc = [PEXService instance];
    // Register for new callbacks.
    [svc.pjManager registerCallDelegate:@(_callId) delegate:self];
}

- (void) pickUp
{
    self.callHandled = YES;
    [self hideNotification];
    /*pj_status_t status = */[[PEXService instance].pjManager answerCall:_callId code:PEX_CALL_CODE_OK];
}

- (void) reject
{
    self.callHandled = YES;
    [self hideNotification];
    if ([[PEXService instance].pjManager answerCall:_callId code:PEX_CALL_CODE_DECLINE] != PJ_SUCCESS)
    {
        [self end];
    }
}

- (void) preDisconnected
{
    [self hideNotification];
}

/**
 * IPH-362: In postConnected we make sure ringing and call notification is not displayed.
 * QA was able to reproduce a bug with very bad internet connection when after answering a call and finishing the encryption
 * ringing tone was playing to the call.
 */
- (void)postConnected {
    [super postConnected];
    [self hideNotification];
}

- (void) ringing
{
    // Avoid starting ringing after pickup, race conditions (IPH-362, IPH-365).
    if (self.callHandled || self.ringingStarted || self.notificationPosted){
        return;
    }

    // Ringing logic - different in background and foreground.
    [self startRingingIfApplicable];

    // Notification logic - same in both modes.
    self.notificationPosted = YES;
    [[PEXANFC instance] showIncommingCallNotification];

    [super ringing];
}

- (void) startRingingIfApplicable {
    // Vibration notifications in foreground.
    [self startExtraVibrations];

    if (self.callHandled || self.ringingStarted){
        return;
    }

    // In the background ringing is not started as notifications takes the role.
    PEXService * svc = [PEXService instance];
    if ([svc isInBackground]){
        return;
    }

    self.ringingStarted = YES;
    [self.player play];
}

- (void) stopRingingIfApplicable {
    // Stop extra vibrations if allowed.
    [self stopExtraVibrations];

    if (!self.ringingStarted){
        return;
    }

    [self.player stop];
    self.ringingStarted = NO;
}

- (void) startExtraVibrations {
    if (self.callHandled || self.vibrationsStarted){
        return;
    }

    // Vibrations and notifications disabled?
    if (![PEXAppNotificationCenter areVibrationNotificationsAllowed]){
        return;
    }

    // Start vibrating applicable.
    const BOOL extraVibrations = [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_APPLICATION_VIBRATE_ON_CALL
                                                                        defaultValue: PEX_PREF_APPLICATION_VIBRATE_ON_CALL_DEFAULT];
    if (!extraVibrations){
        return;
    }

    // In the background ringing is not started as notifications takes the role.
    PEXService * svc = [PEXService instance];
    if ([svc isInBackground]){
        return;
    }

    self.vibrationsActive = YES;
    self.vibrationsStarted = YES;
    [self doVibrateOnce];
    [self scheduleVibrationTimer];
}

-(void) scheduleVibrationTimer {
    if (!self.vibrationsActive){
        return;
    }

    [self.vibrationLock lock];
    @try {
        self.vibrationTimer = [NSTimer timerWithTimeInterval:PEX_VIBRATION_TIMER
                                                      target:self
                                                    selector:@selector(onVibrationTimerFired:)
                                                    userInfo:nil
                                                     repeats:NO];

        [[NSRunLoop mainRunLoop] addTimer:self.vibrationTimer forMode:NSRunLoopCommonModes];

    } @catch(NSException * e){
        DDLogError(@"Exception in stopping vibrations %@", e);
    } @finally {
        [self.vibrationLock unlock];
    }
}

-(void) onVibrationTimerFired:(NSTimer *)timer {
    DDLogDebug(@"Vibration timer fired %@", timer);
    if (!self.vibrationsActive){
        return;
    }

    [self doVibrateOnce];

    // Next vibration
    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
        [weakSelf scheduleVibrationTimer];
    }];
}

- (void) doVibrateOnce {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void) stopExtraVibrations {
    if (!self.vibrationsStarted){
        return;
    }

    [self.vibrationLock lock];
    @try {
        self.vibrationsActive = NO;
        self.vibrationsStarted = NO;

        [self.vibrationTimer invalidate];
        self.vibrationTimer = nil;

    } @catch(NSException * e){
        DDLogError(@"Exception in stopping vibrations %@", e);
    } @finally {
        [self.vibrationLock unlock];
    }
}

/**
 * IPH-365: Make really sure ringing tone is disabled when invite transaction starts to connecting.
 * It probably happens that ringing is started after pickup call.
 */
- (void)encrypting {
    [super encrypting];
    [self hideNotification];
}

-(void) hideNotification {
    if (self.ringingStarted) {
        [self.player stop];
    }

    [self stopExtraVibrations];

    [[PEXANFC instance] hideIncommingCallNotification];
    [self doUnregister];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    WEAKSELF;
    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
            [weakSelf startRingingIfApplicable];
        }];
    } else if (change.stateChange == PEX_APPSTATE_WILL_RESIGN_ACTIVE){
        [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
            [weakSelf stopRingingIfApplicable];
        }];
    }
}

-(void) doUnregister {
    if (!self.observerRegistered){
        return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.observerRegistered = NO;
}

@end
