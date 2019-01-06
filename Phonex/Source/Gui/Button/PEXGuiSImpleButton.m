//
//  PEXGuiSImpleButton.m
//  Phonex
//
//  Created by Matej Oravec on 02/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSImpleButton.h"
#import "PEXGuiSimpleButton_Protected.h"

#import "PEXGuiClassicLabel.h"

@implementation PEXGuiSImpleButton

- (id)init
{
    return [self initWithText:@""];
}

- (id)initWithText:(NSString * const) text
{
    return [self initWithText:text fontSize:PEXVal(@"dim_size_medium")];
}

- (id)initWithText:(NSString * const) text fontSize:(const CGFloat) fontSize
{
    self = [super init];

    self.userInteractionEnabled = YES;

    self.L_text = [[PEXGuiClassicLabel alloc] initWithFontSize:fontSize];
    self.L_text.text = text;
    self.L_text.textColor = [self textColor];
    [self addSubview:self.L_text];

    [self setStateNormal];

    return self;
}

- (void) setText: (NSString * const) text
{
    self.L_text.text = text;
    [PEXGVU center:self.L_text];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU center:self.L_text];
}

- (UIColor *)bgColorNormalStatic {return nil;}
- (UIColor *)bgColorHighlightStatic {return nil;}
- (const UIColor *) textColor{return PEXCol(@"black_normal");}

@end
