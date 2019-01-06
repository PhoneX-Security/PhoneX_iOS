//
//  PEXCall.h
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXCallListener.h"

#import "PEXPjCallCallbacks.h"

/*
 one direction termination hierarchy

                    terminates on demand    checks for connectivity
[CAll USER (controller)] -> [CALL (with _terminate)] -> [CALL CONNECTION]
 
*/

// PRESENTATION module (voice, sounds, ringing should be here)

#import "PEXSipCodes.h"

@class PEXDbContact;

@interface PEXCall : NSObject<PEXPjCallCallbacks>

- (id) initWithContact: (const PEXDbContact * const) contact;

- (void) end;
- (void) start;

- (void) pickUp;
- (void) reject;

- (void) addListener: (id<PEXCallListener>) listener;
- (PEXDbContact *) contact;

@end
