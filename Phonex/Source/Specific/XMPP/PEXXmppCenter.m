//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXXmppCenter.h"
#import "PEXXmppManager.h"


@implementation PEXXmppCenter {

}

- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}


+ (PEXXmppCenter *)instance {
    static PEXXmppCenter *_instance = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}


@end