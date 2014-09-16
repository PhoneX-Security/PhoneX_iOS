//
//  PEXViewController.m
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLogin.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiViewUtils.h"

#import "PEXGuiBackgroundView.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiImageView.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiWindowWithTitleController.h"
#import "PEXGuiDialogUnaryController.h"
#import "PEXGuiDialogCloser.h"
#import "PEXGuiDialogBinaryController.h"
#import "PEXGuiDialogDoubleCloser.h"
#import "PEXGuiTextController.h"
#import "PEXTestingController.h"
#import "PEXGuiWindowMainView.h"


@interface PEXGuiLogin ()

@property (nonatomic) UITextField * TF_username;
@property (nonatomic) UITextField * TF_password;
@property (nonatomic) UIButton * B_login;
@property (nonatomic) UILabel * L_description;
@property (nonatomic) UILabel * L_copyright;
@property (nonatomic) UIImageView * I_appLogo;

@end

// TODO consider maybe different impl file for InitGui and layout, Category?
@implementation PEXGuiLogin

// MAINTENANCE

- (void) initGuiComponents
{
    [super initGuiComponents];
    
    self.TF_username = [[PEXGuiTextFIeld alloc] init];
    [self.mainView addSubview:self.TF_username];
    [self.TF_username setDelegate:self];
    self.TF_password = [[PEXGuiTextFIeld alloc] init];
    [self.mainView addSubview:self.TF_password];
    [self.TF_password setDelegate:self];
    self.B_login = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_login];
    self.L_description = [[PEXGuiClassicLabel alloc]
                          initWithFontSize:PEXVal(@"fontSizeMedium")
                          fontColor:PEXCol(@"grayHigh")];
    [self.mainView addSubview:self.L_description];
    self.L_copyright = [[PEXGuiClassicLabel alloc]
                        initWithFontSize:PEXVal(@"fontSizeSmall")
                        fontColor:PEXCol(@"grayHigh")];
    [self.mainView addSubview:self.L_copyright];
    self.I_appLogo = [[PEXGuiImageView alloc] init];
    [self.mainView addSubview: self.I_appLogo];
}

- (void) initContent
{
    [super initContent];
    
    self.TF_username.placeholder = PEXStr(@"username");
    self.TF_password.placeholder = PEXStr(@"password");
    [self.B_login setTitle:(PEXStrU(@"login")) forState:UIControlStateNormal];
    [self.L_description setText:PEXStr(@"description")];
    [self.L_copyright setText:PEXUnStr(@"AppName")];
    [self.I_appLogo setImage:[UIImage imageNamed:@"log128.png"]];
}

- (void) initBehavior
{
    [super initBehavior];

    self.TF_password.secureTextEntry = YES;
    [self.B_login addTarget:self action:@selector(login:)
       forControlEvents:UIControlEventTouchUpInside];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU centerHorizontally:self.L_copyright];
    [PEXGVU moveToBottom:self.L_copyright withMargin:PEXVal(@"contentMarginLarge")];

    [PEXGVU centerHorizontally:self.L_description];
    [PEXGVU move:self.L_description above:self.L_copyright withMargin:PEXVal(@"distanceNormal")];

    [PEXGVU scaleHorizontally:self.B_login withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU move:self.B_login above:self.L_description
      withMargin:PEXVal(@"distanceNormal")];

    [PEXGVU scaleHorizontally:self.TF_password withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU move:self.TF_password above:self.B_login withMargin:PEXVal(@"distanceNormal")];

    [PEXGVU scaleHorizontally:self.TF_username withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU move:self.TF_username above:self.TF_password withMargin:PEXVal(@"distanceNormal")];

    [PEXGVU centerHorizontally:self.I_appLogo];
    [PEXGVU moveToTop:self.I_appLogo withMargin:PEXVal(@"I_logoFromTopPadding")];
}

- (IBAction) login:(id)sender
{   
    PEXTestingController * vc = [[PEXTestingController alloc] init];
    [vc prepareOnScreen:self];
    [vc show:self];
}

@end
