//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTTAttributedLabel.h"


@interface PEXGuiReadOnlyLinkTextView : TTTAttributedLabel
- (void) padding;
- (void) setPadding: (const CGFloat) padding;
- (void) setPaddingTop:(const CGFloat)top left:(const CGFloat)left bottom:(const CGFloat)bottom rigth:(const CGFloat)right;
- (void) setPaddingNumTop:(NSNumber *)top left:(NSNumber *)left bottom:(NSNumber *)bottom rigth:(NSNumber *)right;
@end