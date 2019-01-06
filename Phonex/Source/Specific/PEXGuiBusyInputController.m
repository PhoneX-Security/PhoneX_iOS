//
//  PEXGuiBusyInputController.m
//  Phonex
//
//  Created by Matej Oravec on 13/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiBusyInputController.h"
#import "PEXGuiBusyInputController_Protected.h"

#import "PEXGuiControllerDecorator.h"
#import "PEXGuiActivityIndicatorView.h"


@interface PEXGuiBusyInputController ()

@end

@implementation PEXGuiBusyInputController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.TV_errorText = [[PEXGuiErrorTextView alloc] init];
    [self.mainView addSubview:self.TV_errorText];

    self.activityIndicatorView = [[PEXGuiActivityIndicatorView alloc] init];

    [self.mainView addSubview:self.activityIndicatorView];
}

- (void) initContent
{
    [super initContent];
}

- (void) initBehavior
{
    [super initBehavior];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TV_errorText withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToBottom:self.TV_errorText
              withMargin:PEXVal(@"dim_size_large") + (2 * PEXVal(@"dim_size_medium"))];

    [PEXGVU moveToBottom:self.activityIndicatorView
              withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerHorizontally:self.activityIndicatorView];
}

- (void)setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    [PEXGVU setSize:
     self.mainView
                  x:
     parent.subviewMaxWidth
                  y:
     (2 * PEXVal(@"dim_size_large")) +  // upper and lower margin
     (2 * PEXVal(@"dim_size_medium"))]; // 2 rows of text error
}

- (void) setErrorText: (NSString * const) text
{
    self.TV_errorText.text = text;

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
    if (busy)
        [self.activityIndicatorView startAnimating];
    else
        [self.activityIndicatorView stopAnimating];
}

@end
