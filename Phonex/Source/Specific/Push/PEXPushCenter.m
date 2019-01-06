//
// Created by Dusan Klinec on 27.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPushCenter.h"


@implementation PEXPushCenter {

}
- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}

+ (PEXPushCenter *)instance {
    static PEXPushCenter *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

@end