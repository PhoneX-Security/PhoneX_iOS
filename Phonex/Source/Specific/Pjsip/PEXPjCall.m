//
// Created by Dusan Klinec on 11.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjCall.h"
#import "pjsua-lib/pjsua.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXPjZrtpStateInfo.h"


@implementation PEXPjCall {

}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.accId = PJSUA_INVALID_ID;
        self.callId = PJSUA_INVALID_ID;
        self.confPort = PJSUA_INVALID_ID;
        self.mediaSecure = NO;
        self.hasZrtp = NO;
        self.zrtpSASVerified = NO;
        self.mediaSecureError = NO;
        self.answerCalled = NO;
        self.hangupCalled = NO;
        self.isIncoming = NO;
        self.remoteSideAnswered = NO;
        self.onHoldStatus = nil;
        self.zrtpLog = [[PEXConcurrentLinkedList alloc] initWithQueueName:@"zrtplogQueue"];
    }

    return self;
}

- (BOOL)hasCallState:(int)callState {
    if (self.callState == nil){
        return NO;
    }

    return [self.callState integerValue] == callState;
}

- (BOOL)hasStatusCode:(int)code {
    if (self.lastStatusCode == nil){
        return NO;
    }

    return [self.lastStatusCode integerValue] == code;
}

- (void)applyDisconnect {

}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.accId=%li", self.accId];
    [description appendFormat:@", self.callId=%i", self.callId];
    [description appendFormat:@", self.remoteContact=%@", self.remoteContact];
    [description appendFormat:@", self.remoteSip=%@", self.remoteSip];
    [description appendFormat:@", self.isIncoming=%d", self.isIncoming];
    [description appendFormat:@", self.roleInitiator=%d", self.roleInitiator];
    [description appendFormat:@", self.confPort=%i", self.confPort];
    [description appendFormat:@", self.callState=%@", self.callState];
    [description appendFormat:@", self.mediaState=%@", self.mediaState];
    [description appendFormat:@", self.answerCalled=%d", self.answerCalled];
    [description appendFormat:@", self.hangupCalled=%d", self.hangupCalled];
    [description appendFormat:@", self.callStart=%@", self.callStart];
    [description appendFormat:@", self.connectStart=%@", self.connectStart];
    [description appendFormat:@", self.mediaSecure=%d", self.mediaSecure];
    [description appendFormat:@", self.zrtpSASVerified=%d", self.zrtpSASVerified];
    [description appendFormat:@", self.hasZrtp=%d", self.hasZrtp];
    [description appendFormat:@", self.zrtpHashMatch=%@", self.zrtpHashMatch];
    [description appendFormat:@", self.mediaSecureInfo=%@", self.mediaSecureInfo];
    [description appendFormat:@", self.mediaSecureError=%d", self.mediaSecureError];
    [description appendFormat:@", self.mediaSecureErrorString=%@", self.mediaSecureErrorString];
    [description appendFormat:@", self.localByeCode=%@", self.localByeCode];
    [description appendFormat:@", self.byeCauseCode=%@", self.byeCauseCode];
    [description appendFormat:@", self.onHoldStatus=%@", self.onHoldStatus];
    [description appendFormat:@", self.lastStatusCode=%@", self.lastStatusCode];
    [description appendFormat:@", self.lastStatusComment=%@", self.lastStatusComment];
    [description appendFormat:@", self.sipCallId=%@", self.sipCallId];
    [description appendFormat:@", self.remoteSideAnswered=%d", self.remoteSideAnswered];
    [description appendFormat:@", self.zrtpInfo=%@", self.zrtpInfo];
    [description appendFormat:@", self.zrtpLog=%@", self.zrtpLog];
    [description appendString:@">"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPjCall *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.accId = self.accId;
        copy.callId = self.callId;
        copy.remoteContact = self.remoteContact;
        copy.remoteSip = self.remoteSip;
        copy.isIncoming = self.isIncoming;
        copy.roleInitiator = self.roleInitiator;
        copy.confPort = self.confPort;
        copy.callState = self.callState;
        copy.mediaState = self.mediaState;
        copy.answerCalled = self.answerCalled;
        copy.hangupCalled = self.hangupCalled;
        copy.callStart = self.callStart;
        copy.connectStart = self.connectStart;
        copy.mediaSecure = self.mediaSecure;
        copy.zrtpSASVerified = self.zrtpSASVerified;
        copy.hasZrtp = self.hasZrtp;
        copy.zrtpHashMatch = self.zrtpHashMatch;
        copy.mediaSecureInfo = self.mediaSecureInfo;
        copy.mediaSecureError = self.mediaSecureError;
        copy.mediaSecureErrorString = self.mediaSecureErrorString;
        copy.localByeCode = self.localByeCode;
        copy.byeCauseCode = self.byeCauseCode;
        copy.onHoldStatus = self.onHoldStatus;
        copy.lastStatusCode = self.lastStatusCode;
        copy.lastStatusComment = self.lastStatusComment;
        copy.sipCallId = self.sipCallId;
        copy.remoteSideAnswered = self.remoteSideAnswered;
        copy.zrtpInfo = self.zrtpInfo;
        copy.zrtpLog = self.zrtpLog;
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.accId = [coder decodeIntForKey:@"self.accId"];
        self.callId = [coder decodeIntForKey:@"self.callId"];
        self.remoteContact = [coder decodeObjectForKey:@"self.remoteContact"];
        self.remoteSip = [coder decodeObjectForKey:@"self.remoteSip"];
        self.isIncoming = [coder decodeBoolForKey:@"self.isIncoming"];
        self.roleInitiator = [coder decodeBoolForKey:@"self.roleInitiator"];
        self.confPort = [coder decodeIntForKey:@"self.confPort"];
        self.callState = [coder decodeObjectForKey:@"self.callState"];
        self.mediaState = [coder decodeObjectForKey:@"self.mediaState"];
        self.answerCalled = [coder decodeBoolForKey:@"self.answerCalled"];
        self.hangupCalled = [coder decodeBoolForKey:@"self.hangupCalled"];
        self.callStart = [coder decodeObjectForKey:@"self.callStart"];
        self.connectStart = [coder decodeObjectForKey:@"self.connectStart"];
        self.mediaSecure = [coder decodeBoolForKey:@"self.mediaSecure"];
        self.zrtpSASVerified = [coder decodeBoolForKey:@"self.zrtpSASVerified"];
        self.hasZrtp = [coder decodeBoolForKey:@"self.hasZrtp"];
        self.zrtpHashMatch = [coder decodeObjectForKey:@"self.zrtpHashMatch"];
        self.mediaSecureInfo = [coder decodeObjectForKey:@"self.mediaSecureInfo"];
        self.mediaSecureError = [coder decodeBoolForKey:@"self.mediaSecureError"];
        self.mediaSecureErrorString = [coder decodeObjectForKey:@"self.mediaSecureErrorString"];
        self.localByeCode = [coder decodeObjectForKey:@"self.localByeCode"];
        self.byeCauseCode = [coder decodeObjectForKey:@"self.byeCauseCode"];
        self.onHoldStatus = [coder decodeObjectForKey:@"self.onHoldStatus"];
        self.lastStatusCode = [coder decodeObjectForKey:@"self.lastStatusCode"];
        self.lastStatusComment = [coder decodeObjectForKey:@"self.lastStatusComment"];
        self.sipCallId = [coder decodeObjectForKey:@"self.sipCallId"];
        self.remoteSideAnswered = [coder decodeBoolForKey:@"self.remoteSideAnswered"];
        self.zrtpInfo = [coder decodeObjectForKey:@"self.zrtpInfo"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.accId forKey:@"self.accId"];
    [coder encodeInt:self.callId forKey:@"self.callId"];
    [coder encodeObject:self.remoteContact forKey:@"self.remoteContact"];
    [coder encodeObject:self.remoteSip forKey:@"self.remoteSip"];
    [coder encodeBool:self.isIncoming forKey:@"self.isIncoming"];
    [coder encodeBool:self.roleInitiator forKey:@"self.roleInitiator"];
    [coder encodeInt:self.confPort forKey:@"self.confPort"];
    [coder encodeObject:self.callState forKey:@"self.callState"];
    [coder encodeObject:self.mediaState forKey:@"self.mediaState"];
    [coder encodeBool:self.answerCalled forKey:@"self.answerCalled"];
    [coder encodeBool:self.hangupCalled forKey:@"self.hangupCalled"];
    [coder encodeObject:self.callStart forKey:@"self.callStart"];
    [coder encodeObject:self.connectStart forKey:@"self.connectStart"];
    [coder encodeBool:self.mediaSecure forKey:@"self.mediaSecure"];
    [coder encodeBool:self.zrtpSASVerified forKey:@"self.zrtpSASVerified"];
    [coder encodeBool:self.hasZrtp forKey:@"self.hasZrtp"];
    [coder encodeObject:self.zrtpHashMatch forKey:@"self.zrtpHashMatch"];
    [coder encodeObject:self.mediaSecureInfo forKey:@"self.mediaSecureInfo"];
    [coder encodeBool:self.mediaSecureError forKey:@"self.mediaSecureError"];
    [coder encodeObject:self.mediaSecureErrorString forKey:@"self.mediaSecureErrorString"];
    [coder encodeObject:self.localByeCode forKey:@"self.localByeCode"];
    [coder encodeObject:self.byeCauseCode forKey:@"self.byeCauseCode"];
    [coder encodeObject:self.onHoldStatus forKey:@"self.onHoldStatus"];
    [coder encodeObject:self.lastStatusCode forKey:@"self.lastStatusCode"];
    [coder encodeObject:self.lastStatusComment forKey:@"self.lastStatusComment"];
    [coder encodeObject:self.sipCallId forKey:@"self.sipCallId"];
    [coder encodeBool:self.remoteSideAnswered forKey:@"self.remoteSideAnswered"];
    [coder encodeObject:self.zrtpInfo forKey:@"self.zrtpInfo"];
}


@end