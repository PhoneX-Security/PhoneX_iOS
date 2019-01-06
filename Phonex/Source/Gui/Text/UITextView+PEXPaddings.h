//
// Created by Dusan Klinec on 02.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UITextView (PEXPaddings)
- (void) setPaddingTop: (const CGFloat) top left: (const CGFloat) left bottom: (const CGFloat) bottom rigth: (const CGFloat) right;
- (void) setPaddingNumTop: (NSNumber *) top left: (NSNumber *) left bottom: (NSNumber *) bottom rigth: (NSNumber *) right;
- (void) setPadding: (const CGFloat) padding;
@end