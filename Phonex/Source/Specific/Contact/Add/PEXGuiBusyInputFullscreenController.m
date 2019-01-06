//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiBusyInputFullscreenController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiErrorTextView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiButtonMain.h"

@implementation PEXGuiBusyInputFullscreenController {

}

- (void)initState
{
    _taskInProgress = false;
    _dismissing = false;
}

- (void)initContent
{
    [super initContent];

    self.TV_errorText.textColor = PEXCol(@"red_normal");
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.TV_introText = [[PEXGuiReadOnlyTextView  alloc] init];
    [self.mainView addSubview:self.TV_introText];

    self.TV_errorText = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_errorText];

    self.B_action = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_action];

    self.activityIndicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [self.mainView addSubview:self.activityIndicatorView];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TV_introText];
    [PEXGVU scaleHorizontally:self.TV_errorText];
    [PEXGVU scaleHorizontally:self.B_action withMargin:PEXVal(@"dim_size_large")];
}

- (void) setErrorText: (NSString * const) text
{
    self.TV_errorText.text = text;

    [PEXGVU scaleHorizontally: self.TV_errorText];
    [self.TV_errorText sizeToFit];
    [PEXGVU shakeView: self.mainView];
}

- (void) setAvailable
{
    [self setBusyInternal:false];
}

- (void) setBusy
{
    [self setBusyInternal:true];
}

- (void) setBusyInternal: (const bool) busy
{
    self.TV_errorText.hidden = busy;
    self.activityIndicatorView.hidden = !busy;
    [self.B_action setEnabled:!busy];

    if (busy)
        [self.activityIndicatorView startAnimating];
    else
        [self.activityIndicatorView stopAnimating];
}

-(CGFloat) getTopKeyboardPoint
{
    const CGPoint point = [PEXGVU getAbsolutePosition:self.B_action highestView:nil];
    return point.y + self.B_action.frame.size.height;
}

@end