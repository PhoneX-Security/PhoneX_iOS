//
// Created by Matej Oravec on 29/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiRowItemView.h"


@interface PEXGuiTicker : PEXGuiRowItemView
- (void) setTitle: (NSString * const) label;
- (void) setLabel: (NSString * const) label;
- (void) setChecked: (const bool) checked;
- (bool) isChecked;

- (instancetype)initWithDisplayTitle:(BOOL)displayTitle;
+ (instancetype)tickerWithDisplayTitle:(BOOL)displayTitle;

@end