//
//  PEXGuiDetailView.h
//  Phonex
//
//  Created by Matej Oravec on 12/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiRowItemView.h"

@interface PEXGuiDetailView : PEXGuiRowItemView

- (void) setName: (NSString * const) name;
- (void) setValue: (NSString * const) value;
- (void) setValue: (NSString * const) value fontColor: (UIColor *) fontColor;
- (void) setAttributedValue: (NSAttributedString *) attributedValue;
- (void) multiLineValue: (BOOL) multiline;

- (void) highlightValue;
- (void) dehighlightValue;

- (void) setEnabledLook:(const bool)enabled;
+ (CGFloat) staticHeight;

@end
