//
//  PEXGuiFullSizeBusyView.m
//  Phonex
//
//  Created by Matej Oravec on 18/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiFullSizeBusyView.h"

#import "PEXGuiActivityIndicatorView.h"

@interface PEXGuiFullSizeBusyView ()

@property (nonatomic) PEXGuiActivityIndicatorView * indicatorView;

@end

@implementation PEXGuiFullSizeBusyView

- (id) initWithColor: (const UIColor * const) color
{
    self = [super init];

    self.indicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [self addSubview:self.indicatorView];
    self.backgroundColor = color;

    [self.indicatorView startAnimating];

    return self;
}

- (id) init
{
    return [self initWithColor:PEXCol(@"white_normal")];
}

- (void) layoutSubviews
{
    [PEXGVU center:self.indicatorView];
}

@end
