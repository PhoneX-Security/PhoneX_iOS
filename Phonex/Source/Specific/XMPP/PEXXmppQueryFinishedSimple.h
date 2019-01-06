//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXXmppQueryFinished.h"

typedef void (^pex_push_finished)(PEXXMPPPhxPushModule * sender, XMPPIQ * resp, PEXXMPPPhxPushInfo * pingInfo, PEXXMPPSimplePacketSendRecord * sendRec);

/**
 * Handler called when XMPP IQ was sent to the server.
 */
@interface PEXXmppQueryFinishedSimple : NSObject<PEXXmppQueryFinished>
@property(nonatomic, copy) pex_push_finished pexFinishedBlock;

- (instancetype)initWithPexFinishedBlock:(pex_push_finished)pexFinishedBlock;
+ (instancetype)simpleWithPexFinishedBlock:(pex_push_finished)pexFinishedBlock;
@end