//
//  PEXGuiCheckBox.m
//  Phonex
//
//  Created by Matej Oravec on 18/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCheckBox.h"
#import "PEXGuiClickableHighlightedView_Protected.h"

#import "PEXGuiTick.h"

@interface PEXGuiCheckBox()
{
    @private
    bool _checked;
}

@property (nonatomic) PEXGuiTick * checkView;

@end

@implementation PEXGuiCheckBox

- (id)init
{
    self = [super init];

    self.checkView = [[PEXGuiTick alloc] initWithColor:PEXCol(@"orange_normal")];
    [self addSubview:self.checkView];

    [self addAction:self action:@selector(check)];

    self.backgroundColor = PEXCol(@"invisible");

    _checked = true;
    [self setChecked:false];

    return self;
}

- (bool) isChecked
{
    return _checked;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.checkView];
}

- (void) check
{
    _checked = !_checked;

    [self.checkView setHidden: !_checked];
    if (self.checkBlock)
        self.checkBlock(_checked);
}

- (void) setChecked: (const bool) checked
{
    if (_checked != checked)
        [self check];
}

@end