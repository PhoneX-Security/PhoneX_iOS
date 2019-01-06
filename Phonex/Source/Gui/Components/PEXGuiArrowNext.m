//
// Created by Dusan Klinec on 13.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiArrowNext.h"


@interface PEXGuiArrowNext ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiArrowNext {

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
    CGContextAddLineToPoint(context, rect.size.width, half);
    CGContextAddLineToPoint(context, half, rect.size.height);
    CGContextDrawPath(context, kCGPathStroke);
}
/*
- (UIColor *)bgColorNormalStatic {return PEXCol(@"invisible");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"orange_low");}*/

@end