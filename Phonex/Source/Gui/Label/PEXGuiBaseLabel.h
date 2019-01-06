//
//  PEXGuiLabel.h
//  Phonex
//
//  Created by Matej Oravec on 01/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PEXGuiBaseLabel : UILabel

@property (nonatomic) const CGFloat fontSize;

- (id)initWithFontSize: (const CGFloat) fontSize
             fontColor: (UIColor * const) fontColor
               bgColor: (UIColor * const) bgColor;

- (id)initWithFontSize: (const CGFloat) fontSize
             fontColor: (UIColor * const) fontColor;

- (id)initWithFontSize: (const CGFloat) fontSize;

- (void)sizeToFitMaxWidth: (NSNumber *) maxWidth maxHeight: (NSNumber *) maxHeight;
@end
