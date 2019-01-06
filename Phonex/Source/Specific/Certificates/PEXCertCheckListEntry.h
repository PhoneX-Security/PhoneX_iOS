//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPriorityQueue.h"

@class PEXCertRefreshParams;


@interface PEXCertCheckListEntry : NSObject <NSCoding, NSCopying, PEXPriorityQueueObject>
@property(nonatomic, copy) NSString * usr;
@property(nonatomic) BOOL policyCheck;//=true;
@property(nonatomic) PEXCertRefreshParams * params;

/**
* If set to YES we need this certificate ASAP.
*/
@property(nonatomic) BOOL urgent;

// Temporary helper variables
@property(nonatomic) volatile BOOL byPushNotification;//=false;
@property(nonatomic) volatile BOOL cancelledFlag;//=false;

// Number of fail count to refresh this certificate entry.
@property(nonatomic) NSUInteger failCount;

-(void) doCancel;
-(BOOL) wasCancelled;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

@end