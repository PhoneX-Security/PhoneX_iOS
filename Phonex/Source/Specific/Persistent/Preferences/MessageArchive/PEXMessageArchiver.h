//
// Created by Matej Oravec on 31/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentObserver.h"


@interface PEXMessageArchiver : NSObject<PEXContentObserver>

+ (PEXMessageArchiver *) instance;

- (void) stop;
- (void) pause;
- (void) resume;
- (void)setTimerInSeconds: (const NSNumber * const)timeInSeconds;

@end