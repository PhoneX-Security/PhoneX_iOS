//
//  PEXGuiCallBaseViewController.m
//  Phonex
//
//  Created by Matej Oravec on 03/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiCallController.h"
#import "PEXGuiControllerDecorator_Protected.h"

#import "PEXGuiViewUtils.h"

#import "PEXGuiWindowMainView.h"
#import "PEXGuiImageView.h"
#import "PEXGuiImageClickableView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiButtonMain.h"

#import "PEXGuiViewRow.h"
#import "PEXGuiButtonWithImageCall.h"

@interface PEXGuiCallController ()

@property (nonatomic) UIImageView * I_fancyImage;
@property (nonatomic) UILabel * L_status;
@property (nonatomic) UILabel * L_name;

@property (nonatomic) PEXGuiImageClickableView * I_answer;
@property (nonatomic) PEXGuiImageClickableView * I_reject;

@property (nonatomic) UIButton * B_endCall;

@property (nonatomic) PEXGuiViewRow * B_row;
@property (nonatomic) UIView * V_loud;
@property (nonatomic) UIView * V_mute;
@property (nonatomic) UIView * V_more;


@end

@implementation PEXGuiCallController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.I_fancyImage = [[PEXGuiImageView alloc] init];
    [self.mainView addSubview: self.I_fancyImage];

    self.L_status = [[PEXGuiClassicLabel alloc]
                          initWithFontSize:PEXVal(@"fontSizeMedium")
                          fontColor:PEXCol(@"grayHigh")];
    [self.mainView addSubview: self.L_status];

    self.L_name = [[PEXGuiClassicLabel alloc]
                     initWithFontSize:PEXVal(@"fontSizeMedium")
                     fontColor:PEXCol(@"grayHigh")];
    [self.mainView addSubview: self.L_name];

    self.B_endCall = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_endCall];

    self.I_answer = [[PEXGuiImageClickableView alloc] init];
    [self.mainView addSubview: self.I_answer];

    self.I_reject = [[PEXGuiImageClickableView alloc] init];
    [self.mainView addSubview: self.I_reject];

    self.B_row = [[PEXGuiViewRow alloc] init];
    [self.mainView addSubview:self.B_row];
    self.V_loud = [[PEXGuiButtonWithImageCall alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_loud];
    self.V_mute = [[PEXGuiButtonWithImageCall alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_mute];
    self.V_more = [[PEXGuiButtonWithImageCall alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_more];
}

- (void) initContent
{
    [super initContent];

    [self.I_fancyImage setImage:[UIImage imageNamed:@"log128.png"]];

    [self setText:PEXDefaultStr forLabel:self.L_name];
    [self setText:PEXDefaultStr forLabel:self.L_status];

    [self.B_endCall setTitle:PEXDefaultStr forState:UIControlStateNormal];

    [self.I_answer setImage:[UIImage imageNamed:@"log64.png"]];
    //[self.I_answer setHighlightedImage:[UIImage imageNamed:@"log32.png"]];
    [self.I_reject setImage:[UIImage imageNamed:@"log64.png"]];
    //[self.I_reject setHighlightedImage:[UIImage imageNamed:@"log32.png"]];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU centerHorizontally:self.I_fancyImage];
    [PEXGVU moveToTop:self.I_fancyImage
           withMargin:PEXVal(@"I_logoFromTopPadding")];

    [PEXGVU moveToBottom:self.B_endCall withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU scaleHorizontally:self.B_endCall withMargin:PEXVal(@"contentMarginLarge")];

    [PEXGVU setHeight:self.B_row to:PEXVal(@"B_imageButton_height")];
    [PEXGVU move:self.B_row above:self.B_endCall withMargin:PEXVal(@"distanceNormal")];
    [PEXGVU scaleHorizontally:self.B_row withMargin:PEXVal(@"contentMarginLarge")];

    // above the 3-way buttons

    [PEXGVU move:self.L_name above:self.B_row
      withMargin:PEXVal(@"distanceNormal")];
    [PEXGVU centerHorizontally:self.L_name];

    [PEXGVU move:self.L_status above:self.L_name
      withMargin:PEXVal(@"distanceNormal")];
    [PEXGVU centerHorizontally:self.L_status];

    [PEXGVU moveToBottom:self.I_answer withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU moveToRight:self.I_answer withMargin:PEXVal(@"contentMarginLarge")];

    [PEXGVU moveToBottom:self.I_reject withMargin:PEXVal(@"contentMarginLarge")];
    [PEXGVU moveToLeft:self.I_reject withMargin:PEXVal(@"contentMarginLarge")];

    [self showCallIsOn];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.I_answer addAction:self action:@selector(answer:)];
    [self.I_reject addAction:self action:@selector(reject:)];

    [self.B_endCall addTarget:self action:@selector(endCall:)
           forControlEvents:UIControlEventTouchUpInside];
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

    self.I_answer.hidden = !beingCalled;
    self.I_reject.hidden = !beingCalled;
}

- (void) setImage:(UIImage * const) image
{
    [self.I_fancyImage setImage:image];

    [PEXGVU centerHorizontally:self.I_fancyImage];
    [PEXGVU moveToTop:self.I_fancyImage
           withMargin:PEXVal(@"I_logoFromTopPadding")];
}

- (void) setText:(NSString * const) text
        forLabel:(UILabel * const) label
{
    [label setText:text];
    [PEXGVU centerHorizontally:label];
}

- (IBAction) endCall:(id)sender
{
    [self showBeingCalled];
}

- (IBAction) reject:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) answer:(id)sender
{
    [self showCallIsOn];
}

@end
