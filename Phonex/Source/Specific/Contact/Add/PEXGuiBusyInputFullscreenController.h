//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiErrorTextView;
@class PEXGuiActivityIndicatorView;
@class PEXGuiReadOnlyTextView;
@class PEXGuiButtonMain;


@interface PEXGuiBusyInputFullscreenController : PEXGuiController
{
    volatile bool _taskInProgress;
    volatile bool _dismissing;
}

@property (nonatomic) PEXGuiReadOnlyTextView * TV_introText;
@property (nonatomic) PEXGuiReadOnlyTextView  * TV_errorText;
@property (nonatomic) PEXGuiButtonMain * B_action;

@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

- (void) setBusyInternal: (const bool) busy;
- (void) setErrorText: (NSString * const) text;
- (void) setAvailable;
- (void) setBusy;

@end