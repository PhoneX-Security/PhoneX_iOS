//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListChangeParams.h"


@implementation PEXCListChangeParams {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.cr = nil;
        self.diplayName = nil;
        self.inWhitelist = YES;
        self.addAsHidden = NO;
        self.userName = nil;
    }

    return self;
}

@end