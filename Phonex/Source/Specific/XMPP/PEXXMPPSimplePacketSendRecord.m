//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXXMPPSimplePacketSendRecord.h"
#import "PEXXmppQueryFinished.h"
#import "PEXXMPPPhxPushModule.h"
#import "XMPPIQ.h"
#import "PEXXmppPhxPushInfo.h"

@interface PEXXMPPSimplePacketSendRecord() {}
@property (nonatomic, weak) PEXXMPPPhxPushModule * sender;
@property (nonatomic) XMPPIQ * response;
@property (nonatomic) PEXXMPPPhxPushInfo * trackingInfo;
@end

@implementation PEXXMPPSimplePacketSendRecord {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sentCount = 0;
        self.tryAfterConnectivityOn = NO;
        self.doneFlag = NO;
        self.sending = NO;
    }

    return self;
}

- (instancetype)initSentinel {
    self = [self init];
    if (self) {
        self.doneFlag = YES;
    }

    return self;
}


- (instancetype)initWithPacketId:(NSString *)packetId {
    self = [self init];
    if (self) {
        self.packetId = packetId;
    }

    return self;
}

+ (instancetype)recordWithPacketId:(NSString *)packetId {
    return [[self alloc] initWithPacketId:packetId];
}

- (BOOL)isFinished {
    return self.doneFlag;
}

- (void)resetForNextSending {
    self.doneFlag = NO;
    self.packetId = nil;
    self.tryAfterConnectivityOn = NO;
    self.sending = YES;
}

- (void)storeLastResult:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)info {
    self.sender = sender;
    self.response = resp;
    self.trackingInfo = info;
}

- (void)onFail {
    @synchronized (self) {
        self.sending = NO;
    }

    if (self.onFinishedHandler != nil){
        [self.onFinishedHandler query:self.sender resp:self.response withInfo:self.trackingInfo withSendRec:self];
    }
}

- (void)onSuccess {
    @synchronized (self) {
        self.sending = NO;
        self.doneFlag = YES;
    }

    if (self.onFinishedHandler != nil){
        [self.onFinishedHandler query:self.sender resp:self.response withInfo:self.trackingInfo withSendRec:self];
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.auxData=%@", self.auxData];
    [description appendFormat:@", self.packetId=%@", self.packetId];
    [description appendFormat:@", self.sentCount=%i", self.sentCount];
    [description appendFormat:@", self.tryAfterConnectivityOn=%d", self.tryAfterConnectivityOn];
    [description appendFormat:@", self.doneFlag=%d", self.doneFlag];
    [description appendFormat:@", self.sending=%d", self.sending];
    [description appendFormat:@", self.usrData=%@", self.usrData];
    [description appendFormat:@", self.sendStarted=%@", self.sendStarted];
    [description appendFormat:@", self.queryInfo=%@", self.queryInfo];
    [description appendFormat:@", self.sender=%@", self.sender];
    [description appendFormat:@", self.response=%@", self.response];
    [description appendFormat:@", self.trackingInfo=%@", self.trackingInfo];
    [description appendString:@">"];
    return description;
}


@end