//
// Created by Matej Oravec on 21/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentProvider.h"
#import "PEXDbContentProvider.h"

@interface PEXDbAppContentProvider : PEXDbContentProvider

+ (void) initInstance;
+ (PEXDbContentProvider *) instance;

@end