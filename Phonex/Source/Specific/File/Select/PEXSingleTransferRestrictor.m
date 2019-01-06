//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXSingleTransferRestrictor.h"

static const uint64_t MAXIMUM_BYTES_TO_PICK = 20LL * 1024LL * 1024LL; // 20 MB

@implementation PEXSingleTransferRestrictor {

}

- (id) init
{
    return [super initWithMaxSizeInBytes:[PEXSingleTransferRestrictor maxSizeInBytes]];
}

+ (uint64_t) maxSizeInBytes
{
    return MAXIMUM_BYTES_TO_PICK;
}

@end