//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"
#import "PEXContactRemoveEvents.h"

/**
* Notification value, triggered when user gets removed.
*/
FOUNDATION_EXPORT NSString * PEX_ACTION_CONTACT_REMOVED;
FOUNDATION_EXPORT NSString * PEX_EXTRA_CONTACT_REMOVED;

@interface PEXContactRemoveTask : PEXTask
@property (nonatomic) NSString * contactAddress;

- (instancetype)initWithContactAddress:(NSString *)contactAddress;
+ (instancetype)taskWithContactAddress:(NSString *)contactAddress;

- (PEXContactRemoveResult *) getResult;
@end