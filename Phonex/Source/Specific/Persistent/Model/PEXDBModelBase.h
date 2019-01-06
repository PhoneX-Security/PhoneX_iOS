//
// Created by Dusan Klinec on 24.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbModel.h"
#import "PEXDbUri.h"

@interface PEXDbModelBase : NSObject <PEXDbModel, NSCoding, NSCopying>
+(NSDate *) getDateFromCursor: (PEXDbCursor *) c idx:(int) idx;
+(NSNumber *) dateToNumber: (NSDate *) d;
+(NSNumber *) bool2int: (NSNumber *) i;
+(NSNumber *) int2bool: (NSNumber *) i;

@end