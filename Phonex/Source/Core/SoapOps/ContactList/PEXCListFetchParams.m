//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListFetchParams.h"


@implementation PEXCListFetchParams {


}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateClistTable = NO;
        self.dbId=-1;
        self.sip=nil;
        self.resetPresence = YES;
    }

    return self;
}

@end