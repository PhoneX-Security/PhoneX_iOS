//
// Created by Matej Oravec on 01/11/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXGuiStaticDimmer;

@interface PEXGuiHorizontalPanRecognizerHelper : NSObject

- (id) initWithView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>  * const) view
             maxPan: (const CGFloat) maxPan;

- (void) reset;

@end