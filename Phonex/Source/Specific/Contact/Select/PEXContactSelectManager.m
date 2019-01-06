//
//  PEXGuiContactSelectManager.m
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXContactSelectManager.h"

@interface PEXContactSelectManager ()

@property (nonatomic) NSMutableArray * listeners;
@property (nonatomic) NSMutableArray * selected;
@property (nonatomic) NSLock * lock;

@end

@implementation PEXContactSelectManager

- (id) init
{
    self = [super init];

    self.listeners = [[NSMutableArray alloc] init];
    self.selected = [[NSMutableArray alloc] init];
    self.lock = [[NSLock alloc] init];

    return self;
}

- (NSArray *) getSelected
{
    return self.selected;
}

- (NSUInteger) getSelectedCount
{
    return self.selected.count;
}

- (void) addContact: (const PEXDbContact * const) contact
{
    [self.lock lock];

    if (![self.selected containsObject:contact])
    {
        [self.selected addObject:contact];

        // always addint at the end of the stack
        for (id<PEXContactSelectListener> listener in self.listeners)
            [listener contactAdded:contact];
    }

    [self.lock unlock];
}
- (void) removeContact: (const PEXDbContact * const) contact
{
    [self.lock lock];

    const NSUInteger position = [self.selected indexOfObject:contact];
    if (position != NSNotFound)
    {
        [self.selected removeObjectAtIndex:position];

        for (id<PEXContactSelectListener> listener in self.listeners)
            [listener contactRemoved:contact];
    }

    [self.lock unlock];
}

- (void) addListener: (id<PEXContactSelectListener>) listener
{
    [self.lock lock];
    [self.listeners addObject:listener];
    [listener fillIn:self.selected];
    [self.lock unlock];
}
- (void) deleteListener: (id<PEXContactSelectListener>) listener
{
    [self.lock lock];
    [self.listeners removeObject:listener];
    [self.lock unlock];
}

- (void) clearSelection
{
    [self.lock lock];
    [self.selected removeAllObjects];
    for (id<PEXContactSelectListener> listener in self.listeners)
        [listener clearSelection];
    [self.lock unlock];
}

@end
