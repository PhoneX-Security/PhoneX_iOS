//
//  PEXGuiTextController.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiTextController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiControllerDecorator.h"

@interface PEXGuiTextController ()

@property (nonatomic) NSString * text;
@property (nonatomic) NSAttributedString * attributedText;
@property (nonatomic) PEXGuiReadOnlyTextView * textView;

@end

@implementation PEXGuiTextController

- (id) init
{
    return [self initWithText:PEXDefaultStr];
}

- (id) initWithText: (NSString * const) text
{
    self = [super init];

    self.text = text;

    return self;
}

- (id) initWithAttributedText: (NSAttributedString * const) text
{
    self = [super init];

    self.attributedText = text;

    return self;
}

/*
- (UIView *) getMainView
{
    return [[PEXGuiReadOnlyTextView alloc] init];
}*/

- (void) initGuiComponents
{
    //self.textView = (PEXGuiReadOnlyTextView *) self.mainView;

    self.textView = [[PEXGuiReadOnlyTextView alloc] init];;
    [self.mainView addSubview:self.textView];
}

- (void) initContent
{
    if (self.attributedText)
        [self.textView setAttributedText:self.attributedText];
    else
        [self.textView setText:self.text];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    // INFO: UITExtView has obviosly problem being the root view of the controller
    // but as a subview the scrolling works fine

    [PEXGVU setWidth: self.textView to: [parent subviewMaxWidth]];
    [self.textView sizeToFit];
    [PEXGVU setWidth: self.mainView to: self.textView.frame.size.width];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    const CGFloat textHeight = self.textView.frame.size.height;

    if (textHeight > maxHeight)
    {
        [PEXGVU setHeight:self.mainView to:maxHeight];
        [PEXGVU setHeight: self.textView to: maxHeight];
    }
    else
    {
        [PEXGVU setHeight:self.mainView to: textHeight];
    }

    // required
    self.textView.scrollEnabled = NO;
    self.textView.scrollEnabled = YES;
}

@end
