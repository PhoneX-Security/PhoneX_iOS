//
//  PEXRefDictionary.m
//  Phonex
//
//  Created by Matej Oravec on 10/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXRefDictionary.h"

@interface PEXRefDictionary ()

@property (nonatomic) NSMutableArray * keys;
@property (nonatomic) NSMutableArray * objects;

@end

@implementation PEXRefDictionary

- (id) initWithCapacity:(const NSUInteger)capacity
{
    self = [super init];

    self.keys = [[NSMutableArray alloc] initWithCapacity:capacity];
    self.objects = [[NSMutableArray alloc] initWithCapacity:capacity];

    return self;
}

- (id) init
{
    return [self initWithCapacity:0];
}

- (void)setObject: (id)object forKey:(id) key;
{
    const NSUInteger index = [self.keys indexOfObject:key];
    if (index != NSNotFound)
    {
        self.keys[index] = key;
        self.objects[index] = object;
    }
    else
    {
        [self.keys addObject: key];
        [self.objects addObject: object];
    }
}

// the key with object must be already there
// [0 - count]
- (void)moveForKey:(id) key to: (const NSUInteger) position;
{
    const NSUInteger index = [self.keys indexOfObject:key];

    [self moveFrom:index to:position];
}

- (void)moveFrom:(const NSUInteger) index to: (const NSUInteger) position;
{
    const bool toHigher = (index < position);
    if ((position == index) || (toHigher && (position == index + 1)))
        return;
    const NSUInteger newPosition = (toHigher ? position - 1 : position);

    id key = self.keys[index];
    id object = self.objects[index];

    [self.keys removeObjectAtIndex:index];
    [self.objects removeObjectAtIndex:index];

    [self.keys insertObject:key atIndex:newPosition];
    [self.objects insertObject:object atIndex:newPosition];
}

- (void)removeObjectForKey: (id)key
{
    const NSUInteger index = [self.keys indexOfObject:key];
    if (index != NSNotFound)
    {
        [self removePairAt:index];
    }
}

- (void) removePairAt: (const NSUInteger) index
{
    [self.keys removeObjectAtIndex:index];
    [self.objects removeObjectAtIndex:index];
}

- (id)objectForKey: (id) key
{
    const NSUInteger index = [self.keys indexOfObject:key];
    id result = nil;
    if (index != NSNotFound)
    {
        result = self.objects[index];
    }
    return result;
}

- (id)keyForObject: (id) object
{
    const NSUInteger index = [self.objects indexOfObject:object];
    id result = nil;
    if (index != NSNotFound)
    {
        result = self.keys[index];
    }
    return result;
}

- (NSUInteger)indexOfKey: (id) key
{
    return [self.keys indexOfObject:key];
}

- (id) keyAt: (const NSUInteger) index
{
    return self.keys[index];
}

- (void) replaceKey: (id) newKey at: (const NSUInteger) index
{
    self.keys[index] = newKey;
}

- (id) objectAt: (const NSUInteger) index
{
    return self.objects[index];
}

- (NSMutableArray*) getKeys
{
    return self.keys;
}

- (NSMutableArray*) getObjects
{
    return self.objects;
}

- (bool) hasKey: (id) key
{
    return ([self.keys indexOfObject:key] != NSNotFound);
}

- (void) removeAllObjects
{
    [self.keys removeAllObjects];
    [self.objects removeAllObjects];
}

- (NSUInteger) count
{
    return self.keys.count;
}

@end
