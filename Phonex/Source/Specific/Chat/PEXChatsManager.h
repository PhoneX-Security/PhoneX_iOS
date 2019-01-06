//
// Created by Matej Oravec on 01/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentObserver.h"
#import "PEXControllerManager.h"

@class PEXGuiChatsController;
@class PEXGuiChat;

@interface PEXChatsManager : PEXControllerManager

- (void)actionOnItem:(const id) item;
- (void)callRemoveItem:(const id) item;

@end