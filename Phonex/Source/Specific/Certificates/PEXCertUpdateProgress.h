//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXX509;

/**
* State for current certificate entry during certificate refresh process.
*/
typedef enum PEXCertUpdateStateEnum {
    PEX_CERT_UPDATE_STATE_NONE,
    PEX_CERT_UPDATE_STATE_IN_QUEUE,
    PEX_CERT_UPDATE_STATE_STARTED,
    PEX_CERT_UPDATE_STATE_LOCAL_LOADING,
    PEX_CERT_UPDATE_STATE_SERVER_CALL,
    PEX_CERT_UPDATE_STATE_POST_SERVER_CALL,
    PEX_CERT_UPDATE_STATE_WAITING_FINAL_CONFIRMATION,
    PEX_CERT_UPDATE_STATE_SAVING,
    PEX_CERT_UPDATE_STATE_DONE
} PEXCertUpdateStateEnum;

@interface PEXCertUpdateProgress : NSObject <NSCoding, NSCopying>

/**
* User for which this update process takes place.
*/
@property(nonatomic) NSString * user;

/**
* State of the updating process right now.
*/
@property(nonatomic) PEXCertUpdateStateEnum state;

/**
* When was this entry updated for the last time.
*/
@property(nonatomic) NSDate * when;

/**
* Denotes whether certificate was changed (new was loaded).
* Is valid only if state is DONE.
*/
@property(nonatomic) BOOL certChanged;

/**
* New certificate loaded. Is valid only in states {WAITING_FINAL_CONFIRMATION, DONE}.
* Serves mainly for confirmation purposes.
*/
@property(nonatomic) NSString *xnewCertificate;

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state;
+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state;

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when;
+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when;

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when certChanged:(BOOL)certChanged newCertificate:(NSString *)newCertificate;
+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when certChanged:(BOOL)certChanged newCertificate:(NSString *)newCertificate;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

@end