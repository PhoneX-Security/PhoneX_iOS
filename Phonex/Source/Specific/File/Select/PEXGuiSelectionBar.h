//
//  PEXGuiSelectionBar.h
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiClickableView.h"

@interface PEXGuiSelectionBar : UIView

@property (nonatomic) PEXGuiClickableView * B_next;
@property (nonatomic) PEXGuiClickableView * B_clearSelection;

- (id) initWithRightActionImage: (UIView * const) image;
- (void) setEnabled: (const bool) enabled;

- (void)setPrimaryLabelText: (NSString * const) text;

+ (CGFloat) staticHeight;

@end
