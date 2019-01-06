//
//  PEXGuiProfileController.m
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiProfileController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiDetailView.h"

#import "PEXGuiChangePasswordExecutor.h"

#import "PEXUserPrivate.h"
#import "PEXLicenceManager.h"
#import "PEXLicenceInfo.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXGuiChangePasswordController.h"
#import "PEXGuiPoint.h"
#import "PEXAppVersionUtils.h"
#import "PEXGuiSendLogsController.h"
#import "PEXTermsOfUseUtils.h"
#import "PEXReport.h"
#import "PEXPermissionsUtils.h"
#import "PEXService.h"
#import "PEXGuiInviteFriendsController.h"
#import "PEXGuiButtonDIalogSecondary.h"
#import "PEXDBUserProfile.h"
#import "PEXDbAppContentProvider.h"
#import "PEXUtils.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXGuiRecoveryEmailController.h"

@interface PEXGuiProfileController () <PEXContentObserver>
{
@private
    NSUInteger _getPremiumViewPosition;
}

@property (nonatomic) PEXGuiLinearScrollingView * linearView;

@property (nonatomic) PEXGuiDetailView * B_changePassword;
@property (nonatomic) PEXGuiDetailView * V_username;
@property (nonatomic) PEXGuiDetailView * B_recoveryEmail;

@property (nonatomic) PEXGuiDetailView * V_licenceType;

@property (nonatomic) PEXGuiPoint * lineTwo;
@property (nonatomic) UIView * B_getPremiumBackground;
@property (nonatomic) PEXGuiButtonMain * B_getPremium;

@property (nonatomic) PEXGuiPoint * line;
@property (nonatomic) PEXGuiDetailView * V_termsOfUse;
@property (nonatomic) PEXGuiDetailView * V_appVersion;

@property (nonatomic) UIView * V_sendLogs;
@property (nonatomic) PEXGuiButtonMain * B_inviteUsers;
@property (nonatomic) PEXGuiButtonMain * B_sendLogs;

@property (nonatomic) PEXGuiInviteFriendsController * inviteController;

@end

@implementation PEXGuiProfileController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{

        self.V_username = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_username];

        self.B_recoveryEmail = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.B_recoveryEmail];

        self.B_changePassword = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.B_changePassword];

        self.lineTwo = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineTwo];

        self.V_licenceType = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_licenceType];

        self.B_getPremiumBackground = [[UIView alloc] init];

        [PEXGVU setHeight: self.B_getPremiumBackground
                       to:[PEXGuiButtonMain height] + 2 * PEXVal(@"dim_size_medium")];

        _getPremiumViewPosition = [self.linearView addView:self.B_getPremiumBackground];

        self.B_getPremium = [[PEXGuiButtonMain alloc] init];
        [self.B_getPremiumBackground addSubview:self.B_getPremium];


        self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.line];

        self.V_termsOfUse = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_termsOfUse];

        self.V_appVersion = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_appVersion];

        self.B_inviteUsers = [[PEXGuiButtonMain alloc] init];
        [self.linearView addView:self.B_inviteUsers];

        // send logs

        self.V_sendLogs = [[UIView alloc] init];
        [PEXGVU setHeight: self.V_sendLogs to:[PEXGuiButtonMain height] + 2 * PEXVal(@"dim_size_medium")];
        [self.linearView addView:self.V_sendLogs];

        self.B_sendLogs = [[PEXGuiButtonDIalogSecondary alloc] init];
        [self.V_sendLogs addSubview:self.B_sendLogs];
    }];
}

- (void) initContent
{
    [super initContent];

    [self.V_username setName:PEXStrU(@"L_username")];
    [self.V_username setValue:[[PEXAppState instance] getPrivateData].username];

    [self.B_changePassword setName:PEXStrU(@"L_change_password")];
    [self.B_changePassword setValue:PEXStrU(@"L_tap_to_change")];

    [self.B_recoveryEmail setName:PEXStrU(@"L_recovery_mail")];
    [self.B_recoveryEmail setValue:PEXStrU(@"L_tap_to_change")];

    [self.V_licenceType setName:PEXStrU(@"L_licence_type")];

    [self.B_getPremium setTitle:PEXStrU(@"L_manage_licence") forState:UIControlStateNormal];

    [self.V_termsOfUse setName:PEXStrU(@"L_terms_of_use")];
    [self.V_termsOfUse setValue: PEXStr(@"B_go_to_web")];

    [self.V_appVersion setName:PEXStrU(@"L_version")];
    [self.V_appVersion setValue: [PEXAppVersionUtils fullVersionStringToShow]];

    [self.B_inviteUsers setTitle:PEXStrU(@"L_invite_friends") forState:UIControlStateNormal];
    [self.B_sendLogs setTitle:PEXStrU(@"L_send_logs") forState:UIControlStateNormal];

    ///
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[PEXService instance] licenceManager] addListenerAndSet:self];
    });

    // Recovery email load.
    [self loadRecoveryEmailAsync];
}

- (void) permissionsChanged: (NSArray * const) permissions
{
    NSDictionary * consumedSummary = nil;
    NSDictionary * subscriptionsSummary = nil;
    [PEXPermissionsUtils processPermissions:permissions
                             toConsumeables:&consumedSummary
                           toSubscriptionss:&subscriptionsSummary
                                 zeroIfNone:false
                                skipDefault:true];

    // this garbage because of compiler errorneous compilation
    int subsCount = 0;
    if (subscriptionsSummary)
        subsCount = subscriptionsSummary.count;

    int consCount = 0;
    if (consumedSummary)
        consCount = consumedSummary.count;

    NSString * desc = nil;
    if (consCount <= 0){
        desc = [NSString stringWithFormat:@"%d %@",
                                            subsCount, PEXStrP(@"L_subscriptions", subsCount)];
    } else {
        desc = [NSString stringWithFormat:@"%d %@ + %d %@",
                                          subsCount, PEXStrP(@"L_subscriptions", subsCount),
                                          consCount, PEXStrP(@"L_consumeables", consCount)];
    }

    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.V_licenceType setValue:desc];
    });

}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.V_username];
    [PEXGVU scaleHorizontally:self.B_changePassword];
    [PEXGVU scaleHorizontally:self.B_recoveryEmail];

    [PEXGVU scaleHorizontally:self.lineTwo];

    [PEXGVU scaleHorizontally:self.V_licenceType];

    [PEXGVU scaleHorizontally:self.B_getPremiumBackground];
    [PEXGVU scaleHorizontally:self.B_getPremium withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerVertically:self.B_getPremium];

    [PEXGVU scaleHorizontally:self.line];

    [PEXGVU scaleHorizontally:self.V_termsOfUse];
    [PEXGVU scaleHorizontally:self.V_appVersion];
    [PEXGVU scaleHorizontally:self.B_inviteUsers withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.V_sendLogs];
    [PEXGVU scaleHorizontally:self.B_sendLogs withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerVertically:self.B_sendLogs];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.V_username setEnabled:false];
    [self.B_changePassword addAction:self action:@selector(showChangePassword)];
    [self.B_recoveryEmail addAction:self action:@selector(showRecoveryMail)];
    [self.V_licenceType setEnabled:false];
    [self.V_termsOfUse addAction:self action:@selector(showTermsOfUse:)];
    [self.V_appVersion setEnabled:false];

    [self.B_getPremium addTarget:self action:@selector(showGetPremium:) forControlEvents:UIControlEventTouchUpInside];
    [self.B_inviteUsers addTarget:self action:@selector(showInviteUsers:) forControlEvents:UIControlEventTouchUpInside];
    [self.B_sendLogs addTarget:self action:@selector(showSendLogs:) forControlEvents:UIControlEventTouchUpInside];

    [[PEXDbAppContentProvider instance] registerObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)prepareOnScreen:(PEXGuiController *const)parent {
    [super prepareOnScreen:parent];
}

- (IBAction)showTermsOfUse:(id)showTermsOfUse
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_TERMS_CONDITIONS];
    NSURL * const url = [NSURL URLWithString:[PEXTermsOfUseUtils urlToTersmOfUse]];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction) showGetPremium: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_GET_PREMIUM];
    [PEXGuiManageLicenceController showOnParent:self];
}

- (IBAction) showSendLogs: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_SEND_LOGS];
    PEXGuiSendLogsController * const controller = [[PEXGuiSendLogsController alloc] init];
    [controller showInNavigation:self title:PEXStrU(@"L_send_logs")];
}

- (IBAction) showInviteUsers: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_INVITE_USERS];
    self.inviteController = [[PEXGuiInviteFriendsController alloc] init];
    [self.inviteController showInNavigation:self title:PEXStrU(@"L_invite_friends")];
}

- (void)initState
{
    [super initState];
    [[PEXGNFC instance] registerToLicenceUpdateAndSet:self];
    [[PEXGNFC instance] registerToRecoveryMailNotificationsAndSet:self];
}

- (void) showChangePassword {

    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_CHANGE_PASSWORD];
    [[[PEXGuiChangePasswordController alloc] init]
            showInNavigation:self
                       title:PEXStrU(@"L_change_password")];
}

- (void) showRecoveryMail {
    [PEXReport logUsrButton:PEX_EVENT_BTN_PROFILE_RECOVERY_MAIL];
    [[[PEXGuiRecoveryEmailController alloc] init] showInNavigation:self title:PEXStrU(@"L_recovery_mail")];
}

- (void) licenceUpdateNotifications: (const int) count
{
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count) {
            [weakSelf.V_licenceType highlightValue];
        }
        else {
            [weakSelf.V_licenceType dehighlightValue];
        }
    });
}

- (void)recoveryMailNotificationCountChanged:(const int)count
{
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count) {
            [weakSelf.B_recoveryEmail highlightValue];
        }
        else {
            [weakSelf.B_recoveryEmail dehighlightValue];
        }
    });
}

- (void) loadRecoveryEmailAsync {
    WEAKSELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf loadRecoveryEmail];
    });
}

- (void) loadRecoveryEmail {
    PEXUserPrivate * privData = [[PEXService instance] privData];
    if (privData == nil || privData.accountId == nil){
        return;
    }

    PEXDbUserProfile * profile = [PEXDbUserProfile getProfileFromDbId:[PEXDbAppContentProvider instance]
                                                                   id:privData.accountId
                                                           projection:nil];

    if (profile == nil){
        return;
    }

    // Update fields
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        if (![PEXUtils isEmpty: profile.recovery_email]) {
//            [weakSelf.B_recoveryEmail setValue:profile.recovery_email fontColor:PEXCol(@"black_normal")];
            [weakSelf.B_recoveryEmail setValue:profile.recovery_email];
        } else {
//            [weakSelf.B_recoveryEmail setValue:PEXStr(@"L_recovery_mail_not_set") fontColor:PEXCol(@"red_normal")];
            [weakSelf.B_recoveryEmail setValue:PEXStr(@"L_recovery_mail_not_set")];
        }
    }];
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    if (![[PEXDbUserProfile getURI] matchesBase:uri]) {
        return;
    }

    // Stuff got changed, refresh view.
    [self loadRecoveryEmailAsync];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [[[PEXService instance] licenceManager] removeListener:self];
    [[PEXGNFC instance] unregisterForLicenceUpdate:self];
    [[PEXGNFC instance] unregisterForRecoveryMailNotifications:self];
    [[PEXDbAppContentProvider instance] unregisterObserver:self];

    [super dismissViewControllerAnimated:flag completion:completion];
}

@end
