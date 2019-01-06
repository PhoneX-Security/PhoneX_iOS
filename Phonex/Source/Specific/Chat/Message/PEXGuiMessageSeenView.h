//
// Created by Matej Oravec on 29/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiMessageSeenView : UICollectionReusableView

- (void) setDate: (const NSDate * const) date;
+ (CGFloat) staticHeight;

@end