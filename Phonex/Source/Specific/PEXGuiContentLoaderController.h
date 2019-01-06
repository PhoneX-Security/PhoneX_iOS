//
//  PEXGuiContentLoaderController.h
//  Phonex
//
//  Created by Matej Oravec on 22/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiContentLoaderController : PEXGuiController

@property (nonatomic) NSLock * contentLock;
@property (nonatomic) NSLock * guiLock; // use if needed

// called in mutex
- (void) reloadContentAsync;

@end
