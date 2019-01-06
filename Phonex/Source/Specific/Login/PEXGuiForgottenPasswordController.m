//
// Created by Dusan Klinec on 12.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiForgottenPasswordController.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiErrorTextView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiLoginController.h"
#import "PEXDBUserProfile.h"
#import "PEXGuiPasswordVerificationController.h"
#import "PEXGuiRecoveryEmailExecutor.h"
#import "PEXAccountSettingsTask.h"
#import "PEXService.h"
#import "PEXDbAppContentProvider.h"
#import "PEXSOAPResult.h"
#import "PEXGuiFactory.h"
#import "PEXUtils.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "UITextView+PEXPaddings.h"
#import "AJWValidator+Private.h"
#import "AJWValidatorRegularExpressionRule.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiPoint.h"
#import "PEXSendRecoveryCodeTask.h"
#import "PEXApplyRecoveryCodeTask.h"
#import "PEXCredentials.h"
#import "PEXLoginNameValidator.h"
#import "PEXRecoveryCodeValidator.h"

@interface PEXGuiForgottenPasswordController () <AJWValidatorDelegate>
@property (nonatomic) PEXGuiClickableScrollView * V_scroller;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_prologue;
@property (nonatomic) PEXGuiTextField * TF_loginName;
@property (nonatomic) UIButton * B_sendCode;

@property (nonatomic) PEXGuiPoint * lineFirst;
@property (nonatomic) UITextField *TF_recoveryCode;
@property (nonatomic) UIButton * B_applyCode;

@property (nonatomic) PEXGuiErrorTextView * TV_errorText;
@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

@property (atomic) BOOL isBusy;
@property (nonatomic) NSString * rememberedUsername;
@property (nonatomic) NSString * errorMessage;
@property (nonatomic) AJWValidator * validator;
@property (nonatomic) AJWValidator * validatorLogin;

@property (nonatomic) PEXSendRecoveryCodeTask * sendCodeTask;
@property (nonatomic) PEXApplyRecoveryCodeTask * applyCodeTask;

@end

@implementation PEXGuiForgottenPasswordController {

}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ForgottenPassword";

    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];
    UIView * mainContainer = self.V_scroller;

    self.TV_prologue = [[PEXGuiReadOnlyTextView alloc] init];
    [mainContainer addSubview:self.TV_prologue];

    self.TF_loginName = [[PEXGuiTextField alloc] init];
    [mainContainer addSubview:self.TF_loginName];

    self.B_sendCode = [[PEXGuiButtonMain alloc] init];
    [mainContainer addSubview:self.B_sendCode];

    self.lineFirst = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [mainContainer addSubview:self.lineFirst];

    self.TF_recoveryCode = [[PEXGuiTextField alloc] init];
    [mainContainer addSubview:self.TF_recoveryCode];

    self.B_applyCode = [[PEXGuiButtonMain alloc] init];
    [mainContainer addSubview:self.B_applyCode];

    self.TV_errorText = [[PEXGuiErrorTextView alloc] init];
    [mainContainer addSubview:self.TV_errorText];

    self.activityIndicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [mainContainer addSubview:self.activityIndicatorView];
}

- (void)initContent
{
    [super initContent];
    [self setDefaultUsernamePlaceholder];

    self.TV_prologue.text = PEXStr(@"txt_forgotten_password_intro");
    self.TF_loginName.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.TF_recoveryCode.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.TF_recoveryCode.placeholder = PEXStr(@"L_recovery_code");
    [self.B_sendCode setTitle:PEXStrU(@"B_sendCode") forState:UIControlStateNormal];
    [self.B_applyCode setTitle:PEXStrU(@"B_applyCode") forState:UIControlStateNormal];

    NSString * const username = [[PEXAppPreferences instance] getStringPrefForKey:PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY defaultValue:nil];
    if (username) {
        self.rememberedUsername = username;
        [self setSpecialusername];
    }

    if (![PEXUtils isEmpty:self.preFilledRecoveryCode]){
        self.TF_recoveryCode.text = [self formatRecoveryCode:self.preFilledRecoveryCode];
    }
}

- (void)initBehavior
{
    [self.B_sendCode addTarget:self action:@selector(sendRecoveryCodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.B_applyCode addTarget:self action:@selector(applyRecoveryCodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.TV_prologue setScrollEnabled:false];
    [self.TV_errorText setScrollEnabled:false];

    self.validator = [PEXRecoveryCodeValidator initValidator];
    self.validatorLogin = [PEXLoginNameValidator initValidatorWithDomain:YES];

    [self.TF_recoveryCode ajw_attachValidator:self.validator];
    [self.TF_recoveryCode addTarget:self action:@selector(codeChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.TF_recoveryCode setDelegate:self];

    [self.TF_loginName ajw_attachValidator:self.validatorLogin];
    [self.TF_loginName addTarget:self action:@selector(loginChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.TF_loginName setDelegate:self];

    WEAKSELF;
    _validator.delegate = self;
    _validator.validatorStateChangedHandler = ^(AJWValidatorState newState) {
        switch (newState) {
            case AJWValidatorValidationStateValid: {
                [weakSelf handleValid];
                break;
            }
            case AJWValidatorValidationStateInvalid: {
                [weakSelf handleInvalid];
                break;
            }
            case AJWValidatorValidationStateWaitingForRemote: {
                [weakSelf handleWaiting];
                break;
            }
        }
    };

    _validatorLogin.delegate = self;
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
            case AJWValidatorValidationStateWaitingForRemote: {
                [weakSelf handleWaitingLogin];
                break;
            }
        }
    };

    // Validate if already pre-filled.
    if (![PEXUtils isEmpty:self.TF_recoveryCode.text]){
        [_validator validate:self.TF_recoveryCode.text];
    }

    [super initBehavior];
}

- (void)initLayout
{
    [super initLayout];

    [self layoutAll];
}

- (void)initState
{
    [super initState];
    self.isBusy = NO;
}

- (void)codeChanged:(UITextField *)sender
{
    if (sender.text.length > 0) {
        [self.validator validate:sender.text];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField != self.TF_recoveryCode){
        return YES;
    }

    BOOL result = [PEXRecoveryCodeValidator textField:textField shouldChangeCharactersInRange:range replacementString:string];
    [self.validator validate:textField.text];
    return result;
}

- (IBAction) loginChanged: (UITextField *) sender
{
    if (sender.text.length > 0) {
        sender.text = [PEXLoginNameValidator removeInvalidCharactersFromLogin:sender.text allowDomain:YES];
        [self.validatorLogin validate:sender.text];
    }

    [self usernameTextChanged];
}

- (void) usernameTextChanged
{
    self.rememberedUsername = self.TF_loginName.text;

    if (self.TF_loginName.specialOneTimeColor)
    {
        [self setDefaultUsernamePlaceholder];
    }
}

- (void) setDefaultUsernamePlaceholder
{
    self.TF_loginName.placeholder = PEXStr(@"L_username");
    self.TF_loginName.specialOneTimeColor = nil;
}

- (void) setSpecialusername
{
    self.TF_loginName.text = @"";
    if (![PEXStringUtils isEmpty:self.rememberedUsername])
    {
        self.TF_loginName.specialOneTimeColor = PEXCol(@"orange_normal");
        self.TF_loginName.placeholder = PEXStr(@"L_remembered_username");
    }
}

- (void)layoutAll
{
    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU scaleHorizontally:self.TV_prologue withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU scaleHorizontally:self.TF_loginName withMargin:margin];
    [PEXGVU scaleHorizontally:self.TF_recoveryCode withMargin:margin];
    [PEXGVU scaleHorizontally:self.B_sendCode withMargin:margin];
    [PEXGVU scaleHorizontally:self.B_applyCode withMargin:margin];
    [PEXGVU scaleHorizontally:self.lineFirst];

    [self.TV_prologue setPaddingNumTop:nil left:@(0.0) bottom:nil rigth:@(0.0)];
    [self.TV_prologue sizeToFit];
    [PEXGVU moveToTop:self.TV_prologue];

    UIView * viewTop = self.TV_prologue;
    UIView * bottom = self.B_applyCode;

    [PEXGVU move:self.TF_loginName below:viewTop];
    [PEXGVU move:self.B_sendCode below:self.TF_loginName withMargin:margin];

    [PEXGVU move:self.lineFirst below:self.B_sendCode withMargin:margin];

    [PEXGVU move:self.TF_recoveryCode below:self.lineFirst withMargin:margin];
    [PEXGVU move:self.B_applyCode below:self.TF_recoveryCode withMargin:margin];
    bottom = self.B_applyCode;

    // Error message.
    if (![PEXUtils isEmpty:self.errorMessage]){
        [PEXGVU scaleHorizontally:self.TV_errorText  withMargin:PEXVal(@"dim_size_medium")];
        self.TV_errorText.text = self.errorMessage;
        [self.TV_errorText setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_errorText sizeToFit];

        [PEXGVU move:self.TV_errorText below:bottom withMargin:margin];
        [PEXGVU shakeView:self.mainView];

        bottom = self.TV_errorText;

    } else {
        self.TV_errorText.text = nil;
        [self.TV_errorText sizeToFit];
    }

    // Busy?
    self.activityIndicatorView.hidden = self.isBusy;
    if (self.isBusy){
        [PEXGVU move:self.activityIndicatorView below:bottom withMargin:margin];
        [PEXGVU centerHorizontally:self.activityIndicatorView];
        bottom = self.activityIndicatorView;
        [self.activityIndicatorView startAnimating];

    } else {
        [self.activityIndicatorView stopAnimating];
    }

    self.V_scroller.contentSize =
            CGSizeMake(self.mainView.frame.size.width, [PEXGVU getLowerPoint:bottom] + margin);
}

- (NSString *) formatRecoveryCode: (NSString *) code {
    return [PEXRecoveryCodeValidator formatCode:code];
}

- (IBAction) sendRecoveryCodeClicked: (id) sender {
    // Regex testing.
    [self.validatorLogin validate:self.rememberedUsername];
    if ([self.validatorLogin state] != AJWValidatorValidationStateValid) {
        [self setErrorText:PEXStr(@"txt_login_name_not_valid")];
        return;
    }

    [self setErrorText:nil];

    // Send recovery code.
    [self setErrorText:nil];
    self.sendCodeTask = [[PEXSendRecoveryCodeTask alloc] init];
    self.sendCodeTask.dstUser = self.rememberedUsername;
    self.sendCodeTask.dstUserResource = [PEXUtils generateResource:self.rememberedUsername];

    [self.B_sendCode setEnabled:NO];
    [self.TF_loginName setEnabled:NO];
    [self setBusy:YES];

    WEAKSELF;
    PEXRecoveryCodeSendFailed failureBlock = ^{
        [weakSelf sendCodeFailed];
    };

    PEXRecoveryCodeSendFinished successBlock = ^(NSNumber * status, NSString * statusText, NSNumber * validTo) {
        [weakSelf sendCodeSuccess:status statusText:statusText validTo:validTo];
    };

    const bool success = [self.sendCodeTask sendRecoveryCode:successBlock errorHandler:failureBlock];
    if (!success) {
        [self sendCodeFailed];
    }
}

- (void) sendCodeFinished {
    WEAKSELF;
    [self setBusy:NO actions:^{
        [weakSelf.B_sendCode setEnabled:YES];
        [weakSelf.TF_loginName setEnabled:YES];
        [weakSelf.validatorLogin validate:weakSelf.rememberedUsername];
    }];
}

- (void) sendCodeFailed {
    [self sendCodeFinished];
    [self setErrorText:PEXStr(@"txt_send_code_failed_general")];
}

- (void) sendCodeSuccess: (NSNumber *) status statusText: (NSString *) statusText validTo: (NSNumber *) validTo{
    WEAKSELF;
    [self sendCodeFinished];

    DDLogVerbose(@"Send code finished, status: %@, statusText: %@, validTo: %@", status, statusText, validTo);
    if (status == nil){
        [self setErrorText:PEXStr(@"txt_send_code_failed_general")];
        return;
    }

    NSInteger statusInt = [status integerValue];
    if (statusInt == -4){
        [self setErrorText:PEXStr(@"txt_send_code_failed_too_often")];
        return;
    } else if (statusInt == -5){
        [self setErrorText:PEXStr(@"txt_send_code_failed_too_often_ip")];
        return;
    } else if (statusInt == -3){
        [self setErrorText:PEXStr(@"txt_send_code_failed_empty_recovery_mail")];
        return;
    } else if (statusInt != 0 || validTo == nil){
        [self setErrorText:PEXStr(@"txt_send_code_failed_general")];
        return;
    }

    [self setErrorText:nil];

    NSDate * dateValidTo = [PEXUtils dateFromMillis:[validTo unsignedLongLongValue]];
    NSDate * dateNow = [NSDate date];
    NSTimeInterval validTime = [dateValidTo timeIntervalSinceDate:dateNow];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    NSString * info = [NSString stringWithFormat:PEXStr(@"txt_recovery_code_send_success"),
                    [dateFormatter stringFromDate:dateValidTo],
                    [PEXTimeUtils timeIntervalFormatted:validTime precision:PEXTimeFormatPrecisionMinutes]];

    // Show informative message box saying for how long the code will be valid.
    [PEXService executeOnMain:YES block:^{
        [PEXGuiFactory showInfoTextBox:weakSelf
                              withText:info
                            completion:nil];
    }];
}

- (IBAction) applyRecoveryCodeClicked: (id) sender {
    [self.validator validate:self.TF_recoveryCode.text];
    if ([self.validator state] != AJWValidatorValidationStateValid) {
        [self setErrorText:PEXStr(@"txt_recovery_code_not_valid")];
        return;
    }

    [self.validatorLogin validate:self.rememberedUsername];
    if ([self.validatorLogin state] != AJWValidatorValidationStateValid) {
        [self setErrorText:PEXStr(@"txt_login_name_not_valid")];
        return;
    }

    if ([PEXUtils isEmpty:self.rememberedUsername]){
        [self setErrorText:PEXStr(@"txt_login_name_not_valid")];
        return;

    }

    [self setErrorText:nil];
    self.applyCodeTask = [[PEXApplyRecoveryCodeTask alloc] init];
    self.applyCodeTask.dstUser = self.rememberedUsername;
    self.applyCodeTask.dstUserResource = [PEXUtils generateResource:self.rememberedUsername];
    self.applyCodeTask.recoveryCode = self.TF_recoveryCode.text;

    [self.B_applyCode setEnabled:NO];
    [self.TF_recoveryCode setEnabled:NO];
    [self setBusy:YES];

    WEAKSELF;
    PEXRecoveryCodeApplyFailed failureBlock = ^{
        [weakSelf applyCodeFailed];
    };

    PEXRecoveryCodeApplyFinished successBlock = ^(NSNumber * status, NSString * statusText, NSString * newPasswd) {
        [weakSelf applyCodeSuccess:status statusText:statusText passwd:newPasswd];
    };

    const bool success = [self.applyCodeTask applyRecoveryCode:successBlock errorHandler:failureBlock];
    if (!success) {
        [self applyCodeFailed];
    }
}

- (void) applyCodeFinished {
    WEAKSELF;
    [self setBusy:NO actions:^{
        [weakSelf.B_applyCode setEnabled:YES];
        [weakSelf.TF_recoveryCode setEnabled:YES];
        [weakSelf.validatorLogin validate:weakSelf.rememberedUsername];
        [weakSelf.validator validate:weakSelf.TF_recoveryCode.text];
    }];
}

- (void) applyCodeFailed {
    [self applyCodeFinished];
    [self setErrorText:PEXStr(@"txt_apply_code_failed_general")];
}

- (void) applyCodeSuccess: (NSNumber *) status statusText: (NSString *) statusText passwd: (NSString *) newPasswd{
    WEAKSELF;
    [self applyCodeFinished];

    DDLogVerbose(@"Apply code finished, status: %@, statusText: %@", status, statusText);
    if (status == nil){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_general")];
        return;
    }

    NSInteger statusInt = [status integerValue];
    if (statusInt == -4){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_too_often")];
        return;
    } else if (statusInt == -5){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_too_often_ip")];
        return;
    } else if (statusInt == -3){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_empty_recovery_mail")];
        return;
    } else if (statusInt == -10){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_invalid_code")];
        return;
    } else if (statusInt != 0 || newPasswd == nil || [PEXUtils isEmpty:newPasswd]){
        [self setErrorText:PEXStr(@"txt_apply_code_failed_general")];
        return;
    }

    [self setErrorText:nil];

    // Login now with new password. Call back login manager.
    PEXCredentials * creds = [PEXCredentials credentialsWithPassword:newPasswd username:self.rememberedUsername];
    [PEXService executeOnMain:YES block:^{
        [weakSelf.loginController storeCredentialsAfterPasswordChange:creds];
        [weakSelf dismissWithCompletion:^{
            DDLogVerbose(@"Starting login with new credentials");
        }];
    }];
}

- (void)fillInCode:(NSString *)code {
    // Sanitizing.
    NSString * formattedCode = [self formatRecoveryCode:code];
    DDLogVerbose(@"Filling in code: %@", formattedCode);

    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        weakSelf.TF_recoveryCode.text = formattedCode;
        [weakSelf.validator validate:formattedCode];
    }];
}

-(void)setBusy: (BOOL) busy {
    [self setBusy:busy actions:nil];
}

-(void)setBusy: (BOOL) busy actions: (dispatch_block_t) actions{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        weakSelf.isBusy = busy;
        if (actions){
            actions();
        }

        [weakSelf layoutAll];
    }];
}

- (void)setErrorText:(NSString *)string {
    [self setErrorText:string actions:nil];
}

- (void)setErrorText:(NSString *)string actions: (dispatch_block_t) actions {
    self.errorMessage = string;
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        if (actions){
            actions();
        }
        [weakSelf layoutAll];
    }];
}

-(void) refreshDisplay {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        [weakSelf layoutAll];
    }];
}

-(void) dismissWithCompletion: (dispatch_block_t) completion{
    [self.fullscreener dismissViewControllerAnimated:YES completion:completion];
}

#pragma mark States

- (void)handleValid
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_recoveryCode.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
}

- (void)handleInvalid
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_recoveryCode.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];
}

- (void)handleWaiting
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)handleValidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_loginName.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
}

- (void)handleInvalidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_loginName.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];

}

- (void)handleWaitingLogin
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        [weakSelf.view endEditing:YES];
    }];
    return YES;
}

#pragma mark AJWValidatorDelegate

- (void)validator:(AJWValidator *)validator remoteValidationAtURL:(NSURL *)url receivedResult:(BOOL)remoteConditionValid
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)validator:(AJWValidator *)validator remoteValidationAtURL:(NSURL *)url failedWithError:(NSError *)error
{
    DDLogVerbose(@"Remote service could not be contacted: %@. Have you started the sinatra server?", error);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *errorMessage = [NSString stringWithFormat:@"The remote service could not be contacted: %@. Have you started the Sinatra server bundled with the demo?", error];
        UIAlertView *alertOnce = [[UIAlertView alloc] initWithTitle:@"Remote service error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertOnce show];
    });

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end