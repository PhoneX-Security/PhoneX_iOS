//
//  PEXGuiSpecialControllersManager.h
//  Phonex
//
//  Created by Matej Oravec on 02/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXGuiShieldManager : NSObject

- (void) bringToFront;
- (void) showShield;
- (void) hideShield;

- (void) preDismissVictims;
- (void) postDismissVictims;
- (void) dimissVictims;

- (void) addVictim: (UIViewController * const) victim;
- (void) removeVictim: (UIViewController * const) victim;

+ (PEXGuiShieldManager *) instance;

@end
