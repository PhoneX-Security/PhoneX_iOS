//
//  PEXGuiBusyInputController.h
//  Phonex
//
//  Created by Matej Oravec on 13/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiBusyInputController : PEXGuiController

- (void) setErrorText: (NSString * const) text;

- (void) setBusy;
- (void) setAvailable;

@end
