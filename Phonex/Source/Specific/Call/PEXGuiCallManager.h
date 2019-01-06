//
//  PEXGuiCallManager.h
//  Phonex
//
//  Created by Matej Oravec on 15/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPjCall.h"
#import "PEXDbContact.h"

@class PEXGuiCallController;

@interface PEXGuiCallManager : NSObject

+ (PEXGuiCallManager *) instance;

+ (int64_t) getMaxDuration: (NSArray * const) permissions;

- (bool)showCall: (PEXPjCall *) callInfo;

- (bool) showCallOutgoing: (const PEXDbContact * const) contact
          withMaxDuration: (const int64_t) maxDuration;

- (bool) showCallOutgoing: (const PEXDbContact * const) contact;

- (void) unsetCallController: (PEXGuiCallController *) thisOne;
- (void) unsetCallController;
- (void) bringTheCallToFront;

- (void) callTimeWasConsumed: (const int64_t) consumedTimeInSeconds;
- (void) callTimeWasSynchronized: (const int64_t) remainingTime;

@end
