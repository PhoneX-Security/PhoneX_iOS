//
//  PEXGuiArrowDown.m
//  Phonex
//
//  Created by Matej Oravec on 16/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiArrowDown.h"

@interface PEXGuiArrowDown ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiArrowDown

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
    const CGFloat SZ = rect.size.height;

    CGContextRef context = UIGraphicsGetCurrentContext();

    const CGFloat half = (((int)SZ) / 2);
    const CGFloat quarter = half / 2.0f;

    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_medium"));

    CGContextMoveToPoint(context, 0.0f, quarter);
    CGContextAddLineToPoint(context, half, quarter + half);
    CGContextAddLineToPoint(context, SZ, quarter);

    //CGContextMoveToPoint(context, half, SZ);
    //CGContextAddLineToPoint(context, half, 0.0f);

    CGContextDrawPath(context, kCGPathStroke);
}

@end
