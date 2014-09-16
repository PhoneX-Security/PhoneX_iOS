//
//  PEXGuiImageClickableView.h
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiImageView.h"

@interface PEXGuiImageClickableView : PEXGuiImageView

-(void) addAction:(id)target action:(SEL)action;

@end
