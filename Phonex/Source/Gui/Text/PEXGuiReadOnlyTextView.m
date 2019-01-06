//
//  PEXGuiReadOnlyTextView.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiTextView_Protected.h"
#import "UITextView+PEXPaddings.h"

@implementation PEXGuiReadOnlyTextView

- (id)init
{
    self = [super init];

    self.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
    self.backgroundColor = PEXCol(@"white_normal");
    self.textColor = PEXCol(@"black_normal");

    [self padding];

    self.editable = NO;
    self.scrollEnabled = YES;
    self.userInteractionEnabled = YES;
    [self resignFirstResponder];

    return self;
}

- (void) padding
{
    [self setPadding:PEXVal(@"dim_size_medium")];
}

- (void)sizeToFit
{
    [super sizeToFit];

    [self.textContainer setSize:self.frame.size];
}

- (void)sizeToFitMaxHeight: (CGFloat) maxHeight {
    [super sizeToFit];
    [self.textContainer setSize:self.frame.size];

    if (self.frame.size.height > maxHeight){
        [PEXGVU setHeight:self to:maxHeight];
    }
}


@end
