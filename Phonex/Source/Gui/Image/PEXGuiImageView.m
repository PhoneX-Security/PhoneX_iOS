//
//  PEXGuiImageView.m
//  Phonex
//
//  Created by Matej Oravec on 05/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiImageView.h"

@implementation PEXGuiImageView

- (id) initWithImage: (UIImage * const) image
{
    self = [super initWithImage:image];

    [self setImage:image];

    return self;
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image];
    [self sizeToFit];
}

-(void) setStateNormal
{
    [self setState:1.0f];
}

-(void) setStateHighlight
{
    [self setState:0.5f];
}

-(void) setState: (const CGFloat) highlight
{
    self.alpha = highlight;
}

@end
