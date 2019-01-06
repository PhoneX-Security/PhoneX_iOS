//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSendingState.h"


@implementation PEXSendingState {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.properties = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (instancetype)initWithType:(PEXSendingStateType)type {
    self = [self init];
    if (self) {
        self.type = type;
    }

    return self;
}

- (instancetype)initWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText {
    self = [self init];
    if (self) {
        self.type = type;
        self.pjsipErrorCode = pjsipErrorCode;
        self.pjsipErrorText = pjsipErrorText;
    }

    return self;
}

- (instancetype)initWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText properties:(NSDictionary *)properties {
    self = [self init];
    if (self) {
        self.type = type;
        self.pjsipErrorCode = pjsipErrorCode;
        self.pjsipErrorText = pjsipErrorText;
        self.properties = properties;
    }

    return self;
}

- (instancetype)initWithBackoff:(NSDate *)resendTime {
    self = [super init];
    if (self) {
        self.type = PEX_STT_FOR_BACKOFF;
        self.resendTime = resendTime;
    }

    return self;
}

+ (instancetype)stateWithBackoff:(NSDate *)resendTime {
    return [[self alloc] initWithBackoff:resendTime];
}


+ (instancetype)stateWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText properties:(NSDictionary *)properties {
    return [[self alloc] initWithType:type pjsipErrorCode:pjsipErrorCode pjsipErrorText:pjsipErrorText properties:properties];
}


+ (instancetype)stateWithType:(PEXSendingStateType)type pjsipErrorCode:(int)pjsipErrorCode pjsipErrorText:(NSString *)pjsipErrorText {
    return [[self alloc] initWithType:type pjsipErrorCode:pjsipErrorCode pjsipErrorText:pjsipErrorText];
}


+ (instancetype)stateWithType:(PEXSendingStateType)type {
    return [(PEXSendingState *)[self alloc] initWithType:type];
}

+(PEXSendingState *) getSending {
    return [PEXSendingState stateWithType: PEX_STT_SENDING];
}

+(PEXSendingState *) getAckPositive {
    return [PEXSendingState stateWithType: PEX_STT_ACK_POSITIVE];
}

+(PEXSendingState *)getBackoff {
    return [PEXSendingState stateWithType: PEX_STT_FOR_BACKOFF];
}

+(PEXSendingState *) getInvalidDestination {
    return [PEXSendingState stateWithType: PEX_STT_FAILED_INVALID_DESTINATION];
}

+(PEXSendingState *) getMissingRemoteCert {
    return [PEXSendingState stateWithType: PEX_STT_FAILED_MISSING_REMOTE_CERT];
}

+(PEXSendingState *)getGenericFail {
    return [PEXSendingState stateWithType: PEX_STT_FAILED_GENERIC];
}

+(PEXSendingState *)getSendingFail {
    return [PEXSendingState stateWithType: PEX_STT_FAILED_CANNOT_SEND];
}

+(PEXSendingState *) getReachedMaxNumOfResends {
    return [PEXSendingState stateWithType: PEX_STT_FAILED_REACHED_MAX_NUM_OF_RESENDS];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.pjsipErrorCode=%i", self.pjsipErrorCode];
    [description appendFormat:@", self.type=%d", self.type];
    [description appendFormat:@", self.pjsipErrorText=%@", self.pjsipErrorText];
    [description appendFormat:@", self.resendTime=%@", self.resendTime];
    [description appendFormat:@", self.properties=%@", self.properties];
    [description appendString:@">"];
    return description;
}

@end