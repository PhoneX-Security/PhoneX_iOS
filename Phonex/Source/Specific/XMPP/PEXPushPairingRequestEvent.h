//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPushPairingRequestEvent : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSString * user;
@property(nonatomic) NSNumber * tstamp;

- (instancetype)initWithTstamp:(NSNumber *)tstamp user:(NSString *)user;
+ (instancetype)eventWithTstamp:(NSNumber *)tstamp user:(NSString *)user;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end