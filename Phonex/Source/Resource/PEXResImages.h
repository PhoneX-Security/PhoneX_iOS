//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>


#define PEXImg(str) [PEXResImages getImageNamed:(str)]

@interface PEXResImages : NSObject

+ (UIImage *) getImageNamed: (NSString * const) imageName;

@end