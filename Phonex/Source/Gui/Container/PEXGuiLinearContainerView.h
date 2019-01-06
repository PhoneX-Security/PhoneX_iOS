//
//  PEXGuiContainerView.h
//  Phonex
//
//  Created by Matej Oravec on 17/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiContainer.h"

// TODO orientation
@interface PEXGuiLinearContainerView : UIView<PEXGuiLinearContainer>
- (UIView *) getViewAtIndex:(const NSUInteger) index;
@end
