//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPrivateKey.h"


@implementation PEXPrivateKey {

}
- (instancetype)initWithKey:(PEXEVPPKey *)key {
    self = [super init];
    if (self) {
        self.key = key;
    }

    return self;
}

+ (instancetype)keyWithKey:(PEXEVPPKey *)key {
    return [[self alloc] initWithKey:key];
}

@end