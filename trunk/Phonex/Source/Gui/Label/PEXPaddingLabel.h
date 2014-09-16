//
//  PEXPaddingLabel.h
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiBaseLabel.h"

@interface PEXPaddingLabel : PEXGuiBaseLabel

- (id) initWithFontColor: (UIColor * const) fontColor
                 bgColor: (UIColor * const) bgColor;

+ (CGFloat) height;

@end
