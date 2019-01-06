//
//  PEXGuiFullArrowDown.m
//  Phonex
//
//  Created by Matej Oravec on 22/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiFullArrowDown.h"

@interface PEXGuiFullArrowDown ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiFullArrowDown

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

    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_medium"));

    CGContextMoveToPoint(context, 0.0f, half);
    CGContextAddLineToPoint(context, half, SZ);
    CGContextAddLineToPoint(context, SZ, half);

    CGContextMoveToPoint(context, half, SZ);
    CGContextAddLineToPoint(context, half, 0.0f);

    CGContextDrawPath(context, kCGPathStroke);
}

@end
