//
// Created by Dusan Klinec on 04.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPriorityQueue.h"


//
//  PEXPriorityQueue.m
//
//  Created by Jesse Collis on 10/10/11.
//  Copyright (c) 2012, Jesse Collis JC Multimedia Design. <jesse@jcmultimedia.com.au>
//  All rights reserved.
//
//  * Redistribution and use in source and binary forms, with or without 
//   modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright 
//   notice, this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright 
//   notice, this list of conditions and the following disclaimer in the 
//   documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY 
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
//

@implementation PEXPriorityQueueHeaderNode

- (double)cost
{
    return -DBL_MAX;
}

- (NSString *)description
{
    return @"HeaderNode";
}

@end

@interface PEXPriorityQueue()
@property (atomic, strong) NSMutableArray *queue;
@end

@implementation PEXPriorityQueue

#pragma mark - Properties
@synthesize queue = _queue;

- (id)init
{
    if ((self = [super init]))
    {
        [self clear];
    }

    return self;
}

- (void)clear
{
    self.queue = [[NSMutableArray alloc] initWithObjects:[[PEXPriorityQueueHeaderNode alloc] init], nil];
}

#pragma mark - PEXPriorityQueue
- (void)addObject:(id<PEXPriorityQueueObject>)object
{
    NSUInteger last_index = [self count];
    NSUInteger parent_index = last_index / 2;

    [self.queue addObject:object];

    id<PEXPriorityQueueObject> parent = [self.queue objectAtIndex:parent_index];

    while (object.cost < parent.cost) //compare with parent
    {
        [self.queue removeObject:object];
        [self.queue insertObject:object atIndex:parent_index];

        [self.queue removeObject:parent];
        [self.queue insertObject:parent atIndex:last_index]; //swap

        last_index = parent_index; //increment
        parent_index /= 2;

        parent = [self.queue objectAtIndex:parent_index]; //re-assign parent
    }
}

- (id<PEXPriorityQueueObject>)pop
{
    id<PEXPriorityQueueObject> first_object_to_return = [self first];

    if (nil == first_object_to_return)
    {
        return nil;
    }

    NSUInteger first_index = 1;
    NSUInteger last_index = [self count] - 1;

    if (last_index == first_index)
    {
        [self.queue removeObjectAtIndex:last_index];
        return first_object_to_return;
    }

    id<PEXPriorityQueueObject> last_object = [self.queue objectAtIndex:last_index];
    [self.queue removeObjectAtIndex:last_index];

    [self.queue removeObjectAtIndex:1];
    [self.queue insertObject:last_object atIndex:1];

    NSUInteger i, child;

    for (i = first_index; i * 2 < [self count]; i = child)
    {
        child = i * 2;

        id<PEXPriorityQueueObject> child_obj = [self.queue objectAtIndex:child];
        id<PEXPriorityQueueObject> child_2;

        if (child + 1 < [self count])
        {
            child_2 = [self.queue objectAtIndex:child + 1];

            if (child_2.cost < child_obj.cost)
            {
                child++;
                child_obj = child_2;
            }
        }

        if (last_object.cost > child_obj.cost)
        {
            [self.queue removeObject:child_obj];
            [self.queue insertObject:child_obj atIndex:i];

            [self.queue removeObject:last_object];
            [self.queue insertObject:last_object atIndex:child];
        }
        else
        {
            break;
        }
    }

    return first_object_to_return;
}

- (void)resort:(id<PEXPriorityQueueObject>)object
{
    NSUInteger last_index = [self.queue indexOfObject:object];
    NSUInteger parent_index = last_index / 2;

    id<PEXPriorityQueueObject> parent = [self.queue objectAtIndex:parent_index];

    while (object.cost < parent.cost) //compare with parent
    {
        [self.queue removeObject:object];
        [self.queue insertObject:object atIndex:parent_index];

        [self.queue removeObject:parent];
        [self.queue insertObject:parent atIndex:last_index]; //swap

        last_index = parent_index; //increment
        parent_index /= 2;

        parent = [self.queue objectAtIndex:parent_index]; //re-assign parent
    }
}

- (id<PEXPriorityQueueObject>)first
{
    if (self.queue.count < 2) return nil;

    return [self.queue objectAtIndex:1];
}

- (NSUInteger)count
{
    return self.queue.count;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"PEXPriorityQueue: %lu items", (unsigned long) [self count]];
}

- (NSMutableArray *)getBackend {
    return self.queue;
}

@end