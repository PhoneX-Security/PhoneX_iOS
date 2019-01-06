//
//  PEXGuiCheck.m
//  Phonex
//
//  Created by Matej Oravec on 04/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiTick.h"

@interface PEXGuiTick ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiTick

- (id) initWithColor: (UIColor * const) color;
{
    self = [super init];

    self.color = color;
    self.backgroundColor = PEXCol(@"invisible");

    return self;
}

- (void)drawRect:(CGRect)rect
{
    const CGContextRef context = UIGraphicsGetCurrentContext();

    static const CGFloat offset = 4.0f;
    const CGFloat size = self.frame.size.width;
    const CGFloat half = (((int)size) / 2);

    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, size / 10.0f);

    CGContextMoveToPoint(context, 0.0f + offset, half);
    CGContextAddLineToPoint(context, half - (half / 3.0f), size - offset);
    CGContextAddLineToPoint(context, size - offset, 0.0f + offset);

    CGContextDrawPath(context, kCGPathStroke);
}

@end
