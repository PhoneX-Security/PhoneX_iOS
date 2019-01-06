//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXFileSizeRestrictor.h"


@interface PEXSingleTransferRestrictor : PEXFileSizeRestrictor

+ (uint64_t) maxSizeInBytes;

@end