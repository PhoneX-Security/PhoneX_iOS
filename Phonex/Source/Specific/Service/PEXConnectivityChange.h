//
// Created by Dusan Klinec on 22.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXReachability.h"

// Connection change values. No change, up, down.
typedef enum PEXConnChangeVal {
    PEX_CONN_NO_CHANGE = 0,
    PEX_CONN_GOES_UP,
    PEX_CONN_GOES_DOWN,
} PEXConnChangeVal;

typedef enum PEXConnWorksVal {
    PEX_CONN_DONT_KNOW = 0,
    PEX_CONN_IS_UP,
    PEX_CONN_IS_DOWN,
} PEXConnWorksVal;

@interface PEXConnectivityChange : NSObject <NSCoding, NSCopying>
@property (nonatomic) PEXConnChangeVal connection;
@property (nonatomic) PEXConnChangeVal sip;
@property (nonatomic) PEXConnChangeVal xmpp;

@property (nonatomic) PEXConnWorksVal connectionWorks;
@property (nonatomic) PEXConnWorksVal sipWorks;
@property (nonatomic) PEXConnWorksVal xmppWorks;

@property (nonatomic) PEXConnWorksVal connectionWorksPrev;
@property (nonatomic) PEXConnWorksVal sipWorksPrev;
@property (nonatomic) PEXConnWorksVal xmppWorksPrev;

@property (nonatomic) NetworkStatus networkStatus;
@property (nonatomic) NetworkStatus networkStatusPrev;
@property (nonatomic) BOOL recheckIPChange;

@property(nonatomic) NSString * radioTechnology;

- (instancetype)initWithConnection:(PEXConnChangeVal)connection sip:(PEXConnChangeVal)sip xmpp:(PEXConnChangeVal)xmpp;
+ (instancetype)changeWithConnection:(PEXConnChangeVal)connection sip:(PEXConnChangeVal)sip xmpp:(PEXConnChangeVal)xmpp;
- (BOOL) isWholeSystemConnected;

- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToChange:(PEXConnectivityChange *)change;
- (NSUInteger)hash;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end