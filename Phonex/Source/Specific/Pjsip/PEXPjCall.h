//
// Created by Dusan Klinec on 11.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXPjZrtpStateInfo.h"

@class PEXConcurrentLinkedList;

@interface PEXPjCall : NSObject <NSCoding, NSCopying>

@property(nonatomic) long accId;
@property(nonatomic) int callId;
@property(nonatomic) NSString * remoteContact;
@property(nonatomic) NSString * remoteSip;
@property(nonatomic) BOOL isIncoming;
@property(nonatomic) BOOL roleInitiator;
@property(nonatomic) int confPort;

@property(nonatomic) NSNumber * callState;
@property(nonatomic) NSNumber * mediaState;
@property(nonatomic) BOOL answerCalled;
@property(nonatomic) BOOL hangupCalled;

@property(nonatomic) NSDate * callStart;
@property(nonatomic) NSDate * connectStart;

@property(nonatomic) BOOL mediaSecure;
@property(nonatomic) BOOL zrtpSASVerified;
@property(nonatomic) BOOL hasZrtp;
@property(nonatomic) NSNumber * zrtpHashMatch;
@property(nonatomic) NSString * mediaSecureInfo;

@property(nonatomic) BOOL mediaSecureError;
@property(nonatomic) NSString * mediaSecureErrorString;

@property(nonatomic) NSNumber * localByeCode;
@property(nonatomic) NSNumber * byeCauseCode;
@property(nonatomic) NSNumber * onHoldStatus;
@property(nonatomic) NSNumber * lastStatusCode;
@property(nonatomic) NSString * lastStatusComment;
@property(nonatomic) NSString * sipCallId;
@property(nonatomic) BOOL remoteSideAnswered;

// ZRTP state info.
@property(nonatomic) PEXPjZrtpStateInfo * zrtpInfo;
@property(nonatomic) PEXConcurrentLinkedList * zrtpLog;

//protected int transportSecure = 0;
//protected boolean mediaHasVideoStream = false;
//protected boolean canRecord = false;
//protected boolean isRecording = false;
- (BOOL) hasCallState: (int) callState;
- (BOOL) hasStatusCode: (int) code;
- (void) applyDisconnect;

@end