//
//  PEXGuiBusyInputController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 13/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiController_Protected.h"
#import "PEXGuiErrorTextView.h"
#import "PEXGuiActivityIndicatorView.h"

@interface PEXGuiBusyInputController ()

@property (nonatomic) PEXGuiErrorTextView * TV_errorText;
@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

- (void) setBusyInternal: (const bool) busy;

@end