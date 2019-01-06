//
//  PEXResDimensions.h
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PEXVal(str) [PEXResValues value:(str)]

@interface PEXResValues : NSObject

+ (CGFloat) value:(NSString * const) key;

+ (CGFloat) getItemHeight;
+ (CGFloat) getThumbnailSize;
+ (CGFloat) getThumbnailDetailSize;

@end
