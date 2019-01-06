//
// Created by Dusan Klinec on 18.01.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiRecoveryEmailController.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiBackgroundView.h"
#import "PEXDbContact.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiTextFIeld.h"
#import "PEXDBUserProfile.h"
#import "PEXService.h"
#import "PEXUtils.h"
#import "AJWValidator+Private.h"
#import "AJWValidatorRegularExpressionRule.h"
#import "PEXGuiErrorTextView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiTextView_Protected.h"
#import "PEXGuiPasswordVerificationController.h"
#import "PEXGuiRecoveryEmailExecutor.h"
#import "PEXGuiFactory.h"
#import "PEXAccountSettingsTask.h"
#import "PEXSOAPResult.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "UITextView+PEXPaddings.h"

#define EMAIL_REGEX @"(^$)|(^[_A-Za-z0-9-+]+(\\.[_A-Za-z0-9-+]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z‌​]{2,})$)"

@interface PEXGuiRecoveryEmailController () <AJWValidatorDelegate>
@property (nonatomic) PEXGuiClickableScrollView * V_scroller;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_prologue;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_warning;
@property (nonatomic) UITextField *TF_recoveryEmail;
@property (nonatomic) UIButton * B_change;

@property (nonatomic) PEXGuiErrorTextView * TV_errorText;
@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

@property (atomic) BOOL isBusy;
@property (atomic) BOOL emailChanged;
@property (nonatomic) NSString * errorMessage;
@property (nonatomic) AJWValidator * validator;
@property (nonatomic) PEXDbUserProfile * profile;
@property (nonatomic) PEXGuiPasswordVerificationController * pwdVerifCtl;
@property (nonatomic) PEXGuiRecoveryEmailExecutor * executor;
@property (nonatomic) PEXAccountSettingsTask * task;

@end

@implementation PEXGuiRecoveryEmailController {

}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"RecoveryEmailSet";

    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];
    UIView * mainContainer = self.V_scroller;

    self.TV_prologue = [[PEXGuiReadOnlyTextView alloc] init];
    [mainContainer addSubview:self.TV_prologue];

    self.TV_warning = [[PEXGuiReadOnlyTextView alloc] init];
    [mainContainer addSubview:self.TV_warning];

    self.TF_recoveryEmail = [[PEXGuiTextField alloc] init];
    [mainContainer addSubview:self.TF_recoveryEmail];

    self.B_change = [[PEXGuiButtonMain alloc] init];
    [mainContainer addSubview:self.B_change];

    self.TV_errorText = [[PEXGuiErrorTextView alloc] init];
    [mainContainer addSubview:self.TV_errorText];

    self.activityIndicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [mainContainer addSubview:self.activityIndicatorView];
}

- (void)initContent
{
    [super initContent];

    self.TV_prologue.text = PEXStr(@"txt_recovery_mail_intro");
    self.TF_recoveryEmail.placeholder = PEXStr(@"L_recovery_mail_placeholder");
    self.TF_recoveryEmail.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.TF_recoveryEmail setKeyboardType:UIKeyboardTypeEmailAddress];
    [self.B_change setTitle:PEXStrU(@"B_change") forState:UIControlStateNormal];
}

- (void)initBehavior
{
    [self.B_change addTarget:self action:@selector(change:) forControlEvents:UIControlEventTouchUpInside];
    [self.TV_prologue setScrollEnabled:false];
    [self.TV_warning setScrollEnabled:false];
    [self.TV_errorText setScrollEnabled:false];

    // Validation rule - new extended regex
    AJWValidatorRegularExpressionRule *rule = [[AJWValidatorRegularExpressionRule alloc] initWithType:AJWValidatorRuleTypeEmail
                                                                                       invalidMessage:PEXStr(@"E-mail is not valid")
                                                                                              pattern:EMAIL_REGEX];

    self.validator = [AJWValidator validatorWithType:AJWValidatorTypeString];
    [self.validator addValidationRule:rule];

    [self.TF_recoveryEmail ajw_attachValidator:self.validator];
    [self.TF_recoveryEmail addTarget:self action:@selector(textFieldTextChanged:) forControlEvents:UIControlEventEditingChanged];

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
    self.emailChanged = NO;
    [self loadProfileAsync];
}

- (void)textFieldTextChanged:(UITextField *)sender
{
    self.emailChanged = YES;
    [self.validator validate:sender.text];
}

- (void)layoutAll
{
    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU scaleHorizontally:self.TV_prologue withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU scaleHorizontally:self.TV_warning withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU scaleHorizontally:self.TF_recoveryEmail withMargin:margin];
    [PEXGVU scaleHorizontally:self.B_change withMargin:margin];

    [self.TV_prologue setPaddingNumTop:nil left:@(0.0) bottom:nil rigth:@(0.0)];
    [self.TV_prologue sizeToFit];
    [PEXGVU moveToTop:self.TV_prologue];

    UIView * viewTop = self.TV_prologue;
    UIView * bottom = self.B_change;

    if (self.profile == nil || [PEXUtils isEmpty: self.profile.recovery_email]) {
        self.TV_warning.text = PEXStr(@"txt_recovery_mail_warning");
        self.TV_warning.textColor = PEXCol(@"red_normal");
        [self.TV_warning setHidden:NO];
        [self.TV_warning setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_warning sizeToFit];

        [PEXGVU move:self.TV_warning below:self.TV_prologue];
        viewTop = self.TV_warning;

    } else {
        [self.TV_warning setHidden:YES];
        self.TV_warning.text = nil;
        [self.TV_warning setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_warning sizeToFit];
    }

    // Email not changed? Show one from profile
    if (!self.emailChanged && ![PEXUtils isEmpty:self.profile.recovery_email]){
        self.TF_recoveryEmail.text = self.profile.recovery_email;
    }

    [PEXGVU move:self.TF_recoveryEmail below:viewTop];
    [PEXGVU move:self.B_change below:self.TF_recoveryEmail withMargin:margin];

    // Error message.
    if (![PEXUtils isEmpty:self.errorMessage]){
        [PEXGVU scaleHorizontally:self.TV_errorText  withMargin:PEXVal(@"dim_size_medium")];
        self.TV_errorText.text = self.errorMessage;
        [self.TV_errorText setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_errorText sizeToFit];

        [PEXGVU move:self.TV_errorText below:self.B_change withMargin:margin];
        [PEXGVU shakeView:self.mainView];

        bottom = self.TV_errorText;

    } else {
        self.TV_errorText.text = nil;
        [self.TV_errorText sizeToFit];
    }

    // Busy?
    if (self.isBusy){
        [PEXGVU move:self.activityIndicatorView below:bottom withMargin:margin];
        [PEXGVU centerHorizontally:self.activityIndicatorView];
        bottom = self.activityIndicatorView;
    }

    self.V_scroller.contentSize =
            CGSizeMake(self.mainView.frame.size.width, [PEXGVU getLowerPoint:bottom] + margin);
}

- (IBAction) change: (id) sender {
    // Regex testing.
    [self.validator validate:self.TF_recoveryEmail.text];
    if ([self.validator state] != AJWValidatorValidationStateValid) {
        [self setErrorText:PEXStr(@"txt_invalid_email")];
        return;
    }

    // Same as previously entered.
    if ([self.TF_recoveryEmail.text isEqualToString:self.profile.recovery_email]) {
        [self setErrorText:PEXStr(@"txt_same_recovery_email")];
        return;
    }

    [self setErrorText:nil];

    // Ask for verification.
    WEAKSELF;
    PEXGuiBinaryDialogExecutor *const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
    executor.primaryButtonText = PEXStrU(@"B_change");
    executor.secondaryButtonText = PEXStrU(@"B_cancel");

    [self.TF_recoveryEmail resignFirstResponder];
    if ([PEXUtils isEmpty:self.TF_recoveryEmail.text]){
        executor.text = PEXStr(@"txt_confirm_email_change_empty");
    } else {
        NSMutableAttributedString * descriptionText = [[NSMutableAttributedString alloc] init];
        NSMutableAttributedString * emailStr = [[NSMutableAttributedString alloc] initWithString:self.TF_recoveryEmail.text];

        [emailStr addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")]
                     range:NSMakeRange(0, emailStr.length)];
        [emailStr addAttribute:NSUnderlineStyleAttributeName
                         value:@(NSUnderlineStyleSingle)
                         range:NSMakeRange(0, emailStr.length)];

        [descriptionText appendAttributedString:[[NSAttributedString alloc] initWithString:
                [NSString stringWithFormat:@"%@\n", PEXStr(@"txt_confirm_email_change")]]];

        [descriptionText addAttribute:NSFontAttributeName
                         value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")]
                         range:NSMakeRange(0, descriptionText.length)];

        [descriptionText appendAttributedString:emailStr];
        executor.attributedText = descriptionText;
    }

    executor.primaryAction = ^{
        [weakSelf onChangeConfirmed];
    };

    executor.secondaryAction =^{
        [weakSelf.TF_recoveryEmail becomeFirstResponder];
    };

    [executor show];
}

-(void) onChangeConfirmed {
    // Password verification via password check controller.
    // Prepare aux string for password verification controller.
    NSMutableAttributedString * descriptionText = [[NSMutableAttributedString alloc] init];
    if (![PEXUtils isEmpty:self.TF_recoveryEmail.text]){
        NSMutableAttributedString *emailStr = [[NSMutableAttributedString alloc] initWithString:self.TF_recoveryEmail.text];
        [emailStr addAttribute:NSFontAttributeName
                         value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")]
                         range:NSMakeRange(0, emailStr.length)];
        [emailStr addAttribute:NSUnderlineStyleAttributeName
                         value:@(NSUnderlineStyleSingle)
                         range:NSMakeRange(0, emailStr.length)];

        [descriptionText appendAttributedString:[[NSAttributedString alloc] initWithString:
                [NSString stringWithFormat:@"%@\n", PEXStr(@"txt_aux_email_change")]]];

        [descriptionText addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")]
                                range:NSMakeRange(0, descriptionText.length)];

        [descriptionText appendAttributedString:emailStr];

    } else {
        [descriptionText appendAttributedString:[[NSAttributedString alloc] initWithString:PEXStr(@"txt_aux_email_change_empty")]];
        [descriptionText addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")]
                                range:NSMakeRange(0, descriptionText.length)];
    }

    // Execute also in main.
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        // Password verification controller.
        weakSelf.pwdVerifCtl = [[PEXGuiPasswordVerificationController alloc] init];
        weakSelf.pwdVerifCtl.attributedExtra = descriptionText;
        weakSelf.pwdVerifCtl.onSuccess = ^ {
            [PEXService executeOnGlobalQueueWithName:@"passwd_success" async:YES block:^ {
                [weakSelf onPasswordSuccess];
            }];
        };

        [PEXGAU showInNavigation:weakSelf.pwdVerifCtl
                              in:weakSelf
                           title:PEXStrU(@"L_password_verification")];
    }];
}

-(void)setBusy: (BOOL) busy {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        weakSelf.isBusy = busy;
        [weakSelf layoutAll];
    }];
}

- (void)setErrorText:(NSString *)string {
    self.errorMessage = string;
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
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

- (void)onPasswordSuccess {
    DDLogVerbose(@"Password entry succeed");
    [self setBusy:YES];

    // Warning: this code is not consistent with the rest. It should be in the executor.
    // Executor should own the controller, here, controller is the master, having both logic + view inside.
    WEAKSELF;
    NSString * email = self.TF_recoveryEmail.text;

    dispatch_block_t successBlock = ^{
        DDLogVerbose(@"Settings update successful");
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEX_DBUSR_FIELD_RECOVERY_EMAIL string:email];
        int updateRes = [cr updateEx:[PEXDbUserProfile getURI]
                       ContentValues:cv
                           selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBUSR_FIELD_ID]
                       selectionArgs:@[self.profile.id]];

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.executor dismissWithCompletion:nil];
            [weakSelf setBusy:NO];
            [weakSelf dismissWithCompletion:nil];
        });
    };

    dispatch_block_t failureBlock = ^{
        DDLogError(@"Settings update task failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.executor dismissWithCompletion:nil];
            [PEXGuiFactory showErrorTextBox:self
                                   withText:PEXStr(@"txt_recovery_email_change_failed")
                                 completion:^{
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [weakSelf setBusy:NO];
                                         [weakSelf dismissWithCompletion:nil];
                                     });
                                 }];
        });
    };

    [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
        // We need internet connection.
        if (![[PEXService instance] isConnectivityWorking]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [PEXGuiFactory showErrorTextBox:weakSelf
                                       withText:PEXStr(@"txt_internet_connection_required")
                                     completion:^{
                                         [weakSelf setBusy:NO];
                                         [weakSelf dismissWithCompletion:nil];
                                     }];
            });
            return;
        }

        // Settings task.
        weakSelf.task = [[PEXAccountSettingsTask alloc] init];
        weakSelf.task.privData = [[PEXAppState instance] getPrivateData];
        weakSelf.task.retryCount = 3;
        weakSelf.task.recoveryEmail = email;
        weakSelf.task.completionHandler = ^(PEXAccountSettingsTask *task) {
            if (task.lastResult.code == PEX_SOAP_CALL_RES_OK){
                successBlock();

            } else {
                failureBlock();
            }
        };

        // Progress monitor, indeterminate.
        weakSelf.executor = [[PEXGuiRecoveryEmailExecutor alloc] init];
        weakSelf.executor.parentController = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.executor show];

            // Execute on the background task.
            [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
                [weakSelf.task requestWithRetryCount];
            }];
        });
    }];
}

- (void)loadProfileAsync
{
    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:@"profileLoad" async:YES block:^{
        PEXUserPrivate * privData = [[PEXService instance] privData];
        if (privData == nil || privData.accountId == nil){
            DDLogError(@"Could not load profile");
            return;
        }

        weakSelf.profile = [PEXDbUserProfile getProfileFromDbId:[PEXDbAppContentProvider instance]
                                                                       id:privData.accountId
                                                               projection:nil];

        if (weakSelf.profile == nil){
            DDLogError(@"loaded profile is nil");
            return;
        }

        // Notification seen
        [[PEXGNFC instance] unsetRecoveryMailNotificationAsync];

        // Refresh view
        [weakSelf refreshDisplay];
    }];
}

#pragma mark States

- (void)handleValid
{
    UIColor *validGreen = PEXCol(@"green_normal");
    self.TF_recoveryEmail.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
}

- (void)handleInvalid
{
    UIColor *invalidRed = PEXCol(@"red_normal");
    self.TF_recoveryEmail.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
}

- (void)handleWaiting
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

#pragma mark AJWValidatorDelegate

- (void)validator:(AJWValidator *)validator remoteValidationAtURL:(NSURL *)url receivedResult:(BOOL)remoteConditionValid
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)validator:(AJWValidator *)validator remoteValidationAtURL:(NSURL *)url failedWithError:(NSError *)error
{
    NSLog(@"Remote service could not be contacted: %@. Have you started the sinatra server?", error);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *errorMessage = [NSString stringWithFormat:@"The remote service could not be contacted: %@. Have you started the Sinatra server bundled with the demo?", error];
        UIAlertView *alertOnce = [[UIAlertView alloc] initWithTitle:@"Remote service error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertOnce show];
    });

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


@end
