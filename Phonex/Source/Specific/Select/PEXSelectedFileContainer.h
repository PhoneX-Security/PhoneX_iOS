//
//  PEXSelectedFileContainer.h
//  Phonex
//
//  Created by Matej Oravec on 27/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXFileData;

@interface PEXSelectedFileContainer : NSObject

@property (nonatomic) NSURL * url;
@property (nonatomic, assign) bool isAsset;
@property (nonatomic) NSString * filename;
@property (nonatomic, assign) int64_t size;

+ (PEXSelectedFileContainer *) containerFromFileData: (const PEXFileData * const) fileData;

@end
