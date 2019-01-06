//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXMessageQueueActions.h"
#import "PEXAmpDispatcher.h"
#import "PEXProtocols.h"

@class PEXUserPrivate;
@class PEXCertificate;

@interface PEXTransportProtocolDispatcher : NSObject
@property(nonatomic) id<PEXMessageQueueActions> messageQueueListener;
@property(nonatomic) PEXUserPrivate * userIdentity;
@property(nonatomic) PEXCertificate * remoteCert;
@property(nonatomic) PEXAmpDispatcher * ampDispatcher;

- (instancetype)initWithRemoteCert:(PEXCertificate *)remoteCert userIdentity:(PEXUserPrivate *)userIdentity;
+ (instancetype)dispatcherWithRemoteCert:(PEXCertificate *)remoteCert userIdentity:(PEXUserPrivate *)userIdentity;

-(void) receive: (PEXDbMessageQueue *) msg;
-(void) transmit: (PEXDbMessageQueue *) msg;
@end