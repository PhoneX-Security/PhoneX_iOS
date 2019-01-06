//
// Created by Dusan Klinec on 08.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"

@class PEXContactAddResult;

@interface PEXContactAddSelfTask : PEXTask
@property (nonatomic) NSString * contactAddress;
@property (nonatomic) NSString * contactAlias;

- (PEXContactAddResult *) getResult;
- (id) initWithController: (PEXGuiController *) controller;
@end