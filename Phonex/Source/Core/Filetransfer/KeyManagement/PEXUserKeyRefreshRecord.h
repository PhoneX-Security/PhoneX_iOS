//
// Created by Dusan Klinec on 07.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPriorityQueue.h"


@interface PEXUserKeyRefreshRecord : NSObject<PEXPriorityQueueObject, NSCoding, NSCopying>
/**
* Username for the user to generate keys for, from contactlist.
*/
@property(nonatomic) NSString * user;

/**
* Number of currently available keys for this user on the server.
*/
@property(nonatomic) NSInteger availableKeys;

/**
* Maximal number of keys to be kept available on the server.
*/
@property(nonatomic) NSInteger maximalKeys;

/**
* Number of key requests since last processing.
* This entry has to be re-set when it passes generation phase
* and new keys are generated and stored on the server so
* its priority is again reduced and others can be processed.
*/
@property(nonatomic) NSInteger numberOfKeyRequests;

/**
* Number of messages from/to this user in the last time window (e.g., last 100 messages) / total.
*/
@property(nonatomic) double ratioOfMessagesInLastWindow;

/**
* Number of files transmitted from/to this user in the last time window (e.g., last 100 file transfers)  / total.
*/
@property(nonatomic) double ratioOfFilesInLastWindow;
@property(nonatomic) BOOL certIsOK;

- (void) recomputeCost;
- (BOOL) shouldBeProcessed;

/**
* Updates metrics from the given record and recomputes cost.
*/
- (void) updateFromRecord: (PEXUserKeyRefreshRecord *) rec;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToRecord:(PEXUserKeyRefreshRecord *)record;
- (NSUInteger)hash;
- (NSString *)description;
@end