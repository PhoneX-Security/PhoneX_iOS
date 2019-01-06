//
// Created by Matej Oravec on 19/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiRowItemView.h"

@class PEXGuiThumailView;
@class PEXGuiPoint;


@interface PEXGuiSimpleFileView : PEXGuiRowItemView

@property (nonatomic) UILabel *L_fileName;
@property (nonatomic) UIView * V_thumbNail;
@property (nonatomic) PEXGuiThumailView *I_thumbnail;
@property (nonatomic) PEXGuiPoint * V_separator;

// TODO check
- (void) layoutImage;

- (void) initGui;
- (void) applyThumb: (UIImage * const) thumb filename: (NSString * const) filename;

@end