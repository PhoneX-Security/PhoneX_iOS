//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    PEX_KEYGEN_STATE_NONE,
    PEX_KEYGEN_STATE_IN_QUEUE,
    PEX_KEYGEN_STATE_STARTED,
    PEX_KEYGEN_STATE_CLEANING,
    PEX_KEYGEN_STATE_OBTAINING_STATE,
    PEX_KEYGEN_STATE_GENERATING_KEY,
    PEX_KEYGEN_STATE_GENERATED,
    PEX_KEYGEN_STATE_SERVER_CALL_SAVE,
    PEX_KEYGEN_STATE_POST_SERVER_CALL_SAVE,
    PEX_KEYGEN_STATE_DONE,
    PEX_KEYGEN_STATE_DELETING,
    PEX_KEYGEN_STATE_SERVER_CALL_DELETE,
    PEX_KEYGEN_STATE_POST_SERVER_CALL_DELETE
} PEXKeyGenStateEnum;

@interface PEXDHKeyGeneratorProgress : NSObject <NSCoding, NSCopying>

/**
* User for which this update process takes place.
*/
@property(nonatomic) NSString * user;

/**
* State of the updating process right now.
*/
@property(nonatomic) PEXKeyGenStateEnum state;

/**
* When was this entry updated for the last time.
*/
@property(nonatomic) NSDate * when;

/**
* Whether error occurred.
*/
@property(nonatomic) BOOL error;
@property(nonatomic) NSNumber * errorCode;  // Integer
@property(nonatomic) NSNumber * errorCodeAux;  // Integer
@property(nonatomic) NSString * errorReason;

/**
* Maximum number of keys that will be generated in the single generating cycle.
* Valid only if state=GENERATING_KEY.
*/
@property(nonatomic) NSNumber * maxKeysToGen;  // Integer

/**
* Number of generated keys so far.
* Valid only if state=GENERATING_KEY.
*/
@property(nonatomic) NSNumber * alreadyGeneratedKeys;  // Integer

- (instancetype)initWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state;
+ (instancetype)progressWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state;

- (instancetype)initWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state when:(NSDate *)when;

+ (instancetype)progressWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state when:(NSDate *)when;


- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToProgress:(PEXDHKeyGeneratorProgress *)progress;
- (NSUInteger)hash;
- (NSString *)description;
        
@end