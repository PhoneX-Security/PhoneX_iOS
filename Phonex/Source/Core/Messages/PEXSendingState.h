//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum PEXSendingStateType{
    // message is taken from queue (marked as processed, and we are trying to send it, which may include multiple resends)
    PEX_STT_SENDING=0,
    // destination acknowledged receiving
    PEX_STT_ACK_POSITIVE,
    // negative ack, sending failed and we know it
    PEX_STT_ACK_NEGATIVE,
    // Marked in MessageQueue as unprocessed and with given timeout for resending
    PEX_STT_FOR_BACKOFF,
    // errors
    PEX_STT_FAILED_INVALID_DESTINATION,
    PEX_STT_FAILED_MISSING_REMOTE_CERT,
    PEX_STT_FAILED_REACHED_MAX_NUM_OF_RESENDS,
    PEX_STT_FAILED_CANNOT_SEND,  // message sending error - internal stack problem.
    PEX_STT_FAILED_GENERIC // any other error that might happen

} PEXSendingStateType;

@interface PEXSendingState : NSObject

@property(nonatomic) PEXSendingStateType type;
@property(nonatomic) int pjsipErrorCode;
@property(nonatomic) NSString * pjsipErrorText;
@property(nonatomic) NSDate * resendTime;
@property(nonatomic) NSDictionary * properties;

- (instancetype)initWithType:(PEXSendingStateType)type;
+ (instancetype)stateWithType:(PEXSendingStateType)type;

- (instancetype)initWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText;
+ (instancetype)stateWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText;

- (instancetype)initWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText properties:(NSDictionary *)properties;
+ (instancetype)stateWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText properties:(NSDictionary *)properties;

- (instancetype)initWithBackoff:(NSDate *)resendTime;

- (NSString *)description;
+ (instancetype)stateWithBackoff:(NSDate *)resendTime;

+(PEXSendingState *) getSending;
+(PEXSendingState *) getAckPositive;
+(PEXSendingState *) getBackoff;
+(PEXSendingState *) getInvalidDestination;
+(PEXSendingState *) getMissingRemoteCert;
+(PEXSendingState *)getGenericFail;
+(PEXSendingState *)getSendingFail;
+(PEXSendingState *) getReachedMaxNumOfResends;

@end