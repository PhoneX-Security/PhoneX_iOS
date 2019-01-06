//
//  PEXGuiNegCrossView.m
//  Phonex
//
//  Created by Matej Oravec on 22/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiNegCrossView.h"

@interface PEXGuiNegCrossView ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiNegCrossView

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

    CGContextSetStrokeColorWithColor(context, [self.color CGColor]);
    CGContextSetLineWidth(context, PEXVal(@"line_width_medium"));

    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, SZ, SZ);

    CGContextMoveToPoint(context, SZ, 0.0f);
    CGContextAddLineToPoint(context, 0.0f, SZ);

    CGContextDrawPath(context, kCGPathStroke);
}
/*
 - (UIColor *)bgColorNormalStatic {return PEXCol(@"invisible");}
 - (UIColor *)bgColorHighlightStatic {return PEXCol(@"orange_low");}*/

@end
