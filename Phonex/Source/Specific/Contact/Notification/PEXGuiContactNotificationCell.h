//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiItemComposedView;

@interface PEXGuiContactNotificationCell : UICollectionViewCell

- (UIView *) getSubview;

// TODO move to protected
@property (nonatomic) PEXGuiItemComposedView * subview;
- (void) initSubview;

@end