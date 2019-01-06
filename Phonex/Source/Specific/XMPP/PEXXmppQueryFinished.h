//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXXMPPPhxPushInfo;
@class PEXXMPPPhxPushModule;
@class XMPPIQ;
@class PEXXMPPSimplePacketSendRecord;

/**
 * Protocol for handler receiving notifications after XMPP IQs was sent.
 */
@protocol PEXXmppQueryFinished <NSObject>
-(void) query:(PEXXMPPPhxPushModule *)sender resp: (XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)pingInfo withSendRec: (PEXXMPPSimplePacketSendRecord *) sendRec;
@end