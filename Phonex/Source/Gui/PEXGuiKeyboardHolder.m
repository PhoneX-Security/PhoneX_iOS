//
//  PEXGuiKeyboardHolder.m
//  Phonex
//
//  Created by Matej Oravec on 19/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiKeyboardHolder.h"

#import "PEXGuiController.h"

@interface PEXGuiKeyboardHolder ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) PEXGuiController * current;

@end

@implementation PEXGuiKeyboardHolder


- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];

    return self;
}

- (void) setCurrent: (PEXGuiController * const) current
{
//    [self.lock lock];

    _current = current;
    

//    [self.lock unlock];
}

- (PEXGuiController *) getCurrent
{
    return _current;
}

- (void) stopEditing
{
    [_current.view endEditing:true];
}


+ (PEXGuiKeyboardHolder*) instance
{
    static PEXGuiKeyboardHolder * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiKeyboardHolder alloc] init];
    });

    return instance;
}

@end
