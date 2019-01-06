//
// Created by Matej Oravec on 02/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentObserver.h"

@class PEXGuiContentLoaderController;


@interface PEXControllerManager : NSObject<PEXContentObserver>

- (void)initContent;
- (int) getCount;
- (void) setController: (PEXGuiContentLoaderController *)controller;
- (bool) isEmpty;
- (id) getItemAt: (const NSUInteger) index;

@end