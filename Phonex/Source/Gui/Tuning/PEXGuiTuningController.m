//
// Created by Matej Oravec on 15/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXGuiTuningController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXPjManager.h"
#import "PEXPjRegStatus.h"
#import "PEXXmppManager.h"
#import "PEXService.h"
#import "PEXXmppCenter.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXDatabase.h"
#import "PEXUtils.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiLinearContainerView.h"
#import "PEXGuiLinearScalingView.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiLogController.h"

@interface PEXGuiTuningController()

@property (nonatomic) NSLock * lock;

@property (nonatomic) PEXGuiLinearContainerView * linearView;
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) PEXGuiDetailView * V_sipReg;
@property (nonatomic) PEXGuiDetailView * V_xmppReg;

@property (nonatomic) PEXGuiLinearContainerView * B_buttons;
@property (nonatomic) PEXGuiButtonMain * B_restartSip;
@property (nonatomic) PEXGuiButtonMain * B_logview;
@property (nonatomic) PEXGuiButtonMain * B_refresh;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_status;
@end


@implementation PEXGuiTuningController {

}

- (void)initGuiComponents {

    [super initGuiComponents];

    self.linearView = [[PEXGuiLinearRollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{

        self.V_sipReg = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_sipReg];

        self.V_xmppReg = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_xmppReg];

        self.B_buttons = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
        self.B_restartSip = [[PEXGuiButtonMain alloc] init];
        self.B_refresh = [[PEXGuiButtonMain alloc] init];
        self.B_logview = [[PEXGuiButtonMain alloc] init];

        // Required for correct setting of button bar.
        [self.B_restartSip setTitle:PEXStrU(@"SIP RESTART") forState:UIControlStateNormal];
        [self.B_refresh setTitle:PEXStrU(@"REFR") forState:UIControlStateNormal];
        [self.B_logview setTitle:PEXStrU(@"LOGS") forState:UIControlStateNormal];

        [self.linearView addView:self.B_buttons];
        [self.B_buttons addView:self.B_restartSip];
        [self.B_buttons addView:self.B_refresh];
        [self.B_buttons addView:self.B_logview];

        // Required so tv_status is placed below buttons.
        [PEXGVU setHeight:self.B_buttons to:self.B_restartSip.frame.size.height];

        self.TV_status = [[PEXGuiReadOnlyTextView alloc] init];
        [PEXGVU setHeight:self.TV_status to:2048];  // will be adjusted later, for scrolling purposes. Last element in the linear layout
        self.TV_status.backgroundColor = PEXCol(@"light_gray_high");
        [self.linearView addView:self.TV_status];

        DDLogVerbose(@"All done");
    }];
}

- (void) initContent
{
    [super initContent];
    [self.V_sipReg setName:@"SIP"];
    [self.V_xmppReg setName:@"XMPP"];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.V_sipReg];
    [PEXGVU scaleHorizontally:self.V_xmppReg];
    [PEXGVU scaleHorizontally:self.B_buttons];
    [PEXGVU setHeight:self.B_buttons to:self.B_restartSip.frame.size.height];

    [PEXGVU scaleHorizontally:self.TV_status];
    [PEXGVU scaleVertically:self.TV_status below:self.B_buttons master:self.mainView withMargin:PEXVal(@"line_width_small")];

    [self.linearView sizeToFit];
    [PEXGVU scaleFull:self.linearView];
}

- (void)initBehavior
{
    [super initBehavior];

    WEAKSELF;
    self.queue = dispatch_queue_create("tuning_queue", nil);
    self.lock = [[NSLock alloc] init];

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    [self.lock lock];
    [self.V_sipReg addActionBlock:^{
        DDLogVerbose(@"Going to re-register SIP");
        [[PEXPjManager instance] reregister:YES allowDuringCall:YES manual:YES];
    }];

    [self.B_restartSip addTarget:self action:@selector(restartSip:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.B_refresh addTarget:self action:@selector(refresh:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.B_logview addTarget:self action:@selector(logs:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.V_xmppReg addActionBlock:^{
        DDLogVerbose(@"Going to re-register XMPP");
        [[[PEXXmppCenter instance] xmppManager] triggerReconnect];
    }];

    [center addObserver:self selector:@selector(onSipConnection:) name:PEX_ACTION_SIP_REGISTRATION object:nil];
    [center addObserver:self selector:@selector(onXmppConnection:) name:PEX_ACTION_XMPP_CONNECTION object:nil];

    [self fillRegFieldsUnsafe];
    [self.lock unlock];
}

- (IBAction) refresh: (id) sender
{
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat prevContentOffset = weakSelf.TV_status.contentOffset.y;
        [weakSelf fillRegFields];
        [weakSelf fillStatusText];
        [weakSelf.TV_status setContentOffset:CGPointMake(0, prevContentOffset)];
    });
}

- (IBAction) restartSip: (id) sender
{
    DDLogVerbose(@"Going to restart SIP");
    [[PEXPjManager instance] watchdogTrigger];
}

- (IBAction) logs: (id) sender
{
    DDLogVerbose(@"Logview");
    [PEXGAU showInNavigation:[[PEXGuiLogController alloc] init]
                          in:self
                       title:PEXStrU(@"L_logs")];
}

- (void) setSipStatus: (const PEXPjRegStatus * const) status
{
    NSString * statusLine = [[status.lastStatusText componentsSeparatedByString:@"\n"][0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * const value = status ? [[NSString alloc] initWithFormat:
            @"%@ | %@ | %@ | %d | %@ | ex:%d",
            status.ipReregistrationInProgress ? @"ip-reg" : @"idle",
            statusLine,
            status.registered ? @"ON" : @"OFF",
            status.lastStatusCode,
            [PEXUtils dateDiffFromNowFormatted:status.created compact:YES],
            status.expire
            ] :
            @"NULL_STATUS";

    [self.V_sipReg setValue:value];
}

- (void)onSipConnection:(NSNotification *)notice
{
    dispatch_async(self.queue, ^{
        [self.lock lock];

        dispatch_sync(dispatch_get_main_queue(), ^{

            const PEXPjRegStatus * const status = notice.userInfo[PEX_EXTRA_SIP_REGISTRATION];
            [self setSipStatus:status];
            [self fillStatusText];
        });

        [self.lock unlock];
    });
}

- (void) setXmppStatus: (const NSNumber * const) connected
{
    NSString * const value = connected ? [[NSString alloc] initWithFormat:
            @"%@", [connected boolValue] ? @"ON" : @"OFF"] :
            @"STATUS_NULL";

    [self.V_xmppReg setValue:value];
}

- (void)onXmppConnection:(NSNotification *)notice {

    dispatch_async(self.queue, ^{
        [self.lock lock];

        dispatch_sync(dispatch_get_main_queue(), ^{

            const NSNumber * const connected = notice.userInfo[PEX_EXTRA_XMPP_CONNECTION];
            [self setXmppStatus:connected];
            [self fillStatusText];
        });

        [self.lock unlock];
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    [self.lock lock];

    [center removeObserver:self];

    [self.lock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

-(void) fillRegFieldsUnsafe {
    [self setSipStatus:[[PEXPjManager instance] regStatus]];
    [self setXmppStatus:@([[[[PEXService instance] xmppCenter] xmppManager] isConnected])];
}

-(void) fillRegFields {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            DDLogVerbose(@"Reg fields update");
            [weakSelf fillRegFieldsUnsafe];
        } @catch(NSException * e){
            DDLogError(@"Excetion in setting reg fields: %@", e);
        }
    });
}

- (void) fillStatusText
{
    dispatch_async(self.queue, ^{
        @try {
            PEXPjManager *pjMgr = [PEXPjManager instance];
            NSString *const textToShow = [NSString stringWithFormat:
                    @"- SIP watchdog report: \n%@\n\n"
                            "- SIP reg watcher report:\n%@\n\n"
                            "- XMPP report:\n%@\n\n"
                            "- DB report:\n%@\n\n"
                            "- SVC report:\n%@\n\n"
                            "Report generated: %@",

                    [pjMgr watchdogReport],
                    [pjMgr regWatcherReportForUI],
                    [[[PEXXmppCenter instance] xmppManager] xmppReportForUI],
                    [[PEXDatabase instance] genDbLogReport],
                    [[PEXService instance] getServiceReport],
                    [NSDate date]
            ];

            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.TV_status setText:textToShow];
            });
        } @catch(NSException * e){
            DDLogError(@"Exception in generating tuning report: %@", e);
        }
    });
}

@end