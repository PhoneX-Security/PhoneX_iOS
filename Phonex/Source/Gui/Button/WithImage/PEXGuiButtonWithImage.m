//
//  PEXGuiButtonWithImage.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonWithImage.h"
#import "PEXGuiButtonWithImage_Protected.h"

@interface PEXGuiButtonWithImage ()

@end

@implementation PEXGuiButtonWithImage

- (id)initWithImage:(UIView * const) image
{
    return [self initWithImage:image labelText:nil fontSize:PEXVal(@"dim_size_medium")];
}

- (id)initWithImage:(UIView * const) image labelText:(NSString * const) label
{
    return [self initWithImage:image labelText:label fontSize:PEXVal(@"dim_size_medium")];
}

- (id)initWithImage:(UIView * const) image labelText:(NSString * const) label
           fontSize:(const CGFloat) fontSize
{
    self = [super init];

    self.userInteractionEnabled = YES;

    self.imageView = image;
    [self addSubview:self.imageView];

    self.labelView = [[PEXGuiClassicLabel alloc] initWithFontSize:fontSize];
    self.labelView.text = label;
    self.labelView.textColor = [self labelColor];
    [self addSubview:self.labelView];

    [self setStateNormal];

    return self;
}

- (UIColor *)bgColorNormalStatic { return PEXCol(@"white_normal"); }
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"light_orange_normal"); }
- (const UIColor *) labelColor{return PEXCol(@"black_normal");}

@end
