//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXXmppManager;

/**
* Simple logic for processing JSON encoded push messages, typically received over XMPP channel from server.
* Parses JSON push message and react on them, in a separate worker queue.
*/
@interface PEXXMPPPushProcessor : NSObject
@property (nonatomic, weak) PEXXmppManager * mgr;
@property (nonatomic) dispatch_queue_t dispatchQueue;
@property (nonatomic) dispatch_queue_t workQueue;

-(void) handlePush: (NSString *) json;

- (instancetype)initWithMgr:(PEXXmppManager *)mgr dispatchQueue:(dispatch_queue_t)dispatchQueue;
+ (instancetype)processorWithMgr:(PEXXmppManager *)mgr dispatchQueue:(dispatch_queue_t)dispatchQueue;

@end