//
//  PEXGuiContactsItemComposed.h
//  Phonex
//
//  Created by Matej Oravec on 02/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiDeleteItemView.h"
#import "PEXGuiStaticDimmer.h"

@interface PEXGuiItemComposedView : UIView
- (id) initWithView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer> *) view;
- (void) applyView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer> *) view;
- (UIView *) getView;
- (PEXGuiDeleteItemView *) getDeleteView;

- (void) reset;

@end
