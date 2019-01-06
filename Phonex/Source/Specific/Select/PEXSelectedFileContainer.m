//
//  PEXSelectedFileContainer.m
//  Phonex
//
//  Created by Matej Oravec on 27/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXSelectedFileContainer.h"
#import "PEXFileData.h"

@implementation PEXSelectedFileContainer

+ (PEXSelectedFileContainer *) containerFromFileData: (const PEXFileData * const) fileData
{
    PEXSelectedFileContainer * const result = [[PEXSelectedFileContainer alloc] init];

    result.url = fileData.url;
    result.isAsset = fileData.isAsset;
    result.filename = fileData.filename;
    result.size = fileData.size;

    return result;
}

@end
