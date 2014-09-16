//
//  PEXTestingController.m
//  Phonex
//
//  Created by Matej Oravec on 26/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTestingController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLogin.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiViewUtils.h"
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
#import "PEXGuiProgressController.h"
#import "PEXGuiCallController.h"
#import "PEXGuiDialogProgressCanceller.h"
#import "PEXGuiViewRow.h"
#import "PEXGuiButtonWithImageCall.h"

#import "PEXGuiUserAction.h"
#import "PEXGuiNavigationController.h"

#import "PEXTaskFake.h"

@interface PEXTestingController ()

@property (nonatomic) PEXGuiClassicLabel * L_description;
@property (nonatomic) PEXGuiButtonMain * B_showWindow;
@property (nonatomic) PEXGuiButtonMain * B_showWindowNoTitle;
@property (nonatomic) PEXGuiButtonMain * B_showDialog;
@property (nonatomic) PEXGuiButtonMain * B_showProgress;
@property (nonatomic) PEXGuiButtonMain * B_showProgressInWindow;
@property (nonatomic) PEXGuiButtonMain * B_showCalling;
@property (nonatomic) PEXGuiButtonMain * B_showRowButtons;
@property (nonatomic) PEXGuiButtonMain * B_showNavigation;

@property (nonatomic) UITableView * TV_list;

@end

@implementation PEXTestingController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.TV_list = [[UITableView alloc] init];


    self.L_description = [[PEXGuiClassicLabel alloc]
                          initWithFontSize:PEXVal(@"fontSizeMedium")
                          fontColor:PEXCol(@"grayHigh")];
    [self.mainView addSubview:self.L_description];

    self.B_showWindow = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showWindow];

    self.B_showWindowNoTitle = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showWindowNoTitle];

    self.B_showDialog = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showDialog];

    self.B_showProgress = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showProgress];

    self.B_showProgressInWindow = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showProgressInWindow];

    self.B_showCalling = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showCalling];

    self.B_showRowButtons = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showRowButtons];

    self.B_showNavigation = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_showNavigation];

}

- (void) initContent
{
    [super initContent];

    [self.L_description setText:@"testing area"];
    [self.B_showWindow setTitle:@"show window" forState:UIControlStateNormal];
    [self.B_showWindowNoTitle setTitle:@"show window no title" forState:UIControlStateNormal];
    [self.B_showDialog setTitle:@"show dialog" forState:UIControlStateNormal];
    [self.B_showProgress setTitle:@"show progress" forState:UIControlStateNormal];
    [self.B_showProgressInWindow setTitle:@"show progress in window" forState:UIControlStateNormal];
    [self.B_showCalling setTitle:@"show calling base" forState:UIControlStateNormal];
    [self.B_showRowButtons setTitle:@"show buttons in row" forState:UIControlStateNormal];
    [self.B_showNavigation setTitle:@"show navigation" forState:UIControlStateNormal];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_showWindow addTarget:self action:@selector(showWindow:)
       forControlEvents:UIControlEventTouchUpInside];

    [self.B_showWindowNoTitle addTarget:self action:@selector(showWindowNoTitle:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.B_showDialog addTarget:self action:@selector(showDialog:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.B_showProgress addTarget:self action:@selector(showProgress:)
                forControlEvents:UIControlEventTouchUpInside];

    [self.B_showProgressInWindow addTarget:self action:@selector(showProgressInWindow:)
                  forControlEvents:UIControlEventTouchUpInside];

    [self.B_showCalling addTarget:self action:@selector(showCalling:)
                          forControlEvents:UIControlEventTouchUpInside];

    [self.B_showRowButtons addTarget:self action:@selector(showRowButtons:)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.B_showNavigation addTarget:self action:@selector(showNavigation:)
                    forControlEvents:UIControlEventTouchUpInside];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU moveToTop:self.L_description withMargin:20.0f];
    [PEXGVU centerHorizontally:self.L_description];

    [PEXGVU move:self.B_showWindow below:self.L_description withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showWindow withMargin:10.0f];

    [PEXGVU move:self.B_showWindowNoTitle below:self.B_showWindow withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showWindowNoTitle withMargin:10.0f];

    [PEXGVU move:self.B_showDialog below:self.B_showWindowNoTitle withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showDialog withMargin:10.0f];

    [PEXGVU move:self.B_showProgress below:self.B_showDialog withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showProgress withMargin:10.0f];

    [PEXGVU move:self.B_showProgressInWindow below:self.B_showProgress withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showProgressInWindow withMargin:10.0f];

    [PEXGVU move:self.B_showCalling below:self.B_showProgressInWindow withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showCalling withMargin:10.0f];

    [PEXGVU move:self.B_showRowButtons below:self.B_showCalling withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showRowButtons withMargin:10.0f];

    [PEXGVU move:self.B_showNavigation below:self.B_showRowButtons withMargin:10.0f];
    [PEXGVU scaleHorizontally:self.B_showNavigation withMargin:10.0f];
}

- (IBAction) showWindow:(id)sender
{
     PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:PEXStr(@"loremIpsum")];
     PEXGuiDialogDoubleCloser * const visitor = [[PEXGuiDialogDoubleCloser alloc] initWithController:txt];
     PEXGuiController * const vc =
     [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];
     PEXGuiWindowWithTitleController * const ud = [[PEXGuiWindowWithTitleController alloc] initWithViewController:vc];

    [ud prepareOnScreen:self];
    [ud show:self];
}

- (IBAction) showWindowNoTitle:(id)sender
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:PEXStr(@"loremIpsum")];
    PEXGuiDialogDoubleCloser * const visitor = [[PEXGuiDialogDoubleCloser alloc] initWithController:txt];
    PEXGuiController * const vc =
    [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];
    PEXGuiWindowController * const ud = [[PEXGuiWindowController alloc] initWithViewController:vc];

    [ud prepareOnScreen:self];
    [ud  show:self];
}

- (IBAction) showDialog:(id)sender
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:PEXStr(@"loremIpsum")];
    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithController:txt];
    PEXGuiController * const vc =
    [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    [vc prepareOnScreen:self];
    [vc show:self];
}

- (IBAction) showProgress:(id)sender
{

    PEXTaskFake * const task = [[PEXTaskFake alloc] init];
    PEXGuiProgressController * progress = [[PEXGuiProgressController alloc] initWithTask:task];

    PEXGuiDialogProgressCanceller * const canceller = [[PEXGuiDialogProgressCanceller alloc] initWithController:progress Task:task];

    PEXGuiController * const vc =
    [[PEXGuiDialogUnaryController alloc] initWithVisitor:canceller];

    [vc prepareOnScreen:self];
    [vc show:self];
}

- (IBAction) showProgressInWindow:(id)sender
{

    PEXTaskFake * const task = [[PEXTaskFake alloc] init];
    PEXGuiProgressController * progress = [[PEXGuiProgressController alloc] initWithTask:task];

    PEXGuiDialogProgressCanceller * const canceller = [[PEXGuiDialogProgressCanceller alloc] initWithController:progress Task:task];

    PEXGuiController * const vc =
    [[PEXGuiDialogUnaryController alloc] initWithVisitor:canceller];

    PEXGuiWindowController * const ud = [[PEXGuiWindowController alloc] initWithViewController:vc];

    [ud prepareOnScreen:self];
    [ud  show:self];
}

- (IBAction) showCalling:(id)sender
{
    PEXGuiCallController * controller = [[PEXGuiCallController alloc] init];

    [controller prepareOnScreen:self];
    [controller show:self];
}

- (IBAction) showRowButtons:(id)sender
{
    PEXGuiUserAction * const main = [[PEXGuiUserAction alloc] init];
    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithController:main];
    PEXGuiController * const vc =
    [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];
    PEXGuiWindowWithTitleController * const ud = [[PEXGuiWindowWithTitleController alloc] initWithViewController:vc];

    [ud prepareOnScreen:self];
    [ud show:self];
}

- (IBAction) showNavigation:(id)sender
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:PEXStr(@"loremIpsum")];

    PEXGuiNavigationController * vc = [[PEXGuiNavigationController alloc] initWithViewController:txt title:@"ahoj"];

    [vc prepareOnScreen:self];
    [vc show:self];
}

@end
