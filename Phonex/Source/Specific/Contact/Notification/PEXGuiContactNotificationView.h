//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiRowItemView.h"
#import "PEXGuiStaticDimmer.h"

@class PEXDbContactNotification;


@interface PEXGuiContactNotificationView : PEXGuiRowItemView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>

- (void) initGui;
- (void) applyNotification:  (const PEXDbContactNotification * const) notification;

@end