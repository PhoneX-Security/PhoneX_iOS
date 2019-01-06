//
//  PEXGuiImageClickableView.h
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiImageView.h"

#import "PEXGuiClickInterface.h"

@interface PEXGuiImageClickableView : PEXGuiImageView<PEXGuiSelectorExecutor>

- (bool) enabled;
- (void) setEnabled: (const bool) enabled;

@end
