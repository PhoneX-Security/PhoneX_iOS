//
//  PEXPaddingLabel.m
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXPaddingLabel.h"
#import "PEXPaddingLabel_Protected.h"

@implementation PEXPaddingLabel

- (id) initWithFontColor: (UIColor * const) fontColor
                 bgColor: (UIColor * const) bgColor
{
    self = [super initWithFontSize:[self fontSize] fontColor:fontColor
                           bgColor:bgColor];

    return self;
}

- (CGFloat) fontSize
{
    return 0.0f;
}

- (CGFloat) padding
{
    return 0.0f;
}

+ (CGFloat) height
{
    return 0.0f + (2.0f * 0.0f);
}

- (void) setText:(NSString *)text
{
    [super setText:text];

    [self sizeToFit];

    // TODO changing width?
    const CGFloat padding = 2 * [self padding];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                            self.frame.size.width + padding,
                            [self fontSize] + padding);
}

@end
