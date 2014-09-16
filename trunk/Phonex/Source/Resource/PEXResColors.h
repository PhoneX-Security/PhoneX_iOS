//
//  PEXResColors.h
//  Phonex
//
//  Created by Matej Oravec on 03/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PEXCol(str) [PEXResColors color:(str)]

@interface PEXResColors : NSObject

+ (UIColor *) color:(const NSString * const) key;

@end
