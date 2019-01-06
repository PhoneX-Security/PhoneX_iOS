//
//  PEXGuiPinLockManager.h
//  Phonex
//
//  Created by Matej Oravec on 01/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiDialogBinaryListener.h"

#import "PEXGuiPinLockController.h"

@interface PEXGuiPinLockManager : NSObject<PEXPinLockListener>

@property (nonatomic) bool worksOutOfLogin;
@property (nonatomic, assign) bool beyondPinLock;

+ (PEXGuiPinLockManager *) instance;
- (PEXGuiPinLockController *) showPinLockOnBecomingActive: (const uint64_t) seconds
                                               forLanding: (UIViewController * const) landing
                                                forceShow: (const bool) force;;
- (void) hidePinLock;
- (void) hidePinLockForGoingToBackground;
- (void) resetTrigger;

- (void) bringToFront;

@end
