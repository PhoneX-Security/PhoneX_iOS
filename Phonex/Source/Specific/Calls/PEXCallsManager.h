//
// Created by Matej Oravec on 02/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentObserver.h"
#import "PEXControllerManager.h"

@class PEXGuiCallsController;
@class PEXGuiCallLog;


@interface PEXCallsManager : PEXControllerManager

//- (void) showChat: (const PEXGuiChat * const) chat;
- (void) callRemoveCallLog: (const PEXGuiCallLog * const)guiCallLog;
- (void) actionOnCallLog: (const PEXGuiCallLog * const)guiCallLog;

@end