//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContactRenameEvents.h"
#import "PEXTask.h"

@interface PEXContactRenameTask : PEXTask
@property (nonatomic) NSString * contactAddress;
@property (nonatomic) NSString * contactAlias;

- (PEXContactRenameResult *) getResult;

@end
