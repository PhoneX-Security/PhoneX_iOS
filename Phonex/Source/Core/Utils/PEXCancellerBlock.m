//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCancellerBlock.h"


@implementation PEXCancellerBlock {

}
- (instancetype)initWithIsCancelledBlock:(CancelBlock)isCancelledBlock {
    self = [super init];
    if (self) {
        self.isCancelledBlock = isCancelledBlock;
    }

    return self;
}

+ (instancetype)blockWithIsCancelledBlock:(CancelBlock)isCancelledBlock {
    return [[self alloc] initWithIsCancelledBlock:isCancelledBlock];
}


- (BOOL)isCancelled {
    if (self.isCancelledBlock == nil){
        return NO;
    }

    return self.isCancelledBlock();
}

@end