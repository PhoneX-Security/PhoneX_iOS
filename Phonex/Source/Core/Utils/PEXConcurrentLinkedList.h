//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXConcurrentLinkedList : NSObject {   }

// Main constructor.
- (instancetype) initWithQueue: (dispatch_queue_t) queue;
- (instancetype) initWithQueueName: (NSString *) queueName;
- (id)init;                                 // init an empty list

- (void)pushBack:(id)anObject;              // add an object to back of list
- (void)pushBack:(id)anObject async: (BOOL) async;
- (void)pushFront:(id)anObject;             // add an object to front of list
- (void)pushFront:(id)anObject async: (BOOL) async;
- (id)popBack;                              // remove object at end of list (returns it)
- (id)popFront;                             // remove object at front of list (returns it)
- (BOOL)removeObjectEqualTo:(id)anObject;   // removes object equal to anObject, returns (YES) on success
- (void)removeAllObjects;                   // clear out the list
- (void)removeAllObjectsAsync: (BOOL) async;
- (void)dumpList;                           // dumps all the pointers in the list to NSLog
- (BOOL)containsObject:(id)anObject;        // (YES) if passed object is in the list, (NO) otherwise
- (unsigned int)count;                      // how many objects are stored
- (BOOL)isEmpty;

- (id)objectAtIndex:(const int)idx;
- (id)lastObject;
- (id)firstObject;
- (id)secondLastObject;
- (id)top;

- (NSArray *)allObjects;
- (NSArray *)allObjectsReverse;

/**
* Atomically takes first N elements from the queue.
* Queue operation typical for batch processing. In a loop, takeN elements, process them.
* Return as an NSArray of objects.
*/
- (NSArray *)peekN: (int) count;

/**
* Atomically takes first N elements from the queue and removes them from the queue.
* Queue operation typical for batch processing. In a loop, takeN elements, process them.
* Return as an NSArray of objects.
*/
- (NSArray *)pollN: (int) count;

/**
* Inserts all objects from the input array.
*/
- (void) addAll: (NSArray*) input;
- (void) addAll:(NSArray *)input async: (BOOL) async;

/**
* Enumerate all elements in the list using given block.
*/
- (void) enumerateAsync: (BOOL) async usingBlock: (list_enumerate_block) block;

@end
