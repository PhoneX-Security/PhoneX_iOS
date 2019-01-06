//
//  PEXGuiPresenceLabelController.h
//  Phonex
//
//  Created by Matej Oravec on 19/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLabelController.h"

@protocol PEXGuiProfileDetailClicked

- (void) clicked;

@end

@interface PEXGuiPresenceLabelController : PEXGuiLabelController

- (void) setListener:(id<PEXGuiProfileDetailClicked>)listener;

@end
