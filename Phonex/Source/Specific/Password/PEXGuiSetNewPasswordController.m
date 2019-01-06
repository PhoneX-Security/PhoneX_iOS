//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiSetNewPasswordController.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiTextField.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiControllerDecorator.h"
#import "PEXGuiErrorTextView.h"

@interface PEXGuiSetNewPasswordController ()

@property (nonatomic) UITextField * TF_newPassword;
@property (nonatomic) UITextField *TF_repeatPassword;
@property (nonatomic) PEXGuiErrorTextView * TV_errorText;

@end

@implementation PEXGuiSetNewPasswordController {

}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"SetNewPassword";

    self.TF_newPassword = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_newPassword];
    self.TF_repeatPassword = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_repeatPassword];

    self.TV_errorText = [[PEXGuiErrorTextView alloc] init];
    [self.mainView addSubview:self.TV_errorText];
}

- (void) initContent
{
    [super initContent];

    self.TF_newPassword.placeholder = PEXStr(@"L_new_password");
    self.TF_repeatPassword.placeholder = PEXStr(@"L_new_password_repeat");
}

- (void) initBehavior
{
    [super initBehavior];

    [self.TF_newPassword setDelegate:self];
    [self.TF_repeatPassword setDelegate:self];

    self.TF_newPassword.secureTextEntry = YES;
    self.TF_repeatPassword.secureTextEntry = YES;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TF_newPassword withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToTop:self.TF_newPassword withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.TF_repeatPassword withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_repeatPassword below:self.TF_newPassword withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.TV_errorText withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TV_errorText below:self.TF_repeatPassword withMargin:PEXVal(@"dim_size_small")];
}

- (NSString *) getNewPassword
{
    return self.TF_newPassword.text;
}
- (NSString *) getRepeatedNewPassword
{
    return self.TF_repeatPassword.text;
}

- (void)setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    [PEXGVU setSize:
                    self.mainView
                  x:
                          parent.subviewMaxWidth
                  y:
                          (PEXVal(@"dim_size_small") * 2) + // TF - TF - TV holes
                                  (2 * PEXVal(@"dim_size_large")) + // upper and lower margin
                                  (2 * PEXVal(@"dim_size_medium")) + // 2 rows of text error
                                  (2 * self.TF_newPassword.frame.size.height)]; // 2 TF
}

- (void) setErrorText: (NSString * const) text
{
    self.TV_errorText.text = text;
    [self.TV_errorText sizeToFit];
    [PEXGVU shakeView: self.mainView];
}

@end