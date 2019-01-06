//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXFileSelectRestrictor.h"


@interface PEXFileSizeRestrictor : PEXFileSelectRestrictor

@property (nonatomic, readonly, assign) uint64_t maxSizeInBytes;

- (id) initWithMaxSizeInBytes: (const uint64_t) maxSize;

- (uint64_t) maxSizeInBytes;

@end