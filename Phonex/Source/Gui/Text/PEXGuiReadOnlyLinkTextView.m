//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiReadOnlyLinkTextView.h"
#import "UITextView+PEXPaddings.h"


@implementation PEXGuiReadOnlyLinkTextView {

}
- (id)initWithFrame:(CGRect) frame
{
    self = [super initWithFrame:frame];

    self.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
    self.backgroundColor = PEXCol(@"white_normal");
    self.textColor = PEXCol(@"black_normal");

    [self padding];
    self.userInteractionEnabled = YES;
    [self resignFirstResponder];

    return self;
}

- (void) padding
{
    [self setPadding:PEXVal(@"dim_size_medium")];
}

- (void) setPadding: (const CGFloat) padding
{
    self.textInsets = UIEdgeInsetsMake(padding, padding, padding, padding);
}

- (void)setPaddingTop:(const CGFloat)top left:(const CGFloat)left bottom:(const CGFloat)bottom rigth:(const CGFloat)right
{
    self.textInsets = UIEdgeInsetsMake(top, left, bottom, right);
}

- (void)setPaddingNumTop:(NSNumber *)top left:(NSNumber *)left bottom:(NSNumber *)bottom rigth:(NSNumber *)right {
    if (top == nil && left == nil && bottom == nil && right == nil){
        return;
    }

    UIEdgeInsets orig = self.textInsets;
    self.textInsets = UIEdgeInsetsMake(
            top    == nil ? orig.top    : [top floatValue],
            left   == nil ? orig.left   : [left floatValue],
            bottom == nil ? orig.bottom : [bottom floatValue],
            right  == nil ? orig.right  : [right floatValue]
    );
}

@end