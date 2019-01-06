//
//  PEXGuiSelectioBar.h
//  Phonex
//
//  Created by Matej Oravec on 23/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectionBar.h"

@class PEXSelectionDescriptionInfo;

@interface PEXGuiFileSelectionBar : PEXGuiSelectionBar

@property (nonatomic) PEXGuiClickableView * B_deleteSelection;

- (void) notifyError;
- (void) setRestrictions: (NSArray * const) descriptors;

@end
