//
//  PEXGuiTextFIeld.m
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiTextField.h"

@implementation PEXGuiTextField

- (id) init
{
    self = [super init];

    [self setBehavior];
    [self setStyle];

    return self;
}

- (void) setBehavior
{
    // bug for simulators ... if any autocorrection is set then
    // EXC_BAD_ACCESS is thrown
    self.autocorrectionType = UITextAutocorrectionTypeNo;

    // TODO customize style of the clear button
    // TODO add tap animation
    //self.clearButtonMode = UITextFieldViewModeWhileEditing;

    //specific
    self.keyboardAppearance = [PEXTheme getKeyboardAppearance];
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeyDone;
}

- (void) setStyle
{
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.borderStyle = UITextBorderStyleLine;
    [self setBackgroundColor:PEXCol(@"white_normal")];
    self.layer.borderColor = [PEXCol(@"light_gray_low") CGColor];
    self.layer.borderWidth = PEXVal(@"line_width_small");
    self.textColor = PEXCol(@"black_normal");
    [[UITextField appearance] setTintColor:PEXCol(@"black_normal")];

    [self setFontSize: PEXVal(@"dim_size_medium") padding: PEXVal(@"dim_size_medium")];

    /*
     set color for the clear button
     http://stackoverflow.com/questions/10274210/uitextfield-clearbuttonmode-color
     */
}

- (void) setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        [self setBackgroundColor:PEXCol(@"white_normal")];
    }
    else
    {
        [self setBackgroundColor:PEXCol(@"light_gray_high")];
    }

    [super setEnabled:enabled];
}

- (void) setFontSize: (const CGFloat) fontSize padding: (const CGFloat) padding
{
    self.font = [UIFont systemFontOfSize:fontSize];
    _padding = padding;
    self.frame = CGRectMake(0, 0, PEXDefaultVal, fontSize + (2 * padding));
}

- (void) drawPlaceholderInRect:(CGRect)rect
{
    [super drawPlaceholderInRect:rect];

    // iOS 7 and later
    NSDictionary * const attributes = @{NSForegroundColorAttributeName: self.specialOneTimeColor ?
            self.specialOneTimeColor :
            PEXCol(@"light_gray_normal"),
                                        NSFontAttributeName: self.font};
    const CGRect boundingRect = [self.placeholder boundingRectWithSize: rect.size
                                                               options: 0
                                                            attributes: attributes
                                                               context: nil];
    [self.placeholder drawAtPoint:CGPointMake(0, (rect.size.height / 2) -
                                              (boundingRect.size.height / 2))
                   withAttributes: attributes];
}


- (CGRect) textRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.origin.x + _padding, bounds.origin.y,
                      bounds.size.width - _padding, bounds.size.height);
}

- (CGRect) editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end
