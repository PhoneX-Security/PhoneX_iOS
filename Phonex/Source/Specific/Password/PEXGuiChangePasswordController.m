//
//  PEXGuiChangePassword.m
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiChangePasswordController.h"
#import "PEXGuiBusyInputController_Protected.h"

#import "PEXGuiTextField.h"
#import "PEXStringUtils.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiChangePasswordExecutor.h"
#import "PEXReport.h"

@interface PEXGuiChangePasswordController()

@property (nonatomic) UITextField *TF_oldPassword;
@property (nonatomic) UITextField *TF_newPassword;
@property (nonatomic) UITextField *TF_newPasswordRepeated;

@property (nonatomic) UIButton * B_change;

@property (nonatomic) PEXGuiChangePasswordExecutor * executor;

@end

@implementation PEXGuiChangePasswordController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ChangePassword";

    self.TF_oldPassword = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_oldPassword];
    self.TF_newPassword = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_newPassword];
    self.TF_newPasswordRepeated = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_newPasswordRepeated];

    self.B_change = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_change];
}

- (void) initContent
{
    [super initContent];

    self.TF_oldPassword.placeholder = PEXStr(@"L_old_password");
    self.TF_newPassword.placeholder = PEXStr(@"L_new_password");
    self.TF_newPasswordRepeated.placeholder = PEXStr(@"L_new_password_repeat");

    [self.B_change setTitle:PEXStrU(@"L_change") forState:UIControlStateNormal];
}

- (void) initBehavior
{
    [super initBehavior];

    [self setUpTF:self.TF_oldPassword];
    [self setUpTF:self.TF_newPassword];
    [self setUpTF:self.TF_newPasswordRepeated];

    [self.B_change addTarget:self action:@selector(changePassword:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initState
{
    [super initState];

    self.executor = [[PEXGuiChangePasswordExecutor alloc] initWithParentController:self];
    self.executor.showedController = self;
    [self.executor topControllerShowed:self.fullscreener];
}

- (IBAction) changePassword: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CHANGE_PASSWORD];
    [self.executor primaryButtonClicked];
}

- (void) setUpTF: (UITextField * const) tf
{
    [tf setDelegate:self];
    tf.secureTextEntry = YES;
}

/*
- (void) setErrorText: (NSString * const) text
{
    [PEXGVU move:self.TV_errorText below: self.B_change withMargin:PEXVal(@"dism_size_small")];

    [super setErrorText:text];
}
*/

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TF_oldPassword withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToTop:self.TF_oldPassword withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.TF_newPassword withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_newPassword below:self.TF_oldPassword withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.TF_newPasswordRepeated withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_newPasswordRepeated below:self.TF_newPassword withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.B_change withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_change below:self.TF_newPasswordRepeated withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.TV_errorText withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TV_errorText below: self.B_change withMargin:PEXVal(@"dism_size_small")];
}

- (void)setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    [PEXGVU makeFullscreenBackground:self.mainView];
}
/*
- (void)setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    [super setSizeInView:parent];

    [PEXGVU setSize:
     self.mainView
                  x:
     self.mainView.frame.size.width
                  y:      self.mainView.frame.size.height +
     (PEXVal(@"dim_size_small") * 3) + // 2 x TF - TV hole
     (3 * self.TF_newPassword.frame.size.height)]; // 3 TF
}
*/

- (void) setBusyInternal: (const bool) busy
{
    [super setBusyInternal:busy];

    self.TF_oldPassword.text =
        [PEXStringUtils trimWhiteSpaces:self.TF_oldPassword .text];
    self.TF_newPassword.text =
        [PEXStringUtils trimWhiteSpaces:self.TF_newPassword.text];
    self.TF_newPasswordRepeated.text =
        [PEXStringUtils trimWhiteSpaces:self.TF_newPasswordRepeated.text];

    self.TF_oldPassword.enabled = !busy;
    self.TF_newPassword.enabled = !busy;
    self.TF_newPasswordRepeated.enabled = !busy;

    [self.B_change setEnabled:!busy];

    [PEXGVU move:self.activityIndicatorView below: self.B_change withMargin:PEXVal(@"dism_size_large")];
}

- (NSString *) oldPassword
{
    return self.TF_oldPassword.text;
}
- (NSString *) newPassword
{
    return self.TF_newPassword.text;
}
- (NSString *) newPasswordRepeated
{
    return self.TF_newPasswordRepeated.text;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [self.executor secondaryButtonClicked];

    [super dismissViewControllerAnimated:flag completion:completion];
}

@end
