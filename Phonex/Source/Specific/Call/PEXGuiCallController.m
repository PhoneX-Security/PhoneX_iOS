//
//  PEXGuiCallBaseViewController.m
//  Phonex
//
//  Created by Matej Oravec on 03/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiCallController.h"
#import "PEXGuiControllerDecorator_Protected.h"

#import "PEXGuiImageView.h"
#import "PEXGuiImageClickableView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiButtonMain.h"

#import "PEXGuiLinearScalingView.h"
#import "PEXGuiCallButtonView.h"
#import "PEXGuiCheckCallButtonView.h"

#import "PEXDbContact.h"

#import "PEXOutgoingCall.h"
#import "PEXIncommingCall.h"

#import "PEXGuiEndCallButton.h"
#import "PEXGuiClickableView.h"
#import "PEXGuiCircleView.h"

#import "PEXGuiCallManager.h"
#import "PEXDateUtils.h"

#import "PEXGuiSasController.h"
#import "PEXPjManager.h"
#import "PEXGuiSasBinaryVisitor.h"

#import "PEXSipCodes.h"

#import "PEXGuiLoginController.h"
#import "PEXReport.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiFactory.h"
#import "PEXService.h"
#import "PEXGrandSelectionManager.h"
#import "PEXUtils.h"

// TODO react on pos-sync with server ~ cut off the call if needed

// TODO disallow call on insufficient minuites?


@interface PEXGuiCallController ()
{
    @private
    volatile bool _cancelCounting;
    volatile uint64_t _cancellationInterval;
    volatile bool _countingWasFired;
    volatile bool _callFinished;

    bool _isOutgoing;
    bool _endedNoMinutesLeft;

    bool _mutedMicrophoneWanted;
    bool _loudSpeakerActiveWanted;
    bool _bluetoothActiveWanted;
}

// sas
@property (nonatomic) PEXGuiController * sasControllerWindow;
@property (nonatomic) PEXPjCall * sasCallInfo;

@property (nonatomic) UIImageView * I_fancyImage;
@property (nonatomic) UILabel * L_status;
@property (nonatomic) UILabel * L_name;
@property (nonatomic) UILabel * L_time;
@property (nonatomic) UILabel * L_remainingTime;

@property (nonatomic) UIView * B_answer;
@property (nonatomic) UIView * B_reject;
@property (nonatomic) PEXGuiImageView * I_answer;
@property (nonatomic) PEXGuiImageView * I_reject;
@property (nonatomic) PEXGuiClickableView * B_answerWrapper;
@property (nonatomic) PEXGuiClickableView * B_rejectWrapper;

@property (nonatomic) PEXGuiEndCallButton * B_endCall;
@property (nonatomic) PEXGuiLinearContainerView * B_row;
@property (nonatomic) PEXGuiCheckCallButtonView * B_speaker;
@property (nonatomic) PEXGuiCheckCallButtonView * B_microphone;
@property (nonatomic) PEXGuiCheckCallButtonView * B_bluetooth;
@property (nonatomic) UIView * V_settings;

@property (nonatomic) PEXCall * call;
@property (nonatomic, copy) void (^initCallState)(void);

@property (nonatomic, assign) int64_t finalCallDuration;
@property (nonatomic) dispatch_queue_t callGeneralQueue;

@property (nonatomic) NSLock * counterLock;

@property (nonatomic) PEXGuiController * infoBox;
@property (nonatomic, copy) dispatch_block_t onGsmFinishBlock;
@property (nonatomic, copy) dispatch_block_t infoBoxFinishBlock;

@property (nonatomic) PEXGuiNotEnoughListener * notEnoughListener;
@property (nonatomic) PEXGuiController * notEnoughDialog;
@property (nonatomic, copy) dispatch_block_t notEnoughFinishBlock;

@end

@implementation PEXGuiCallController

- (void) bringTofront
{
    [[PEXGuiLoginController instance].landingController.view bringSubviewToFront:self.view];

    // just moving the view of the sas controller to front did not work
    if (self.sasControllerWindow)
    {
        [PEXGVU executeWithoutAnimations:^{
            [self justDismissSasDialog:^{
                [self showSasDialog];
            }];
        }];
    }
}

// TODO mutex
- (void)setIsUnlimitedPost:(bool)isUnlimited
{
    _isUnlimited = isUnlimited;

    if (isUnlimited)
    {
        [self setCancellation];
        self.maxCallDurationInSeconds = INT64_MAX;
    }
    else
    {
        [self startCounter];
    }

}

- (BOOL)dismissEverythingIfCallEnded {
    if (!_callFinished){
        return NO;
    }

    // Info box, internal call error.
    @try {
        if (self.infoBox != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.infoBox dismissViewControllerAnimated:NO completion:nil];
            });
        }

        if (self.infoBoxFinishBlock != nil) {
            self.infoBoxFinishBlock();
        }
    } @catch(NSException *e){
        DDLogError(@"Exception when dismissing controller1: %@", e);
    }

    // Info box, not enough minutes.
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (self.notEnoughDialog != nil) {
                [self.notEnoughDialog dismissViewControllerAnimated:NO completion:nil];
            }

            if (self.notEnoughFinishBlock) {
                self.notEnoughFinishBlock();
            }
        } @catch (NSException *e) {
            DDLogError(@"Exception when dismissing controller2: %@", e);
        }
    });

    return YES;
}

- (BOOL)hasCallEnded {
    return _callFinished;
}


- (id) initWithOutgoingCall: (PEXOutgoingCall *) call
{
    self = [self init];

    self.call = call;
    _isOutgoing = true;

    WEAKSELF;
    self.initCallState = ^{[weakSelf showCallIsOn];};

    return self;
}

- (id) initWithIncommingCall: (PEXIncommingCall *) call
{
    self = [self init];

    self.call = call;
    _isOutgoing = false;

    WEAKSELF;
    self.initCallState = ^{[weakSelf showBeingCalled];};

    return self;
}

- (id) init
{
    self = [super init];

    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("call_general_queue", nil);
    });
    self.callGeneralQueue = queue;

    _cancelCounting = false;
    _countingWasFired = false;
    _mutedMicrophoneWanted = false;
    _loudSpeakerActiveWanted = false;
    _bluetoothActiveWanted = [[PEXPjManager instance] isHandsfreeDefault];
    _callFinished = NO;
    _onGsmFinishBlock = nil;
    _infoBoxFinishBlock = nil;
    _endedNoMinutesLeft = NO;
    _notEnoughFinishBlock = nil;
    self.infoBox = nil;

    self.counterLock = [[NSLock alloc] init];
    self.finalCallDuration = 0LL;
    // DANGER equation may overflow ... but is not set only for incoming calls
    self.maxCallDurationInSeconds = INT64_MAX;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"Call";

    self.I_fancyImage = [[PEXGuiImageView alloc] init];
    [self.mainView addSubview: self.I_fancyImage];

    self.L_status = [[PEXGuiBaseLabel alloc]
                          initWithFontSize:PEXVal(@"dim_size_medium")
                          fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview: self.L_status];

    self.L_name = [[PEXGuiBaseLabel alloc]
                     initWithFontSize:PEXVal(@"dim_size_medium")
                     fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview: self.L_name];

    self.L_time = [[PEXGuiBaseLabel alloc]
                   initWithFontSize:PEXVal(@"dim_size_large")
                   fontColor:PEXCol(@"orange_normal")];
    [self.mainView addSubview: self.L_time];

    self.L_remainingTime = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview: self.L_remainingTime];

    self.B_endCall = [[PEXGuiEndCallButton alloc] init];
    [self.mainView addSubview:self.B_endCall];

    self.B_answerWrapper = [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview: self.B_answerWrapper];
    self.B_answer = [[PEXGuiCircleView alloc] initWithDiameter:PEXVal(@"B_call_diameter")];
    self.I_answer = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"pickup")];
    [self.B_answer addSubview:self.I_answer];
    [self.B_answerWrapper addSubview: self.B_answer];

    self.B_rejectWrapper = [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview: self.B_rejectWrapper];
    self.B_reject = [[PEXGuiCircleView alloc] initWithDiameter:PEXVal(@"B_call_diameter")];
    self.I_reject = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"reject")];
    [self.B_reject addSubview:self.I_reject];
    [self.B_rejectWrapper addSubview: self.B_reject];

    self.B_row = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
    [self.mainView addSubview:self.B_row];


    self.B_speaker = [[PEXGuiCheckCallButtonView alloc] initWithImage:
                      [[PEXGuiImageView alloc]
                       initWithImage:PEXImg(@"speaker")]
                                                         labelText:
                      PEXStrU(@"B_speaker")];
    [self.B_row addView:self.B_speaker];

    self.B_bluetooth = [[PEXGuiCheckCallButtonView alloc] initWithImage:
                      [[PEXGuiImageView alloc]
                       initWithImage:PEXImg(@"bluetooth")]
                                                         labelText:
                      PEXStrU(@"B_bluetooth")];
    if ([[PEXPjManager instance] isHandsfreeDefault]){
        [self.B_bluetooth check];
    }

    [self.B_row addView:self.B_bluetooth];

    self.B_microphone = [[PEXGuiCheckCallButtonView alloc] initWithImage:
                         [[PEXGuiImageView alloc]
                          initWithImage:PEXImg(@"mic")]
                                                         labelText:PEXStrU(@"B_mute")];
    [self.B_row addView:self.B_microphone];

//    self.V_settings = [[PEXGuiCallButtonView alloc] initWithImage:
//                       [[PEXGuiImageView alloc]
//                        initWithImage:PEXImg(@"settings")]
//                                                         labelText:PEXStrU(@"B_settings")];
//    [self.B_row addView:self.V_settings];

    [self.L_time setHidden:true];
    [self.L_remainingTime setHidden:true];
}

- (void) initContent
{
    [super initContent];

    [self.B_endCall setTitle:PEXStrU(@"B_end_call")
                    forState:UIControlStateNormal];

    self.B_answer.backgroundColor = PEXCol(@"green_normal");
    self.B_reject.backgroundColor = PEXCol(@"red_normal");

    self.L_time.text = @"";

    [self setImage:PEXImg(@"logo_large")];
}

- (void) initState
{
    [super initState];

    _cancelCounting = false;
    _cancellationInterval = 0ULL;
    [self setText:self.call.contact.displayName forLabel:self.L_name];

    //[self setTimeInterval:0ULL];
    //[self setTimeInterval:self.maxCallDurationInSeconds];
}

- (void) setTimeInterval: (const int64_t) intervalInSeconds
{
    [self setText:[PEXGuiCallController getTimeIntervalStringFromTime:intervalInSeconds] forLabel:self.L_time];
}

+ (NSString *) getTimeIntervalStringFromTime: (const int64_t) intervalInSeconds
{
    const int seconds = (int) intervalInSeconds % 60;
    const int minutes = (int) ((intervalInSeconds / 60) % 60);
    const int hours   = (int) (intervalInSeconds / 3600);

    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU moveToBottom:self.B_endCall withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU scaleHorizontally:self.B_endCall withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU setHeight:self.B_row to:PEXVal(@"B_imageButton_height")];
    [PEXGVU move:self.B_row above:self.B_endCall withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU scaleHorizontally:self.B_row withMargin:PEXVal(@"dim_size_large")];

    // above the 3-way buttons

    [PEXGVU move:self.L_name above:self.B_row
      withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU centerHorizontally:self.L_name];

    [PEXGVU move:self.L_status above:self.L_name
      withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU centerHorizontally:self.L_status];

    [PEXGVU move:self.L_time above:self.L_status
      withMargin:PEXVal(@"dim_size_small") + self.L_remainingTime.frame.size.height];
    [PEXGVU centerHorizontally:self.L_time];

    [PEXGVU move:self.L_remainingTime below:self.L_time];
    [PEXGVU centerHorizontally:self.L_remainingTime];

    self.B_answerWrapper.frame = self.B_answer.frame;
    [PEXGVU moveToBottom:self.B_answerWrapper withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToRight:self.B_answerWrapper withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU center:self.I_answer];

    self.B_rejectWrapper.frame = self.B_reject.frame;
    [PEXGVU moveToBottom:self.B_rejectWrapper withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToLeft:self.B_rejectWrapper     withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU center:self.I_reject];

    [self positionImage];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setStatusText:PEXStrU(@" 	")];

    // can be NULL??
    self.initCallState();
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.call addListener:self];

    dispatch_async(self.callGeneralQueue, ^(void)
                   {
                       [self.call start];
                   });
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_answerWrapper addAction:self action:@selector(answer:)];
    [self.B_rejectWrapper addAction:self action:@selector(reject:)];

    [self.B_endCall addTarget:self action:@selector(endCall:)
           forControlEvents:UIControlEventTouchUpInside];

    PEXGuiCallController * const weakSelf = self;
    [self.B_microphone addActionBlock:^{ [weakSelf switchMicrophone]; }];
    [self.B_speaker addActionBlock:^{ [weakSelf switchLoudSpeaker]; }];
    [self.B_bluetooth addActionBlock:^{ [weakSelf switchBluetooth]; }];
}

- (void) showBeingCalled
{
    [self switchFace:YES];
}

- (void) showCallIsOn
{
    [self switchFace:NO];
}

- (void) switchFace: (const BOOL) beingCalled
{
    self.B_row.hidden = beingCalled;
    self.B_endCall.hidden = beingCalled;

    self.B_answer.hidden = !beingCalled;
    self.B_reject.hidden = !beingCalled;
}

- (void) setImage:(UIImage * const) image
{
    [self.I_fancyImage setImage:image];
    [self positionImage];
}

- (void) positionImage
{
    [PEXGVU centerHorizontally:self.I_fancyImage];
    [PEXGVU centerBetweenTop:self.I_fancyImage and:self.L_time];
}

- (void) setText:(NSString * const) text
        forLabel:(UILabel * const) label
{
    [label setText:text];
    label.textAlignment = NSTextAlignmentCenter;
    [PEXGVU scaleHorizontally:label withMargin:PEXVal(@"dim_size_large")];
}

- (IBAction) endCall:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_END_CALL];
    [self.call end];
}

- (IBAction) reject:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_REJECT_CALL];
    [self.call reject];
}

- (IBAction) answer:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_ANSWER_CALL];
    [self.call pickUp];
}

- (void) started
{
    [self setStatusTextAsync:PEXStrU(@"L_call_prepairing")];
}

- (void) ringing
{
    [self setStatusTextAsync:PEXStrU(@"L_call_ringing")];
}

- (void) connected
{
    dispatch_async(dispatch_get_main_queue(),
                   ^(void)
                   {
                       [self.L_time setHidden:false];
                       [self setStatusText:PEXStrU(@"L_call_connected")];
                   });

}

- (void)startCounter
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("call_counter_queue", nil);
    });


    dispatch_async(queue, ^{

        [self.counterLock lock];

        _countingWasFired = true;
        const uint64_t callStart = PEXGetPIDTimeInSeconds();

        while (!_cancelCounting)
        {
            const int64_t callDuration = (PEXGetPIDTimeInSeconds() - callStart);
            [self callDurationChanged:callDuration];

            [NSThread sleepForTimeInterval:0.25];
        }

        self.finalCallDuration = _cancellationInterval - callStart;

        [self.counterLock unlock];
    });
}

- (void) callDurationChanged: (const int64_t)durationInSeconds
{
    if ( (!self.isUnlimited) && (durationInSeconds >= self.maxCallDurationInSeconds))
    {
        _endedNoMinutesLeft = YES;
        dispatch_async(self.callGeneralQueue, ^{
            [self.call end];
        });
    }

    dispatch_sync(dispatch_get_main_queue(),
            ^{
                [self setTimeInterval:durationInSeconds];
            });

    if (_isOutgoing)
    {
        dispatch_sync(dispatch_get_main_queue(),
                ^{
                    [self setRemainingTimeTex:self.maxCallDurationInSeconds - durationInSeconds];
                    [PEXGVU centerHorizontally:self.L_remainingTime];

                    [self.L_remainingTime setHidden:_isUnlimited];
                });
    }
}

- (void) setRemainingTimeTex: (const int64_t) remainintgSeconds
{
    [self setText:
            [NSString stringWithFormat:@"%@: %@",
    PEXStrU(@"L_remaining_time"), [PEXGuiCallController getTimeIntervalStringFromTime:remainintgSeconds]]
         forLabel:self.L_remainingTime];
}

- (void) ended
{
    const bool countingWasFired = _countingWasFired;

    _callFinished = YES;
    [self setCancellation];

    if (_isOutgoing)
        [[PEXGuiCallManager instance] callTimeWasConsumed:self.finalCallDuration];
    // else do not count the minutes

    WEAKSELF;
    // Check available limits, show warning.
    if (_endedNoMinutesLeft){
        self.notEnoughFinishBlock = ^{
            weakSelf.notEnoughFinishBlock = nil;
            weakSelf.notEnoughListener = nil;
            weakSelf.notEnoughDialog = nil;
            [weakSelf dismissSasDialog];
            [weakSelf dismissViewControllerAnimated:NO completion:^{
                [[PEXGuiCallManager instance] unsetCallController:weakSelf];
            }];
        };

        UIViewController * landing = [PEXGuiLoginController instance].landingController;
        self.notEnoughListener = [[PEXGuiNotEnoughListener alloc] init];
        self.notEnoughListener.parent = self;
        self.notEnoughListener.primaryClickBlock = ^{
            if (weakSelf.notEnoughFinishBlock) {
                dispatch_async(dispatch_get_main_queue(), weakSelf.notEnoughFinishBlock);
            }
        };

        self.notEnoughListener.secondaryClickBlock = ^{
            if (weakSelf.notEnoughFinishBlock) {
                dispatch_async(dispatch_get_main_queue(), weakSelf.notEnoughFinishBlock);
            }
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            PEXGuiController * dialog = [PEXGuiFactory showBinaryDialog:weakSelf
                                                                   withText:PEXStrU(@"txt_not_enough_minutes_to_spend")
                                                                   listener:weakSelf.notEnoughListener
                                                              primaryAction:PEXStrU(@"L_buy")
                                                            secondaryAction:nil];
            weakSelf.notEnoughListener.dialog = dialog;
            weakSelf.notEnoughDialog = dialog;
        });

        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
        weakSelf.notEnoughFinishBlock = nil;
        weakSelf.notEnoughListener = nil;
        weakSelf.notEnoughDialog = nil;
        [weakSelf dismissSasDialog];
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            [[PEXGuiCallManager instance] unsetCallController:weakSelf];
        }];
    }});
}

- (void) setCancellation
{
    if (!_cancelCounting)
    {
        _cancellationInterval = PEXGetPIDTimeInSeconds();
        _cancelCounting = true;

        // waint until counting finishes
        [self.counterLock lock];

        _countingWasFired = false;

        [self.counterLock unlock];
    }
}

- (void) encrypting
{
    dispatch_async(dispatch_get_main_queue(),
                   ^(void)
                   {
                       [self showCallIsOn];
                       [self setStatusText:PEXStrU(@"L_call_encrypting")];
                   });

}

- (void) callIsInsecure
{
    [self setStatusTextAsync:PEXStrU(@"L_call_is_insecure")];
}

- (void) callIsSecure
{
    [self startCounter];

    [self setStatusTextAsync:PEXStrU(@"L_call_is_secure")];
}

- (void) showSas: (PEXPjCall * const)callInfo
{
    dispatch_async(dispatch_get_main_queue(),
                   ^(void)
                   {
                       self.sasCallInfo = callInfo;
                       [self showSasDialog];
                   });

}

- (void) showSasDialog
{
    PEXGuiController * sasController = [[PEXGuiSasController alloc]
            initWithSas:self.sasCallInfo.zrtpInfo.sas outgoing:_isOutgoing];


    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiSasBinaryVisitor alloc] initWithDialogSubcontroller:
                                                 sasController listener:self];

    PEXGuiController * const dialog = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];
    self.sasControllerWindow = [dialog showInWindow:self withTitle:PEXStrU(@"L_security")];
}

- (void) primaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_SAS_CONFIRM];
    [self dismissSasDialogWithCompletion:^{
        [self dismissSasDialog];
        [[PEXPjManager instance] sasVerified:self.sasCallInfo.callId async:true];
    }];
}

- (void) secondaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_SAS_REJECT];
    [self dismissSasDialogWithCompletion:^{
        [[PEXPjManager instance] sasRevoked:self.sasCallInfo.callId async:true];
        [self.call end];
    }];
}

- (void) dialling
{
    [self setStatusTextAsync:PEXStrU(@"L_dialling")];
}

- (void) setStatusTextAsync: (NSString * const) text
{
    dispatch_async(dispatch_get_main_queue(),
            ^{
                [self setStatusText:text];
            });
}

- (void) setStatusText: (NSString * const) text
{
    [self setText:text forLabel:self.L_status];
}

- (void) disconnected
{
    [self endCallWithReasonText: PEXStrU(@"L_disconnected")];
}

- (void) declined
{
    [self endCallWithReasonText: PEXStrU(@"L_rejected")];
}

- (void) hangUp
{
    [self endCallWithReasonText: PEXStrU(@"L_hung_up")];
}

- (void) endCallWithReasonText: (NSString * const) text
{
    _callFinished = YES;
    [self setCancellation];
    dispatch_async(dispatch_get_main_queue(),
                   ^(void)
                   {
                       [self dismissSasDialog];
                       [self setStatusText:text];
                   });
}

- (void) errorred: (NSNumber * const) errorCode
{
    NSString * statusMessage;

    // see http://en.wikipedia.org/wiki/List_of_SIP_response_codes
    switch (errorCode.integerValue)
    {
        case PEX_CALL_CODE_FORBIDDEN:
            statusMessage = PEXStrU(@"L_call_error_not_allowed");
            break;
        case PEX_CALL_CODE_NOT_FOUND:
            statusMessage = PEXStrU(@"L_call_error_callee_offline");
            break;
        case PEX_CALL_CODE_REQUEST_TIMEOUT: //almost the same as decline
            statusMessage = PEXStrU(@"L_call_error_timeout");
            break;
        case PEX_CALL_CODE_BUSY_HERE: //almost the same as decline
            statusMessage = PEXStrU(@"L_call_error_busy");
            break;
        case PEX_CALL_CODE_TEMPORARILY_UNAVAILABLE:
        case PEX_CALL_CODE_GONE: // Gone
            statusMessage = PEXStrU(@"L_call_error_callee_unavailable");
            break;
        case 477: // cannot send to next hop
            statusMessage = PEXStrU(@"L_call_error_cannot_reach_destination");
            break;
        case PEX_CALL_CODE_NOT_IMPLEMENTED:
            statusMessage = PEXStrU(@"L_call_error_not_implemented");
            break;
        case PEX_CALL_CODE_SERVICE_UNAVAILABLE: // service unavailable
            statusMessage = PEXStrU(@"L_call_error_servis_unavailable");
            break;
        case PJSIP_SC_GSM_BUSY: // service unavailable
            statusMessage = PEXStrU(@"L_call_error_gsm_busy_local");
            break;
        default: statusMessage = [NSString stringWithFormat:@"%@ %@", PEXStrU(@"L_errorred"), errorCode];
    }

    [self endCallWithReasonText:statusMessage];
}

- (void)gsmBusyLocal: (BOOL) isLocal finishBlock: (dispatch_block_t) finishBlock {
    WEAKSELF;

    _callFinished = YES;
    [self setCancellation];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * statusMessage = isLocal ? PEXStrU(@"L_call_error_gsm_busy_local") : PEXStrU(@"L_call_error_gsm_busy_remote");

        [weakSelf dismissSasDialog];
        [weakSelf setStatusText:PEXStrU(@"L_disconnected")];

        // In case of abort by another incoming call, user may not clicked on OK buton
        // so this dialog remains active.
        weakSelf.onGsmFinishBlock = finishBlock;
        weakSelf.infoBoxFinishBlock = ^{
            weakSelf.infoBox = nil;
            weakSelf.onGsmFinishBlock = nil;
            weakSelf.infoBoxFinishBlock = nil;
            if (finishBlock){
                finishBlock();
            }
        };

        weakSelf.infoBox = [PEXGuiFactory showInfoTextBox:weakSelf
                               withText:statusMessage
                             completion:^{
                                 if (finishBlock){
                                     weakSelf.infoBox = nil;
                                     weakSelf.onGsmFinishBlock = nil;
                                     weakSelf.infoBoxFinishBlock = nil;
                                     [PEXService executeDelayedWithName:@"call_disconnected_err" timeout:0.5 block:^{
                                         finishBlock();
                                     }];
                                 }
                             }];
    });
}

- (void)gsmBusyLocal: (dispatch_block_t) finishBlock {
    [self gsmBusyLocal:YES finishBlock:finishBlock];
}

- (void)gsmBusyRemote: (dispatch_block_t) finishBlock {
    [self gsmBusyLocal:NO finishBlock:finishBlock];
}

- (void) dismissSasDialog
{
    [self dismissSasDialogWithCompletion:nil];
}

- (void) dismissSasDialogWithCompletion: (void (^)(void))completion
{
    if (self.sasControllerWindow)
        [self.sasControllerWindow dismissViewControllerAnimated:true completion:^{
            self.sasControllerWindow = nil;

            if (completion)
                completion();
        }];
}

- (void)justDismissSasDialog: (void (^)(void))completion
{
    [self.sasControllerWindow dismissViewControllerAnimated:true completion:completion];
}

-(void) switchMicrophone
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_MUTE_MIC];
    WEAKSELF;

    // Disable button until process finishes.
    [self.B_microphone setEnabled:NO];

    [[PEXPjManager instance] muteMicrophone:!_mutedMicrophoneWanted async:YES onFinished:^(pj_status_t status) {
        [PEXUtils executeOnMain:YES block:^{
            [weakSelf.B_microphone setEnabled:YES];

            if (status == PJ_SUCCESS) {
                DDLogVerbose(@"Mic change completed");
                _mutedMicrophoneWanted = !_mutedMicrophoneWanted; // TODO: un-click button.
                [self.B_microphone check];
            }
        }];
    }];
}

-(void) switchLoudSpeaker
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOUDSPEAKER];
    WEAKSELF;

    // Disable button until process finishes.
    [self.B_speaker setEnabled:NO];

    [[PEXPjManager instance] switchAudioRoutingToLoud:!_loudSpeakerActiveWanted async:YES onFinished:^(pj_status_t status) {
        [PEXUtils executeOnMain:YES block:^{
            [weakSelf.B_speaker setEnabled:YES];

            if (status == PJ_SUCCESS) {
                DDLogVerbose(@"Speaker switch completed");
                _loudSpeakerActiveWanted = !_loudSpeakerActiveWanted; // TODO: un-click button.
                [self.B_speaker check];
            }
        }];
    }];
}

-(void) switchBluetooth
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_BLUETOOTH];
    WEAKSELF;

    // Disable button until process finishes.
    [self.B_bluetooth setEnabled:NO];

    // Execute async.
    [[PEXPjManager instance] switchBluetooth:!_bluetoothActiveWanted async:YES onFinished:^(pj_status_t status) {
        [PEXUtils executeOnMain:YES block:^{
            [weakSelf.B_bluetooth setEnabled:YES];

            if (status == PJ_SUCCESS || status == EALREADY){
                DDLogVerbose(@"BT switch completed");
                _bluetoothActiveWanted = !_bluetoothActiveWanted;
                [weakSelf.B_bluetooth check];

                // Doing whatever with bluetooth disables loudspeaker mode
                if (_loudSpeakerActiveWanted){
                    _loudSpeakerActiveWanted = NO;
                    [weakSelf.B_speaker check];
                }
            }
        }];
    }];
}

@end
