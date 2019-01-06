//
// Created by Dusan Klinec on 21.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushRequestMsg.h"
#import "PEXPushRequestPart.h"


@implementation PEXPushRequestMsg {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.requests = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void) addPart: (PEXPushRequestPart *) part{
    [self.requests addObject:part];
}

-(void) clear {
    [self.requests removeAllObjects];
}

-(void) mergeWithMessage: (PEXPushRequestMsg *) req {


}

@end