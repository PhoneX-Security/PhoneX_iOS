//
//  PEXGuiCallBaseViewController.h
//  Phonex
//
//  Created by Matej Oravec on 03/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLooseController.h"

#import "PEXCallListener.h"
#import "PEXGuiDialogBinaryListener.h"

@class PEXOutgoingCall;
@class PEXIncommingCall;

@interface PEXGuiCallController : PEXGuiLooseController<PEXCallListener, PEXGuiDialogBinaryListener>

@property (nonatomic, assign) int64_t maxCallDurationInSeconds;
@property (nonatomic, assign) bool isUnlimited;

- (void) bringTofront;

- (void)setIsUnlimitedPost:(bool)isUnlimited;

- (BOOL) hasCallEnded;
- (BOOL) dismissEverythingIfCallEnded;

- (id)initWithOutgoingCall: (PEXOutgoingCall *) call;
- (id) initWithIncommingCall: (PEXIncommingCall *) call;

+ (NSString *)getTimeIntervalStringFromTime:(const int64_t)intervalInSeconds;
@end
