//
// Created by Dusan Klinec on 28.01.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiPasswordVerificationController.h"
#import "PEXDBUserProfile.h"
#import "AJWValidator.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiErrorTextView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiButtonMain.h"
#import "PEXService.h"
#import "PEXUtils.h"
#import "PEXDbAppContentProvider.h"
#import "PEXGuiTextView_Protected.h"
#import "PEXGuiLoginController.h"
#import "UITextView+PEXPaddings.h"

#define MAX_INVALID_RETRIES 10

@interface PEXGuiPasswordVerificationController ()
@property (nonatomic) PEXGuiClickableScrollView * V_scroller;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_prologue;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_auxInfo;
@property (nonatomic) UITextField *TF_password;
@property (nonatomic) UIButton *B_check;

@property (nonatomic) PEXGuiErrorTextView * TV_errorText;
@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

@property (atomic) BOOL isBusy;
@property (nonatomic) NSString * errorMessage;
@property (nonatomic) PEXDbUserProfile * profile;
@end

@implementation PEXGuiPasswordVerificationController {

}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"RecoveryEmailSet";
    self.isBusy = NO;

    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];
    UIView * mainContainer = self.V_scroller;

    self.TV_prologue = [[PEXGuiReadOnlyTextView alloc] init];
    [mainContainer addSubview:self.TV_prologue];

    self.TV_auxInfo = [[PEXGuiReadOnlyTextView alloc] init];
    [mainContainer addSubview:self.TV_auxInfo];

    self.TF_password = [[PEXGuiTextField alloc] init];
    [mainContainer addSubview:self.TF_password];

    self.B_check = [[PEXGuiButtonMain alloc] init];
    [mainContainer addSubview:self.B_check];

    self.TV_errorText = [[PEXGuiErrorTextView alloc] init];
    [mainContainer addSubview:self.TV_errorText];

    self.activityIndicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [mainContainer addSubview:self.activityIndicatorView];
}

- (void)initContent
{
    [super initContent];

    self.TV_prologue.text = PEXStr(@"txt_password_verification_needed");
    self.TV_auxInfo.attributedText = self.attributedExtra == nil ? nil : self.attributedExtra;
    self.TF_password.secureTextEntry = YES;
    self.TF_password.placeholder = PEXStr(@"L_login_password");
    self.TF_password.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.TF_password becomeFirstResponder];
    [self.B_check setTitle:PEXStrU(@"B_ok") forState:UIControlStateNormal];
}

- (void)initBehavior
{
    [self.B_check addTarget:self action:@selector(change:) forControlEvents:UIControlEventTouchUpInside];
    [self.TV_prologue setScrollEnabled:false];
    [self.TV_auxInfo setScrollEnabled:false];
    [self.TV_errorText setScrollEnabled:false];
    [super initBehavior];
}

- (void)initLayout
{
    [super initLayout];
    [self layoutAll];
}

- (void)layoutAll
{
    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU scaleHorizontally:self.TV_prologue withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU scaleHorizontally:self.TV_auxInfo withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU scaleHorizontally:self.TF_password withMargin:margin];
    [PEXGVU scaleHorizontally:self.B_check withMargin:margin];

    [self.TV_prologue setPaddingNumTop:nil left:@(0.0) bottom:nil rigth:@(0.0)];
    [self.TV_prologue sizeToFit];
    [PEXGVU moveToTop:self.TV_prologue];

    UIView * viewTop = self.TV_prologue;
    UIView * bottom = self.B_check;

    // Aux info?
    if (self.attributedExtra != nil){
        self.TV_auxInfo.text = nil;
        self.TV_auxInfo.attributedText = self.attributedExtra;
        [self.TV_auxInfo setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_auxInfo sizeToFit];
        [PEXGVU move:self.TV_auxInfo below:viewTop];
        viewTop = self.TV_auxInfo;
    }

    [PEXGVU move:self.TF_password below:viewTop];
    [PEXGVU move:self.B_check below:self.TF_password withMargin:margin];

    // Error message.
    if (![PEXUtils isEmpty:self.errorMessage]){
        [PEXGVU scaleHorizontally:self.TV_errorText withMargin:margin];
        [PEXGVU scaleHorizontally:self.TV_errorText  withMargin:PEXVal(@"dim_size_medium")];
        self.TV_errorText.text = self.errorMessage;
        [self.TV_errorText setPaddingNumTop:@(0.0) left:@(0.0) bottom:nil rigth:@(0.0)];
        [self.TV_errorText sizeToFit];

        [PEXGVU move:self.TV_errorText below:self.B_check withMargin:margin];
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

- (IBAction) change: (id) sender
{
    [self checkPasswordAsync: self.TF_password.text];
}

-(void)setBusy: (BOOL) busy {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        weakSelf.isBusy = busy;
        [weakSelf layoutAll];
    }];
}

-(void)setErrorText:(NSString *)string {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        weakSelf.errorMessage = string;
        [weakSelf layoutAll];
    }];
}

-(void)setAuxText:(NSAttributedString *)string {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        weakSelf.attributedExtra = string;
        [weakSelf layoutAll];
    }];
}

-(void)refreshDisplay {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^ {
        [weakSelf layoutAll];
    }];
}

-(void)onPasswordMatches {
    [PEXService executeOnMain:YES block:^{
        [self.fullscreener dismissViewControllerAnimated:true completion:^ {
            if (self.onSuccess){
                self.onSuccess();
            }
        }];
    }];
}

- (void) checkPasswordAsync: (NSString *) pass{
    [self setBusy:YES];

    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:@"profileLoad" async:YES block:^{
        PEXUserPrivate * privData = [[PEXService instance] privData];
        if (privData == nil || privData.accountId == nil){
            DDLogError(@"Could not load profile");
            return;
        }

        if ([privData.pass isEqualToString:pass]){
            [privData resetInvalidPasswordEntryCounter];
            [weakSelf setErrorText:nil];
            [weakSelf onPasswordMatches];

        } else {
            NSInteger invalidRetries = [privData incAndGetInvalidPasswordEntryCounter];
            if (invalidRetries >= MAX_INVALID_RETRIES){
                [PEXService executeOnGlobalQueueWithName:@"logout" async:YES block:^ {
                    [[PEXGuiLoginController instance] performLogoutWithMessage:PEXStr(@"txt_too_many_invalid_password_attempts")];
                }];
            }

            [weakSelf setErrorText:[NSString stringWithFormat:@"%@ %ld", PEXStr(@"txt_invalid_password"), (long) (MAX_INVALID_RETRIES - invalidRetries)]];
        }

        [weakSelf setBusy:NO];
        [weakSelf refreshDisplay];
    }];
}

- (void)dismissWithCompletion:(void (^)(void))completion animation:(void (^)(void))animation {
    [self.TF_password resignFirstResponder];
    [super dismissWithCompletion:completion animation:animation];
}


@end