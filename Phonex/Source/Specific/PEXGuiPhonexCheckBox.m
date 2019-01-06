//
//  PEXGuiPhonexCheckBox.m
//  Phonex
//
//  Created by Matej Oravec on 18/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiPhonexCheckBox.h"

@implementation PEXGuiPhonexCheckBox

- (UIColor *)bgColorNormalStatic
{
    return PEXCol(@"invisible");
}
- (UIColor *)bgColorHighlightStatic
{
    return PEXCol(@"orange_normal");
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];

    self.layer.borderColor = [PEXCol(@"light_gray_low") CGColor];
    self.layer.borderWidth = PEXVal(@"line_width_small");

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [PEXCol(@"light_gray_low") CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_small"));

    const CGSize size = self.frame.size;

    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, 0.0f, size.height);
    CGContextAddLineToPoint(context, size.width, size.height);
    CGContextAddLineToPoint(context, size.width, 0.0f);
    CGContextAddLineToPoint(context, 0.0f, 0.0f);

    CGContextDrawPath(context, kCGPathStroke);
}

@end
