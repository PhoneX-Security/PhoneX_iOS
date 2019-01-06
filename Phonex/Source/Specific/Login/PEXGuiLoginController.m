//
//  PEXViewController.m
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PEXGuiLoginController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiTextField.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiImageView.h"
#import "PEXLoginExecutor.h"
#import "PEXCredentials.h"
#import "PEXGuiPhonexCheckBox.h"


#import "PEXDbAppContentProvider.h"
#import "PEXService.h"
#import "PEXGuiPinLockManager.h"

#import "PEXGuiFactory.h"
#import "PEXOpenUDID.h"

#import "PEXGuiImageView.h"

#import "PEXGuiFileUtils.h"
#import "PEXGuiSpecialPriorityManager.h"

#import "PEXGuiNoticeManager.h"
#import "PEXAppVersionUtils.h"
#import "PEXMessageArchiver.h"
#import "PEXGuiButtonDIalogSecondary.h"
#import "PEXGuiCreateAccountController.h"
#import "PEXGuiUtils.h"
#import "PEXGuiTextController.h"
#import "PEXGuiDialogCloser.h"
#import "PEXStringUtils.h"
#import "PEXLoginHelper.h"
#import "PEXAutoLoginManager.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXGuiShieldView.h"
#import "PEXGuiFullSizeBusyView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXTermsOfUseUtils.h"
#import "PEXReport.h"
#import "PEXGuiForgottenPasswordController.h"
#import "PEXLoginNameValidator.h"
#import "UIView+AJWValidator.h"
#import "AJWValidator.h"

@interface PEXGuiLoginController ()
{
@private bool _onFailedAutologin;
}

@property (nonatomic) PEXGuiTextField * TF_username;
@property (nonatomic) UITextField * TF_password;
@property (nonatomic) UIButton * B_login;
@property (nonatomic) UIButton *B_createAccount;
@property (nonatomic) UILabel * L_appName;
@property (nonatomic) PEXGuiImageView * I_appLogo;

@property (nonatomic) UILabel * L_rememberUsername;
@property (nonatomic) PEXGuiClickableView * B_rememberUsernameWrapper;
@property (nonatomic) PEXGuiPhonexCheckBox * CB_rememberUsername;

@property (nonatomic) UIView * B_details;
@property (nonatomic) PEXGuiClickableView * B_detailsClickWrapper;

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSString * rememberedUsername;

@property (nonatomic) PEXGuiShieldView * V_postAutoLoginShield;

@property (nonatomic) PEXGuiFullSizeBusyView * V_busier;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_licenceAgreement;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_forgotPassword;

@property (nonatomic) PEXGuiForgottenPasswordController * C_forgottenPasswd;
@property (nonatomic) const PEXCredentials *const passwordChangeCredentials;

@property (nonatomic) AJWValidator * validatorLogin;

@end

@implementation PEXGuiLoginController

+ (PEXGuiLoginController *) instance
{
    static PEXGuiLoginController * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiLoginController alloc] init];
    });

    return instance;
}

- (void) showBusier
{
    if (self.V_busier)
        return;

    self.V_busier = [[PEXGuiFullSizeBusyView alloc] init];

    [self.view addSubview:self.V_busier];
    [PEXGVU scaleFull:self.V_busier];

    [self.view bringSubviewToFront:self.V_busier];
}

- (void) hideBusier
{
    if (!self.V_busier)
        return;

    [self.V_busier removeFromSuperview];
    self.V_busier = nil;
}

- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];
    self.rememberedUsername = @"";

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"Login";

    self.TF_username = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_username];
    self.TF_password = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_password];

    self.B_login = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_login];

    self.B_createAccount = [[PEXGuiButtonDIalogSecondary alloc] init];
    [self.mainView addSubview:self.B_createAccount];

    /*
    self.L_appName = [[PEXGuiClassicLabel alloc]
                          initWithFontSize:PEXVal(@"dim_size_medium")
                          fontColor:PEXCol(@"light_gray_normal")];

    [self.mainView addSubview:self.L_appName];
     */

    self.I_appLogo = [[PEXGuiImageView alloc] init];
    [self.mainView addSubview: self.I_appLogo];

    self.CB_rememberUsername = [[PEXGuiPhonexCheckBox alloc] init];
    [self.mainView addSubview:self.CB_rememberUsername];

    self.B_rememberUsernameWrapper = [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview:self.B_rememberUsernameWrapper];

    self.L_rememberUsername = [[PEXGuiClassicLabel alloc]
                        initWithFontSize:PEXVal(@"dim_size_small_medium")
                        fontColor:PEXCol(@"black_normal")];
    [self.mainView addSubview:self.L_rememberUsername];

    self.B_detailsClickWrapper = [[PEXGuiClickableView alloc] init];
    //[self.mainView addSubview:self.B_detailsClickWrapper];
    self.B_details = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"settings")];;
    [self.B_detailsClickWrapper addSubview:self.B_details];

    self.TV_licenceAgreement = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_licenceAgreement];

    self.TV_forgotPassword = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_forgotPassword];

    if (self.V_postAutoLoginShield)
    {
        [self.view addSubview:self.V_postAutoLoginShield];
    }
}

- (void) setPostLaunchShield
{
    if (!self.V_postAutoLoginShield)
    {
        self.V_postAutoLoginShield = [[PEXGuiShieldView alloc] init];
    }
}

- (void) removePostLaunchShield
{
    if (self.V_postAutoLoginShield)
    {
        if (self.V_postAutoLoginShield.superview)
        {
            [self.V_postAutoLoginShield removeFromSuperview];
        }

        self.V_postAutoLoginShield = nil;
    }
}

- (void) setDefaultUsernamePlaceholder
{
    self.TF_username.placeholder = PEXStr(@"L_username");
    self.TF_username.specialOneTimeColor = nil;
}

- (void) setSpecialusername
{
    if (self.preserveCredentials)
        return;

    self.TF_username.text = @"";

    if (![PEXStringUtils isEmpty:self.rememberedUsername])
    {
        self.TF_username.specialOneTimeColor = PEXCol(@"orange_normal");
        self.TF_username.placeholder = PEXStr(@"L_remembered_username");
    }
}

- (void) initContent
{
    [super initContent];

    [self setDefaultUsernamePlaceholder];
    self.TF_password.placeholder = PEXStr(@"L_password");
    [self.B_login setTitle:(PEXStrU(@"B_login")) forState:UIControlStateNormal];
    [self.B_createAccount setTitle:(PEXStrU(@"B_new_account")) forState:UIControlStateNormal];

    NSMutableString * const appDescription = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@ %@",
                    PEXStr(@"L_version"),
                    [PEXAppVersionUtils fullVersionStringToShow]]];
    /*
#ifdef PEX_BUILD_DEBUG
    [appDescription appendString:@" {DEBUG}"];
#endif
     */

    //[self.L_appName setText: appDescription];

    //[self.I_appLogo setImage:PEXImg(@"logo_large")];
    [self.I_appLogo setImage:PEXImg(@"logo_full")];


    const bool set = [[PEXAppPreferences instance] getBoolPrefForKey: PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY
                                                        defaultValue: PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT];
    if (set)
    {
        NSString * const username = [[PEXAppPreferences instance]
                getStringPrefForKey:PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY defaultValue:nil];

        if (username)
        {
            self.rememberedUsername = username;
            [self setSpecialusername];
        }
    }

    [self checkSet:set];

    self.L_rememberUsername.text = PEXStr(@"L_remember_login_username");

    [self setTermsOfUse];
    [self.TV_forgotPassword setText:PEXStr(@"L_forgot_password")];
}

- (void) setTermsOfUse
{
    NSMutableString * licenceAgreementSimple = [[NSMutableString alloc] initWithString:PEXStr(@"txt_terms_of_use")];

    NSRange linkStart = [licenceAgreementSimple rangeOfString:@"<strong>"];
    NSRange linkEnd = [licenceAgreementSimple rangeOfString:@"</strong>"];
    [licenceAgreementSimple deleteCharactersInRange:linkEnd];
    [licenceAgreementSimple deleteCharactersInRange:linkStart];

    const NSUInteger start = linkStart.location;
    const NSUInteger endOf = linkEnd.location - linkStart.length;

    // licence agreement
    NSMutableAttributedString * licenceAgreement =
            [[NSMutableAttributedString alloc] initWithString:licenceAgreementSimple];

    // THIS URL IS IGNORED ... look for IPH-350 comment
    [licenceAgreement addAttribute: NSLinkAttributeName
                             value: [PEXTermsOfUseUtils urlToTersmOfUse]
                             range: NSMakeRange(start, endOf - start)];

    self.TV_licenceAgreement.attributedText = licenceAgreement;

    self.TV_licenceAgreement.textColor = PEXCol(@"black_normal");
    self.TV_licenceAgreement.tintColor = PEXCol(@"orange_low");
}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;
    [self.TF_username setDelegate:self];
    [self.TF_password setDelegate:self];

    self.TF_username.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.TF_username.keyboardType = UIKeyboardTypeEmailAddress;
    self.TF_password.secureTextEntry = YES;

    [self.B_login addTarget:self action:@selector(login:)
       forControlEvents:UIControlEventTouchUpInside];

    [self.B_createAccount addTarget:self action:@selector(callCreateAccount:)
           forControlEvents:UIControlEventTouchUpInside];

    self.CB_rememberUsername.checkBlock = ^(const bool isChecked) {
        [weakSelf checkSet:isChecked];
    };

    [self.B_rememberUsernameWrapper addAction:self action:@selector(rememberClicked:)];
    [self.B_detailsClickWrapper addAction:self action:@selector(detailsClicked:)];

    self.TV_licenceAgreement.delegate = self;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleForgotPasswordTap)];
    [singleTap setNumberOfTapsRequired:1];
    [self.TV_forgotPassword addGestureRecognizer:singleTap];

    self.validatorLogin = [PEXLoginNameValidator initValidatorWithDomain:YES];
    [self.TF_username ajw_attachValidator:self.validatorLogin];
    _validatorLogin.validatorStateChangedHandler = ^(AJWValidatorState newState) {
        switch (newState) {
            case AJWValidatorValidationStateValid: {
                [weakSelf handleValidLogin];
                break;
            }
            case AJWValidatorValidationStateInvalid: {
                [weakSelf handleInvalidLogin];
                break;
            }
            default:
                break;
        }
    };
}

- (IBAction) rememberClicked: (id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_REMEMBER_USERNAME];
    [self checkSet:!self.CB_rememberUsername.isChecked];
}

- (void) checkSet: (const bool) isChecked
{
    [[PEXAppPreferences instance] setBoolPrefForKey:PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY
                                              value:isChecked];

    [self.CB_rememberUsername setChecked:isChecked];
}

- (void) cleanTracesForce
{
    self.TF_password.text = @"";
    self.passwordChangeCredentials = nil;

    const bool set = [[PEXAppPreferences instance] getBoolPrefForKey: PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY
                                                        defaultValue: PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT];

    [self.CB_rememberUsername setChecked:set];

    if (!set)
    {
        [[PEXAppPreferences instance] setStringPrefForKey:PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY value:@""];
        self.TF_username.text = @"";
        self.rememberedUsername = @"";
        [self setDefaultUsernamePlaceholder];
    }
    else
    {
        if (!self.TF_username.specialOneTimeColor)
            self.rememberedUsername = self.TF_username.text;

        [self setSpecialusername];
    }
}

- (void) cleanTraces
{
    self.passwordChangeCredentials = nil;
    if (self.preserveCredentials)
        return;

    [self cleanTracesForce];
}

- (void) initLayout
{
    [super initLayout];

    /*
    [PEXGVU centerHorizontally:self.self.L_appName];
    [PEXGVU moveToBottom:self.self.L_appName withMargin:PEXVal(@"dim_size_tiny_small")];
     */

    ////////////

    [PEXGVU scaleHorizontally:self.TF_username withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToTop:self.TF_username withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.TF_password withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_password below:self.self.TF_username withMargin:PEXVal(@"dim_size_small")];

    /*remember*/
    [PEXGVU setSize:self.CB_rememberUsername x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.CB_rememberUsername below:self.TF_password withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU moveToLeft:self.CB_rememberUsername withMargin:PEXVal(@"dim_size_large")];

    /*remember*/

    [PEXGVU scaleHorizontally:self.B_login withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_login below:self.CB_rememberUsername withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU centerVertically:self.L_rememberUsername on:self.CB_rememberUsername];

    [PEXGVU move:self.L_rememberUsername rightOf:self.CB_rememberUsername withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.B_createAccount withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_createAccount below:self.B_login withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.TV_forgotPassword];
    [self.TV_forgotPassword sizeToFit];
    [PEXGVU move:self.TV_forgotPassword below:self.B_createAccount];

    //////////////////
    [PEXGVU centerHorizontally:self.I_appLogo];

    [PEXGVU scaleHorizontally:self.TV_licenceAgreement];
    [self.TV_licenceAgreement sizeToFit];
    [PEXGVU center:self.TV_licenceAgreement];
    [PEXGVU moveToBottom:self.TV_licenceAgreement withMargin:PEXVal(@"dim_size_tiny_small")];
    [PEXGVU move:self.I_appLogo above:self.TV_licenceAgreement];

    // because of the launch image
    //[PEXGVU move:self.I_appLogo above:self.L_appName withMargin:PEXVal(@"dim_size_small")];
    // margin of the version string from gottom + version string size + margin btw version str and logo
//    [PEXGVU moveToBottom:self.I_appLogo
//              withMargin:PEXVal(@"dim_size_tiny_small") /*+ PEXVal(@"dim_size_medium") + PEXVal(@"dim_size_small")*/];


    // remember user check box wrapper
    const CGFloat upperY = self.TF_password.frame.origin.y + self.TF_password.frame.size.height;
    const CGFloat leftX = self.CB_rememberUsername.frame.origin.x;

    self.B_rememberUsernameWrapper.frame = CGRectMake(0.0f /*leftX*/,
                                                      upperY,

                                                      self.L_rememberUsername.frame.origin.x +
                                                      self.L_rememberUsername.frame.size.width /*- leftX*/,

                                                      self.B_login.frame.origin.y - upperY
                                                      );
    [self.view bringSubviewToFront:self.B_rememberUsernameWrapper];

    // details
    const CGFloat length = (2.0f * PEXVal(@"dim_size_large")) + self.B_details.frame.size.width;

    [PEXGVU setSize:self.B_detailsClickWrapper x:length y:3.0f * PEXVal(@"dim_size_medium") /*see labelController*/];

    [PEXGVU moveToRight:self.B_detailsClickWrapper];
    [PEXGVU moveToTop:self.B_detailsClickWrapper];

    [PEXGVU center:self.B_details];

    if (self.V_postAutoLoginShield) {
        [PEXGVU makeFullscreenBackground:self.V_postAutoLoginShield];
        [self.view bringSubviewToFront:self.V_postAutoLoginShield];
    }
}

- (void) initState
{
    [super initState];

    [self.TF_username addTarget:self
                         action:@selector(usernameTextChanged:)
               forControlEvents:UIControlEventEditingChanged];

    // Auto-login on app start.
//    PEXAutoLoginManager * autoLoginManager = [PEXAutoLoginManager instance];
//    PEXCredentials * creds = [PEXLoginHelper loadCredentialsFromKeyChain];
//    if (creds)
//    {
//        DDLogVerbose(@"Credentials loaded from keystore: %@", creds.username);
//        [self startLoggingIn:creds];
//    }
}

- (IBAction) usernameTextChanged: (UITextView *) sender
{
    if (sender.text.length > 0) {
        sender.text = [PEXLoginNameValidator sanitize:sender.text allowDomain:YES];
        [self.validatorLogin validate:sender.text];
    }

    [self usernameTextChanged];
}

- (void) usernameTextChanged
{
    self.rememberedUsername = self.TF_username.text;

    if (self.TF_username.specialOneTimeColor)
    {
        [self setDefaultUsernamePlaceholder];
    }
}

- (IBAction) callCreateAccount:(id)sender
{
    // PEX_LOGIN_TASK_RESULT_TLS_CACHE_BUG
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGIN_CREATE_ACCOUNT];
    PEXService * svc = [PEXService instance];
    if (svc.lastLoginUserName)
    {
        [PEXGuiFactory showErrorTextBox:self withText:[NSString stringWithFormat:@"%@\n\n%@",
        PEXStr(@"msg_login_tls_bug_new_account"), PEXStr(@"txt_restart_app_detail_description")]];
        return;
    }

    PEXGuiCreateAccountController * const c = [[PEXGuiCreateAccountController alloc] init];
    c.listener = self;
    [c showInNavigation:self title:PEXStrU(@"B_new_account")];
}

- (IBAction) login:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGIN];
    [self.view endEditing:YES];

    if (!self.TF_username.specialOneTimeColor)
        [PEXGuiUtils sanitizeTextFieldInputLowerCase:self.TF_username];

    self.rememberedUsername = [PEXStringUtils trimWhiteSpaces:self.rememberedUsername].lowercaseString;
    [self.validatorLogin validate:self.rememberedUsername];
    if ([self.validatorLogin state] != AJWValidatorValidationStateValid) {
        [PEXGuiFactory showErrorTextBox:self withText:PEXStr(@"txt_login_name_not_valid")];
        return;
    }

    PEXCredentials * const credentials = [[PEXCredentials alloc] init];
    credentials.username = self.rememberedUsername;
    credentials.password = self.TF_password.text;

    [self startLoggingIn:credentials];
}

- (void) startLoggingIn: (const PEXCredentials * const) credentials
{
    self.passwordChangeCredentials = nil;
    [[PEXAppPreferences instance] setStringPrefForKey:PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY value:credentials.username];

    const PEXLoginExecutor * const loginEx =
            [[PEXLoginExecutor alloc] initWithCredentials:credentials parentController:self];

    [loginEx show];
}

// Controller OVERRIDE KEYBOARD EVENTS
-(CGFloat) getTopKeyboardPoint
{
    const CGPoint point = [PEXGVU getAbsolutePosition:self.B_login highestView:nil];
    return point.y + self.B_login.frame.size.height;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self cleanTraces];

    [super viewDidDisappear:animated];
}

// TODO always look for data that need to be reset on logout
// the main controller must be provided (this)
- (void) performLogout
{
    [self performLogoutWithAftermath:nil];
}

- (void) performLogoutWithMessage: (NSString * const) message
{
    if (message)
        [self performLogoutWithMessageInternal: message];
    else
        [self performLogoutWithAftermath:nil];
}

- (void) performLogoutWithMessageInternal: (NSString * const) message
{
    [self performLogoutWithAftermath:^{

        [PEXGuiFactory showWarningTextBox:self
                                 withText:message];


    }];
}

- (void)performLogoutWithAftermath: (void (^)(void)) afterLogoutBlock
{
    [self performLogoutWithAftermath:afterLogoutBlock willLoginImmediatelly:false];
}

- (void)performLogoutWithAftermath: (void (^)(void)) afterLogoutBlock
             willLoginImmediatelly: (const bool) willLoginImmediatelly
{
    [self.lock lock];

    self.passwordChangeCredentials = nil;
    self.preserveCredentials = false;

    [[PEXGuiLoginController instance] removePostLaunchShield];

    if ([[PEXAppState instance] logged])
    {
        [[PEXMessageArchiver instance] stop];

        [[PEXService instance] onLogout: !willLoginImmediatelly];

        // internally the app is now logegd out
        PEXAppState * const appState = [PEXAppState instance];
        [appState setLogged: false];

        // - call controller from manager is unset always
        // 0. unregister for db updates
        [[PEXDbAppContentProvider instance] unregisterAll];
        // 1. notifications
        [[PEXGNFC instance] unload];
        // 2. application notifier
        [[PEXANFC instance] unregister];

        [appState clearManagers];

        // 5. remove all executors
        [PEXUnmanagedObjectHolder clearAll];

        // 6. reset state of all special controller manager
        [PEXGuiSpecialPriorityManager dismissAll];

        [self.landingController dismissViewControllerAnimated:false completion:^{
            self.landingController = nil;
            [[PEXGuiPinLockManager instance] setBeyondPinLock: true];

            [[PEXGuiNoticeManager instance] reshowNoticeIfNeeded];

            if (afterLogoutBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    afterLogoutBlock();
                });
            }
        }];
    }

    [self.lock unlock];
}

- (void)newAccountCreated:(const PEXNewAccountInfo *const)info
{
    PEXGuiDetailsTextBuilder * const builder = [[PEXGuiDetailsTextBuilder alloc] init];

    [builder appendFirstValue:PEXStr(@"msg_account_successfully_created")];

    [builder appendLabel:PEXStr(@"L_username")];
    [builder appendValue:info.username];

    [builder appendLabel:PEXStr(@"L_password")];
    [builder appendValue:info.tempPassword];

    // Because of in-app
    //[builder appendLabel:PEXStr(@"L_expiration_date")];
    //[builder appendValue:[PEXDateUtils dateToFullDateString:info.expirationDate]];

    [builder appendValue:@"\n"];
    [builder appendValue:PEXStr(@"msg_you_will_be_prompted_to_change_password")];

    PEXGuiTextController * const txtController = [[PEXGuiTextController alloc]
            initWithAttributedText:builder.result];

    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithDialogSubcontroller:txtController
                                                                                        listener:nil];

    visitor.primaryButtonTitle = PEXStrU(@"B_login");

    PEXGuiController * const result =
            [[[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor] showInWindow:self];

    visitor.finishPrimaryBlock = ^{[result dismissViewControllerAnimated:true completion:^{

        self.TF_username.text = info.username;
        [self usernameTextChanged];
        self.TF_password.text = @"";

        PEXCredentials * const credentials = [[PEXCredentials alloc] init];
        credentials.username = info.username;
        credentials.password = info.tempPassword;

        [self startLoggingIn:credentials];
    }];};
}

- (void) autologinFailedStateOn: (const PEXCredentials * const) credentials
{
    if (!_onFailedAutologin)
    {
        _onFailedAutologin = true;
        [[PEXAppState instance] resetPinLockAttempts];
        PEXUserPrivate *tempPrivate = [[PEXUserPrivate alloc] init];
        tempPrivate.username = credentials.username;
        tempPrivate.pass = credentials.password;
        [[PEXAppState instance] setPrivData:tempPrivate];

        [[PEXGuiPinLockManager instance] setWorksOutOfLogin:true];
        self.preserveCredentials = true;
    }
}

- (void) autologinFailedStateOff
{
    if (_onFailedAutologin)
    {
        _onFailedAutologin = false;
        [[PEXAppState instance] setPrivData:nil];
        [[PEXGuiPinLockManager instance] setWorksOutOfLogin:false];
        self.preserveCredentials = false;
    }
}

- (void) autoLoginFailedWithCredentials: (const PEXCredentials * const) credentials
{
    NSString * const pin =
            // [[PEXUserAppPreferences instance] getStringPrefForKey: PEX_PREF_PIN_LOCK_PIN_KEY
            [[PEXAppPreferences instance] getStringPrefForKey:
                    [PEXUserAppPreferences userKeyFor:PEX_PREF_PIN_LOCK_PIN_KEY
                                                 user:credentials.username]
                                                     defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT];

    UIViewController * parentForDialog = self;

    if (pin)
    {
        [self autologinFailedStateOn:credentials];

        UIViewController * const pinController =
        [[PEXGuiPinLockManager instance] showPinLockOnBecomingActive:0
                                                          forLanding:self
                                                           forceShow:true];

        if (pinController)
        {
            parentForDialog = pinController;
        }
        else
        {
            [self autologinFailedStateOff];
        }
    }

    [PEXGuiFactory showErrorTextBox:parentForDialog
                           withText:PEXStr(@"txt_autologin_failed_please_click_login")];

    self.rememberedUsername = credentials.username;
    self.TF_username.text = credentials.username;
    self.TF_password.text = credentials.password;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    // check for long press event
    BOOL isLongPress = YES;
    for (UIGestureRecognizer *recognizer in self.TV_licenceAgreement.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]){
            if (recognizer.state == UIGestureRecognizerStateFailed) {
                isLongPress = NO;
            }
        }
    }


    bool result = false;

    // IGNORE long press because of IPH-350

    if (!isLongPress)
    {
        NSURL * const url = [NSURL URLWithString:[PEXTermsOfUseUtils urlToTersmOfUse]];
        [[UIApplication sharedApplication] openURL:url];
        result = true;
    }

    return result;

}

- (void)viewDidReveal {
    [super viewDidReveal];
    self.C_forgottenPasswd = nil;
    if (self.passwordChangeCredentials != nil){
        [self startLoggingIn:self.passwordChangeCredentials];
    }
}

-(void)handleForgotPasswordTap{
    DDLogVerbose(@"Forgot password tap");
    self.C_forgottenPasswd = [[PEXGuiForgottenPasswordController alloc] init];
    self.C_forgottenPasswd.loginController = self;
    [self.C_forgottenPasswd showInNavigation:self title:PEXStrU(@"B_forgotten_password")];
}

- (void)recoveryCodePassed:(NSString *)code {
    if (self.landingController != nil){
        [NSException raise:PEXRuntimeException format:@"Should not get here, recovery code cannot be applied when logged in"];
    }

    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        if (weakSelf.C_forgottenPasswd == nil){
            weakSelf.C_forgottenPasswd = [[PEXGuiForgottenPasswordController alloc] init];
            weakSelf.C_forgottenPasswd.loginController = weakSelf;
            weakSelf.C_forgottenPasswd.preFilledRecoveryCode = code;
            [weakSelf.C_forgottenPasswd showInNavigation:weakSelf title:PEXStrU(@"B_forgotten_password")];
            return;
        }

        [weakSelf.C_forgottenPasswd fillInCode: code];
    }];
}

- (void)storeCredentialsAfterPasswordChange:(const PEXCredentials *const)credentials {
    self.passwordChangeCredentials = credentials;
}

- (void)handleValidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_username.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
}

- (void)handleInvalidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_username.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];
}

@end
