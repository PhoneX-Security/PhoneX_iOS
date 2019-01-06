//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"
#import "PEXLoginTaskResultDescription.h"
#import "PEXLoginTaskEvents.h"
#import "PEXLoginStage.h"
#import "PEXLoginTaskResultDescription.h"
#import "PEXPasswordListener.h"

@class PEXGuiController;
@class PEXContactAddResult;

FOUNDATION_EXPORT NSString * PEX_ACTION_CONTACT_ADDED;
FOUNDATION_EXPORT NSString * PEX_EXTRA_CONTACT_ADDED;

@interface PEXContactAddTask : PEXTask
@property (nonatomic) NSString * contactAddress;
@property (nonatomic) NSString * contactAlias;

- (PEXContactAddResult *) getResult;
- (id) initWithController: (PEXGuiController *) controller;

@end
