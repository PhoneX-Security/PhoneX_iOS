//
// Created by Dusan Klinec on 30.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXConcurrentRingQueue : NSObject
- (instancetype)initWithQueue:(dispatch_queue_t)queue1 capacity: (NSUInteger) capacity;
- (instancetype)initWithQueueName:(NSString *)queueName capacity: (NSUInteger) capacity;

/**
 * Synchronously pushes object to the queue to back of list
 * If there is not enough room in the queue, operation increases queue size.
 */
- (void)pushBack:(id)anObject;

/**
 * Remove object at end of list (returns it).
 */
- (void)pushBack:(id)anObject async: (BOOL) async;

/**
 * Pushes object to the queue only if no resize is needed. Otherwise
 * the object is not stored.
 *
 * Returns YES if object was pushed. No if not.
 * If operation is executed asynchronously, return value is always NO.
 *
 * Used to implement (weak) pool mechanism, pushing constructed object
 * to the pool only if the pool is not full.
 */
- (BOOL)pushBackOnlyIfNonFull:(id)anObject async: (BOOL) async;

/**
 * Synchronously pops object from the queue at front of list.
 * If queue is empty, nil is returned.
 */
- (id)popFront;

- (void)removeAllObjects;                   // clear out the list
- (void)removeAllObjectsAsync: (BOOL) async;
- (BOOL)containsObject:(id)anObject;        // (YES) if passed object is in the list, (NO) otherwise

/**
 * Returns number of elements stored in the queue.
 */
- (NSUInteger)count;

/**
 * Returns YES if the queue is empty.
 *
 * Note this call is only of small informative value as after the
 * returning from the call information can be already obsolete.
 */
- (BOOL)isEmpty;

/**
 * Returns YES if queue has full capacity and next push would result
 * in queue resizing.
 *
 * Note this call is only of small informative value as after the
 * returning from the call information can be already obsolete.
 */
- (BOOL) isFull;

- (id)lastObject;
- (id)firstObject;
- (id)top;

- (NSArray *)allObjects;

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