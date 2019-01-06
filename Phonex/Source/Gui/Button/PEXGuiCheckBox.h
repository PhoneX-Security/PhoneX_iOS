//
//  PEXGuiCheckBox.h
//  Phonex
//
//  Created by Matej Oravec on 18/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiClickableView.h"

@interface PEXGuiCheckBox : PEXGuiClickableView

@property (nonatomic, copy) void (^checkBlock)(const bool isChecked);

- (bool) isChecked;
- (void) setChecked: (const bool) checked;

@end
