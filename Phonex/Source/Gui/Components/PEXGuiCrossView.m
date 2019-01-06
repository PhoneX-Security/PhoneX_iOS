//
// Created by Matej Oravec on 30/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCrossView.h"

@interface PEXGuiCrossView ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiCrossView {

}

- (id) initWithColor: (UIColor * const) color;
{
    self = [super init];

    const CGFloat SZ = PEXVal(@"dim_size_medium");

    self.color = color;
    [PEXGVU setSize: self x:SZ y: SZ];
    self.backgroundColor = PEXCol(@"invisible");

    return self;
}

- (void)drawRect:(CGRect)rect
{
    const CGFloat SZ = rect.size.width;

    CGContextRef context = UIGraphicsGetCurrentContext();

    const CGFloat half = (((int)SZ) / 2);

    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_medium"));

    CGContextMoveToPoint(context, 0.0f, half);
    CGContextAddLineToPoint(context, SZ, half);

    CGContextMoveToPoint(context, half, 0.0f);
    CGContextAddLineToPoint(context, half, SZ);

    CGContextDrawPath(context, kCGPathStroke);
}
/*
- (UIColor *)bgColorNormalStatic {return PEXCol(@"invisible");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"orange_low");}*/

@end