//
// Created by Matej Oravec on 01/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXArrayUtils : NSObject

+ (void)moveObject:(id) object to: (const NSUInteger) position on: (NSMutableArray * const) marray;
+ (bool)moveFrom:(const NSUInteger) index to: (const NSUInteger) position on:(NSMutableArray * const) marray;
+ (bool) getMoveNewPosition: (const NSUInteger) from to: (const NSUInteger) to result: (NSUInteger * const) out;

@end