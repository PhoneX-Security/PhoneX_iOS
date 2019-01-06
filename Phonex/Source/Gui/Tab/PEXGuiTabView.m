//
//  PEXGuiTabView.m
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiTabView.h"
#import "PEXGuiCentricButtonView_Protected.h"

@interface PEXGuiTabView ()

@property (nonatomic) UIView * highlightImageView;

@end

@implementation PEXGuiTabView

- (id)initWithImage:(UIView* const) image labelText:(NSString * const) label highlightImage:(UIView * const) hightlightImage;
{
    self = [super initWithImage:image labelText:label];

    self.highlightImageView = hightlightImage;
    [self addSubview:self.highlightImageView];

    [self setEnabled:true];

    return self;
}

- (void) setEnabled: (const bool) enabled
{
    [super setEnabled:enabled];

    // TODO wtf logic
    [self.imageView setHidden:!enabled];
    [self.highlightImageView setHidden:enabled];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU setPosition:self.highlightImageView
                      x:self.imageView.frame.origin.x y:self.imageView.frame.origin.y];
}


- (CGFloat) getMoveSizeImage
{
    return self.labelView.frame.size.height / 2.0f;
}

- (CGFloat) getMoveSizeLabel
{
    return PEXVal(@"dim_size_nano");
}

// TODO make it static with dispatch_once
- (UIColor *) bgColorNormalStatic {return PEXCol(@"light_gray_high");}
// TODO light_orange_normal as highlight color when the bottom click is solved

- (UIColor *) bgColorHighlightStatic {return PEXCol(@"light_gray_high");}
/// because it is always at the bottom and there is
// the glitch with control center

- (UIColor *) bgColorDisabledStatic {return PEXCol(@"light_gray_high");}
- (const UIColor *) labelColor{return PEXCol(@"light_gray_low");}

@end
