//
// Created by Matej Oravec on 02/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXControllerManager.h"

@interface PEXControllerManager ()

@property (nonatomic) NSMutableArray * items;
@property (nonatomic) NSLock * lock;
@property (nonatomic, weak) PEXGuiContentLoaderController * controller;

- (void) initContent;
- (int) getCount;
- (void) loadItems;
- (void) executeOnControllerSync: (void (^)(void))actionOnController;
- (void) fillController;

@end