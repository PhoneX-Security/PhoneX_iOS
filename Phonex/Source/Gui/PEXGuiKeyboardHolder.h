//
//  PEXGuiKeyboardHolder.h
//  Phonex
//
//  Created by Matej Oravec on 19/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXGuiKeyboardHolder : NSObject

- (void) setCurrent: (PEXGuiController * const) current;
- (PEXGuiController *) getCurrent;
- (void) stopEditing;
+ (PEXGuiKeyboardHolder*) instance;

@end
