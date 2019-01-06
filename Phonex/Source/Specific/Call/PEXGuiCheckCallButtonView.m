//
//  PEXGuiCheckCallButtonView.m
//  Phonex
//
//  Created by Matej Oravec on 25/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiCheckCallButtonView.h"
#import "PEXGuiCallButtonView_Protected.h"

// TODO not reusable design when it comes to check buttons

@interface PEXGuiCheckCallButtonView ()

@property (nonatomic) UIColor * normalColor;
@property (nonatomic) UIColor * highlightColor;
@property (nonatomic) BOOL checked;

@end

@implementation PEXGuiCheckCallButtonView

- (id)initWithImage:(UIView *const)image labelText:(NSString *const)label
{
    self.checked = false;

    self.normalColor = [self bgColorNormalStatic];
    self.highlightColor = [self bgColorHighlightStatic];

    self = [super initWithImage:image labelText:label];

    [self addAction:self action:@selector(check)];

    return self;
}

- (void) check
{
    self.checked = !self.checked;

    UIColor * const tmp = self.normalColor;
    self.normalColor = self.highlightColor;
    self.highlightColor = tmp;
    [self setStateNormal];
}

-(void) setStateNormal
{
    [self setState:self.normalColor];
}

-(void) setStateHighlight
{
    [self setState:self.highlightColor];
}

@end
