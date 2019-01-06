//
//  PEXUnmanagedObjectHolder.m
//  Phonex
//
//  Created by Matej Oravec on 06/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXUnmanagedObjectHolder.h"

#import "PEXRefDictionary.h"

@interface PEXUnmanagedObjectHolder ()

@property (nonatomic) PEXRefDictionary * dict;
@property (nonatomic) NSLock * lock;

@end

@implementation PEXUnmanagedObjectHolder

- (id)init
{
    self = [super init];

    // probably max 2 executors at a time
    self.lock = [[NSLock alloc] init];
    self.dict = [[PEXRefDictionary alloc] initWithCapacity: 2];

    return self;
}

+ (void) initInstance
{
    [PEXUnmanagedObjectHolder instance];
}

+ (PEXUnmanagedObjectHolder *) instance
{
    static PEXUnmanagedObjectHolder* instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXUnmanagedObjectHolder alloc] init];
    });

    return instance;
}

+ (void)addActiveObject: (id)object forKey: (id) key;
{
    PEXUnmanagedObjectHolder * const instance = [self instance];
    [instance.lock lock];
    [instance.dict setObject: object forKey:key];
    [instance.lock unlock];
}

+ (void)removeActiveObjectForKey: (id)key
{
    PEXUnmanagedObjectHolder * const instance = [self instance];
    [instance.lock lock];
    [instance.dict removeObjectForKey:key];
    [instance.lock unlock];
}

+ (void) clearAll
{
    PEXUnmanagedObjectHolder * const instance = [self instance];
    [instance.lock lock];
    [instance.dict removeAllObjects];
    [instance.lock unlock];
}

@end
