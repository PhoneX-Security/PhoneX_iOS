//
// Created by Dusan Klinec on 25.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDatabase;
typedef int (^PEXTableConversionBlock)(NSString * oldTable, NSString * newTable);

@interface PEXDbSchemeUpdates : NSObject
+(void) onUpgrade: (PEXDatabase *) db oldVersion: (int) oldVersion newVersion: (int) newVersion;
@end