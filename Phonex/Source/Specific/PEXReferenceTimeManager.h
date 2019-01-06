//
// Created by Matej Oravec on 17/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXReferenceTime : NSObject <NSCopying, NSCoding>

@property (nonatomic) uint64_t localInSeconds;
@property (nonatomic) NSDate * serverTime;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToTime:(PEXReferenceTime *)time;
- (NSUInteger)hash;
@end

@protocol PEXReferenceTimeUpdateListener
- (void) fill: (const PEXReferenceTime * const) referenceTime;
- (void)added:(const PEXReferenceTime *const)referenceTime;
@end

@interface PEXReferenceTimeManager : NSObject

- (void)startCheckForTimeIfNeeded: (void (^)(void)) blockOnNoConnection;
- (PEXReferenceTime *) getReferenceTime;
- (PEXReferenceTime *) setReferenceServerTime: (NSDate *) referenceTime;

- (void) addListener: (id<PEXReferenceTimeUpdateListener>) listener;
- (void) removeListener: (id<PEXReferenceTimeUpdateListener>) listener;

- (NSDate *) currentTimeSinceReference: (NSDate * const) dateIfServerNotAvavailable;

@end