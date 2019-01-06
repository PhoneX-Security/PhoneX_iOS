//
//  PEXGuiCallLogItemView.h
//  Phonex
//
//  Created by Matej Oravec on 20/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiMenuItemView.h"
#import "PEXGuiStaticDimmer.h"
#import "PEXDbContact.h"
#import "PEXGuiCallLog.h"

@interface PEXGuiCallLogItemView : PEXGuiRowItemView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>

- (id)initWithCallLog:(const PEXGuiCallLog * const) callLog;
- (void) initGuiStuff;
- (void) applyGuiCallLog: (const PEXGuiCallLog * const) chat;

+ (bool) callLog: (const PEXDbCallLog * const) c1
     needsUpdate: (const PEXDbCallLog * const) c2;
- (void) applyCallLog: (const PEXDbCallLog * const) callLog;

+ (bool) contact: (const PEXDbContact * const) m1
     needsUpdate: (const PEXDbContact * const) m2;
- (void) applyContact: (const PEXDbContact * const) contact;

- (void) highlighted;
- (void) normal;

@end
