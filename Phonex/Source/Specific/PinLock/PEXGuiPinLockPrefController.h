//
//  PEXGuiPinLockPrefController.h
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"
#import "PEXPreferenceChangedListener.h"


@interface PEXGuiPinLockPrefController : PEXGuiController<PEXPreferenceChangedListener>

+ (NSString *) getTriggerTimeDescription: (const int)seconds;

@end
