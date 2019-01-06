//
// Created by Dusan Klinec on 27.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPJID;

/**
* Simple presence update holder for contacts. Used for bulk updates in arrays.
*/
@interface PEXPresenceUpdate : NSObject

@property(nonatomic) NSString * user;
@property(nonatomic) BOOL isAvailable;
@property(nonatomic) NSString * statusText;
@property(nonatomic) NSDate * timestamp;
@property(nonatomic) XMPPJID * xmppUser;

- (instancetype)initWithUser:(NSString *)user isAvailable:(BOOL)isAvailable statusText:(NSString *)statusText;
+ (instancetype)updateWithUser:(NSString *)user isAvailable:(BOOL)isAvailable statusText:(NSString *)statusText;

- (instancetype)initWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user;
+ (instancetype)updateWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user;

- (instancetype)initWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user xmppUser:(XMPPJID *)xmppUser;
+ (instancetype)updateWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user xmppUser:(XMPPJID *)xmppUser;

@end