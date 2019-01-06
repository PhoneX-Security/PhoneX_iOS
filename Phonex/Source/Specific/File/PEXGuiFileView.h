//
//  PEXGuiFileView.h
//  Phonex
//
//  Created by Matej Oravec on 02/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiRowItemView.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "PEXFileData.h"
#import "PEXGuiSimpleFileView.h"

@interface PEXGuiFileView : PEXGuiSimpleFileView

- (void) applyAsset: (const PEXFileData * const) data;

- (bool) isChecked;
- (void) check;
- (void) setChecked: (const bool) checked;
- (void) setPositionNumber: (const int) position;

- (PEXGuiClickableView *) getCheckView;

- (NSUInteger) position;

@end
