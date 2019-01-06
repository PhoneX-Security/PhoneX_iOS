//
//  PEXGuiNotifiedTabView.m
//  Phonex
//
//  Created by Matej Oravec on 05/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiNotifiedTabView.h"
#import "PEXGuiCentricButtonView_Protected.h"


#import "PEXGuiNotificationCounterView.h"

// TODO more general for different : message, all, phone, notification, etc.

@interface PEXGuiNotifiedTabView ()

@end

@implementation PEXGuiNotifiedTabView

- (id)initWithImage:(UIView* const) image labelText:(NSString * const) label highlightImage:(UIView * const) hightlightImage;
{
    self = [super initWithImage:image labelText:label highlightImage:hightlightImage];


    PEXGuiNotificationCounterView * const counter = [[PEXGuiNotificationCounterView alloc] init];
    self.counter = counter;
    [self addSubview:counter];
    // TODO: currently unregistered by logout
    [self registerCounter];

    return self;
}

- (void) registerCounter
{
    //abstract
}

- (void) unregisterCounter
{
    //abstract
}

- (void) dealloc
{
    [self unregisterCounter];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [PEXGVU move:self.counter rightOf:self.imageView withMargin:PEXVal(@"dim_size_nano")];
    [PEXGVU set:self.counter y: self.imageView.frame.origin.y];
}

@end
