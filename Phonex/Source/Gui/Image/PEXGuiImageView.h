//
//  PEXGuiImageView.h
//  Phonex
//
//  Created by Matej Oravec on 05/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PEXGuiImageView : UIImageView

- (id) initWithImage: (UIImage * const) image;

-(void) setStateNormal;
-(void) setStateHighlight;

@end
