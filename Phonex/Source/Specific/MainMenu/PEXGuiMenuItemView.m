//
//  PEXGuiMainMenuItem.m
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiMenuItemView.h"
#import "PEXGuiRowItemViewWithImage_Protected.h"

#import "PEXGuiMenuLine.h"
#import "PEXGuiClassicLabel.h"

@interface PEXGuiMenuItemView ()

@property (nonatomic) UILabel *labelView;

@end

@implementation PEXGuiMenuItemView

- (id)initWithImage:(UIView * const) image labelText:(NSString * const) label
{
    self = [super initWithImage:image];

    self.labelView = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    self.labelView.text = label;
    [self addSubview:self.labelView];

    [self labelView].textColor = PEXCol(@"black_normal");

    return self;
}

- (void) setNotificationColor: (UIColor * const) color
{
    self.labelView.textColor = color;
}

- (void) highlighted
{
    [self setNotificationColor:PEXCol(@"orange_low")];
}

- (void) normal
{
    [self setNotificationColor:PEXCol(@"black_normal")];
}

- (void) setLabelText: (NSString * const) text
{
    self.labelView.text = text;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.labelView];
    self.labelView.frame = CGRectMake([self staticHeight], self.labelView.frame.origin.y,
            self.frame.size.width, self.labelView.frame.size.height);
    //[PEXGVU moveToLeft:self.labelView withMargin:[self staticHeight]];
}

@end