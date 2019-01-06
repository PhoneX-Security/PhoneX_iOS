//
// Created by Matej Oravec on 12/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXReferenceTimeManager.h"
#import "PEXLicenceManager.h"

@class PEXDbExpiredLicenceLog;

@protocol PEXMessageAccountingListener

- (void) messagesStatusChanged: (const int64_t) messagesCounts withLimit: (const int64_t) limit;
- (void) limitReached;

@end

@interface PEXChatAccountingManager : NSObject<PEXLicenceListener>

- (void)addListenerAndSet: (id<PEXMessageAccountingListener>) listener;
- (void) removeListener: (id<PEXMessageAccountingListener>) listener;

- (void)loadStateAndnotifyListenersWithPermissions: (NSArray * const) permissions;

+ (int) getMessageCountLimitPeriodInDays;

+ (int64_t) getAvailableMessages: (NSArray *) permissions;

+ (int64_t)getSpentMessagesLimitOut:(int64_t *const)limitOut
                    fromPermissions: (NSArray *) permissions;

@end