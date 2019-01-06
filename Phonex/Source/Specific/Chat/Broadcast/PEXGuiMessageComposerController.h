//
//  PEXGuiMessageComposerControllerViewController.h
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiMessageComposerController : PEXGuiController

- (void) warningFlash;
- (NSString *) getComposedText;
- (void) setComposedText: (NSString * const) text;

@end
