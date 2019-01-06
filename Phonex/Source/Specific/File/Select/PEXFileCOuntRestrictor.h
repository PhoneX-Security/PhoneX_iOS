//
// Created by Matej Oravec on 24/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXFileSelectRestrictor.h"


@interface PEXFileCountRestrictor : PEXFileSelectRestrictor

- (id) initWithMaxCount: (const int64_t) maxCount;

@end