//
//  PEXGuiButtonWithImage_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 05/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonWithImage.h"
#import "PEXGuiClickableHighlightedView_Protected.h"

#import "PEXGuiClassicLabel.h"
#import "PEXGuiImageView.h"

@interface PEXGuiButtonWithImage ()

@property (nonatomic) UIView *imageView;
@property (nonatomic) UILabel *labelView;

- (const UIColor *) labelColor;

@end
