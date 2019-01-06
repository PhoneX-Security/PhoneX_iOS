//
// Created by Matej Oravec on 31/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiArrowBack.h"

@interface PEXGuiArrowBack ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiArrowBack {

}

- (id) initWithColor: (UIColor * const) color
{
    self = [super init];

    const CGFloat size = PEXVal(@"dim_size_medium");

    self.color = color;
    [PEXGVU setSize: self x:size / 2 y: size];
    self.backgroundColor = PEXCol(@"invisible");

    return self;
}

- (void)drawRect:(CGRect)rect
{

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_medium"));

    const CGFloat half = rect.size.height / 2;
    CGContextMoveToPoint(context, half, 0.0f);
    CGContextAddLineToPoint(context, 0.0f, half);
    CGContextAddLineToPoint(context, half, rect.size.height);
    CGContextDrawPath(context, kCGPathStroke);
}
/*
- (UIColor *)bgColorNormalStatic {return PEXCol(@"invisible");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"orange_low");}*/

@end