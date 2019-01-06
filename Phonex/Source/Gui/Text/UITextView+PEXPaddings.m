//
// Created by Dusan Klinec on 02.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "UITextView+PEXPaddings.h"


@implementation UITextView (PEXPaddings)
- (void) setPadding: (const CGFloat) padding
{
    self.textContainerInset = UIEdgeInsetsMake(padding, padding, padding, padding);
}

- (void)setPaddingTop:(const CGFloat)top left:(const CGFloat)left bottom:(const CGFloat)bottom rigth:(const CGFloat)right
{
    self.textContainerInset = UIEdgeInsetsMake(top, left, bottom, right);
}

- (void)setPaddingNumTop:(NSNumber *)top left:(NSNumber *)left bottom:(NSNumber *)bottom rigth:(NSNumber *)right {
    if (top == nil && left == nil && bottom == nil && right == nil){
        return;
    }

    UIEdgeInsets orig = self.textContainerInset;
    self.textContainerInset = UIEdgeInsetsMake(
            top    == nil ? orig.top    : [top floatValue],
            left   == nil ? orig.left   : [left floatValue],
            bottom == nil ? orig.bottom : [bottom floatValue],
            right  == nil ? orig.right  : [right floatValue]
    );
}
@end