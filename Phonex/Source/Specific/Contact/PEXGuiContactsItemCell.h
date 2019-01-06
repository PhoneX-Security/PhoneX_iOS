//
// Created by Matej Oravec on 17/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiItemComposedView;

@interface PEXGuiContactsItemCell : UICollectionViewCell


- (UIView *) getSubview;

// TODO move to protected
@property (nonatomic) PEXGuiItemComposedView * subview;
- (void) initSubview;

@end