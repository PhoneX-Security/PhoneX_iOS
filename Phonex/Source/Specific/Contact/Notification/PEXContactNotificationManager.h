//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXControllerManager.h"

@class PEXDbContactNotification;

@protocol PEXContactNotificationListener

- (void) countChanged: (NSArray * const) notifications;

@end

@interface PEXContactNotificationManager : NSObject<PEXContentObserver>


- (void)initContent;
- (void)addListenerAndSet: (id<PEXContactNotificationListener>) listener;
- (void) removeListener: (id<PEXContactNotificationListener>) listener;

+ (void)seeAllNotificationsAsync;
+ (void) removeNotification: (const PEXDbContactNotification * const) notification;

@end