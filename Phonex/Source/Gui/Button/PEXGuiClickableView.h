//
//  PEXGuiCLickableView.h
//  Phonex
//
//  Created by Matej Oravec on 02/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiClickInterface.h"

typedef void (^ActionBlock)();

@interface PEXGuiClickableView : UIView<PEXGuiBlockExecutor, PEXGuiSelectorExecutor>

// must be called after all recognizrs are added
- (bool) enabled;
- (void) setEnabled: (const bool) enabled;

//-(void) handleControlEvent:(UIControlEvents)event
//                 withBlock:(ActionBlock) action;


@end
