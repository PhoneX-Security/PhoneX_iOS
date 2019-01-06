//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXXmppQueryFinishedSimple.h"
#import "PEXXMPPPhxPushModule.h"
#import "XMPPIQ.h"


@implementation PEXXmppQueryFinishedSimple {

}
- (instancetype)initWithPexFinishedBlock:(pex_push_finished)pexFinishedBlock {
    self = [super init];
    if (self) {
        self.pexFinishedBlock = pexFinishedBlock;
    }

    return self;
}

+ (instancetype)simpleWithPexFinishedBlock:(pex_push_finished)pexFinishedBlock {
    return [[self alloc] initWithPexFinishedBlock:pexFinishedBlock];
}

- (void)query:(PEXXMPPPhxPushModule *)sender resp:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)pingInfo withSendRec: (PEXXMPPSimplePacketSendRecord *) sendRec {
    if (self.pexFinishedBlock == nil){
        return;
    }

    self.pexFinishedBlock(sender, resp, pingInfo, sendRec);
}

@end