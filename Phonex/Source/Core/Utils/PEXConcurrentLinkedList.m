//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXConcurrentLinkedList.h"
#import "PEXUtils.h"

// LNode was a struct previously.
// Is problematic with ARC when list was the only place where
// object was placed.

// Node used in linked list.
@interface LNode : NSObject {}
@property(nonatomic) id obj;
@property(nonatomic) LNode * next;
@property(nonatomic) LNode * prev;
@end

@implementation LNode
@end

// convenience method for creating a LNode.
LNode * LNodeMake(id obj, LNode *next, LNode *prev);

// Keep all properties private in order to preserve thread safety.
@interface PEXConcurrentLinkedList () {
    // Dispatch queue to use for list control.
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite) LNode * first;
@property (nonatomic, readwrite) LNode * last;
@property (nonatomic, readwrite) unsigned int size;
@end

@implementation PEXConcurrentLinkedList

- (instancetype)initWithQueue:(dispatch_queue_t)queue1 {
    if ((self = [super init]) == nil) return nil;
    if (queue1 == nil){
        // Create a new serial queue if none is provided.
        _queue = dispatch_queue_create("concurrent_list_queue", DISPATCH_QUEUE_SERIAL);
    } else {
        _queue = queue1;
    }

    self.first = self.last = nil;
    self.size = 0;
    return self;
}

- (instancetype)initWithQueueName:(NSString *)queueName {
    return [self initWithQueue:dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
}

- (id)init {
    return [self initWithQueue:nil];
}

//FIXED
- (id)lastObject {
    __block id item;
    dispatch_sync(_queue, ^{
        item = self.last ? self.last.obj : nil;
    });
    return item;
}

//FIXED
- (id)firstObject {
    __block id item;
    dispatch_sync(_queue, ^{
        item = self.first ? self.first.obj : nil;
    });
    return item;
}

//FIXED
- (id)secondLastObject {
    __block id item = nil;
    dispatch_sync(_queue, ^{
        if (self.last && self.last.prev) {
            item = self.last.prev.obj;
        }
    });
    return item;
}

//FIXED
- (id)top {
    return [self lastObject];
}

//FIXED
- (void)pushBack:(id)anObject{
    [self pushBack:anObject async:YES];
}

- (void)pushBack:(id)anObject async: (BOOL) async {
    if (anObject == nil) return;

    // Execute in async block, synchronization on adding.
    // Potentially add completion block.
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self pushBackInternal:anObject];
    }];
}

//FIXED
- (void)pushFront:(id)anObject {
    [self pushFront:anObject async:YES];
}

- (void)pushFront:(id)anObject async: (BOOL) async {
    if (anObject == nil) return;

    // Execute in async block, synchronization on adding.
    // Potentially add completion block.
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self pushFrontInternal:anObject];
    }];
}

//FIXED
- (void)insertObject:(id)anObject beforeNode:(LNode *)node {
    [self insertObject:anObject betweenNode:node.prev andNode:node];
}

//FIXED
- (void)insertObject:(id)anObject afterNode:(LNode *)node {
    [self insertObject:anObject betweenNode:node andNode:node.next];
}

//FIXED
- (void)insertObject:(id)anObject betweenNode:(LNode *)previousNode andNode:(LNode *)nextNode {
    if (anObject == nil) return;

    // Execute in async block, synchronization on adding.
    // Potentially add completion block.
    dispatch_async(_queue, ^{
        [self insertObjectInternal:anObject betweenNode:previousNode andNode:nextNode];
    });
}

// FIXED
- (id)objectAtIndex:(const int)inidx {
    __block id ret = nil;

    dispatch_sync(_queue, ^{
        int idx = inidx;

        // they've given us a negative index
        // we just need to convert it positive
        if (inidx < 0) idx = self.size + inidx;
        if (idx >= self.size || idx < 0) {
            return;
        }

        LNode *n = nil;
        if (idx > (self.size / 2)) {
            // loop from the back
            int curridx = self.size - 1;
            for (n = self.last; idx < curridx; --curridx) {
                n = n.prev;
            }

            ret = n.obj;
        } else {
            // loop from the front
            int curridx = 0;
            for (n = self.first; curridx < idx; ++curridx) {
                n = n.next;
            }

            ret = n.obj;
        }
    });

    return ret;
}

// FIXED
- (id)popBack {
    __block id ret = nil;
    dispatch_sync(_queue, ^{
        if (self.size == 0) return;

        ret = self.last.obj;
        [self removeNodeInternal:self.last];
    });

    return ret;
}

// FIXED
- (id)popFront {
    __block id ret = nil;
    dispatch_sync(_queue, ^{
        if (self.size == 0) return;

        ret = self.first.obj;
        [self removeNodeInternal:self.first];
    });
    return ret;
}

//FIXED
- (void)removeAllObjects {
    [self removeAllObjectsAsync:YES];
}

- (void)removeAllObjectsAsync: (BOOL) async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self removeAllObjectsInternal];
    }];
}

//FIXED
- (BOOL)removeObjectEqualTo:(id)anObject {
    __block BOOL contains = NO;
    dispatch_sync(_queue, ^{
        LNode *n = nil;
        for (n = self.first; n; n = n.next) {
            if (n.obj == anObject) {
                [self removeNodeInternal:n];
                contains = YES;
                break;
            }
        }
    });

    return contains;
}

- (unsigned int)count {
    __block unsigned int count = 0;
    dispatch_sync(_queue, ^{
        count = self.size;
    });

    return count;
}

- (BOOL)isEmpty {
    __block BOOL isEmpty = YES;
    dispatch_sync(_queue, ^{
        isEmpty = self.size == 0;
    });

    return isEmpty;
}

//FIXED
- (BOOL)containsObject:(id)anObject {
    __block BOOL contains = NO;
    dispatch_sync(_queue, ^{
        LNode *n = nil;
        for (n = self.first; n; n = n.next) {
            if (n.obj == anObject) {
                contains = YES;
                break;
            }
        }
    });

    return contains;
}

//FIXED
- (NSArray *)allObjects {
    __block NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:self.size];
    dispatch_sync(_queue, ^{
        LNode *n = nil;
        for (n = self.first; n; n = n.next) {
            [ret addObject:n.obj];
        }
    });

    return [NSArray arrayWithArray:ret];
}

//FIXED
- (NSArray *)allObjectsReverse {
    __block NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:self.size];
    dispatch_sync(_queue, ^{
        LNode *n = nil;
        for (n = self.last; n; n = n.prev) {
            [ret addObject:n.obj];
        }
    });

    return [NSArray arrayWithArray:ret];
}

//FIXED
- (NSArray *) peekN: (int) count {
    __block NSMutableArray *ret = nil;
    dispatch_sync(_queue, ^{
        ret = [[NSMutableArray alloc] initWithCapacity:count];
        LNode *n = nil;
        int ctr = 0;
        for (n = self.first; n && ctr < count; n = n.next, ctr++) {
            [ret addObject:n.obj];
        }
    });

    return [NSArray arrayWithArray:ret];
}

// FIXED
- (NSArray *) pollN: (int) count {
    __block NSMutableArray *ret = nil;
    dispatch_sync(_queue, ^{
        ret = [[NSMutableArray alloc] initWithCapacity:count];
        LNode *n = nil;
        int ctr = 0;
        for (n = self.first; n && ctr < count; n = n.next, ctr++) {
            [ret addObject:n.obj];
            [self removeNodeInternal:n];
        }
    });

    return [NSArray arrayWithArray:ret];
}

- (void)addAll:(NSArray *)input {
    [self addAll:input async:YES];
}

- (void)addAll:(NSArray *)input async: (BOOL) async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        for (id obj in input){
            [self pushBackInternal:obj];
        }
    }];
}

// FIXED
- (void) enumerateAsync: (BOOL) async usingBlock: (list_enumerate_block) block {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        LNode *n = nil;
        BOOL stop = NO;
        NSUInteger idx = 0;
        for (n = self.first; n ; n = n.next, ++idx) {
            block(n.obj, idx, &stop);

            if (stop){
                break;
            }
        }
    }];
}

// Internal, no-sync.
- (void)pushBackInternal:(id)anObject {
    if (anObject == nil){
        DDLogError(@"Cannot insert nil!");
        return;
    }

    LNode *n = LNodeMake(anObject, nil, self.last);
    if (self.size == 0) {
        self.first = self.last = n;
    } else {
        self.last.next = n;
        self.last = n;
    }

    self.size++;
}

// Internal, no-sync.
- (void)pushFrontInternal:(id)anObject {
    LNode *n = LNodeMake(anObject, self.first, nil);
    if (self.size == 0) {
        self.first = self.last = n;
    } else {
        self.first.prev = n;
        self.first = n;
    }

    self.size++;
}

//Internal, no-sync
- (void)insertObjectInternal:(id)anObject betweenNode:(LNode *)previousNode andNode:(LNode *)nextNode {
    if (anObject == nil) return;

    LNode *n = LNodeMake(anObject, nextNode, previousNode);
    if (previousNode) {
        previousNode.next = n;
    } else {
        self.first = n;
    }

    if (nextNode) {
        nextNode.prev = n;
    } else {
        self.last = n;
    }

    self.size++;
}

// Internal, no-sync.
- (void)removeAllObjectsInternal {
    LNode *n = self.first;
    while (n) {
        LNode *next = n.next;
        n.obj;
        n.obj = nil;
        n = next;
    }

    self.first = self.last = nil;
    self.size = 0;
}

// Internal, no-sync.
- (void)removeNodeInternal:(LNode *)aNode {
    if (self.size == 0) return;
    if (self.size == 1) {
        // delete first and only
        self.first = self.last = nil;
    } else if (aNode.prev == nil) {
        // delete first of many
        self.first = self.first.next;
        self.first.prev = nil;
    } else if (aNode.next == nil) {
        // delete last
        self.last = self.last.prev;
        self.last.next = nil;
    } else {
        // delete in the middle
        LNode *tmp = aNode.prev;
        tmp.next = aNode.next;
        tmp = aNode.next;
        tmp.prev = aNode.prev;
    }

    aNode.obj;
    aNode.obj = nil;
    aNode = nil;
    self.size--;
}

// Internal, no-sync.
- (void)pushNodeBackInternal:(LNode *)n {
    if (self.size == 0) {
        self.first = self.last = LNodeMake(n.obj, nil, nil);
    } else {
        self.last.next = LNodeMake(n.obj, nil, self.last);
        self.last = self.last.next;
    }

    self.size++;

}

// Internal, no-sync.
- (void)pushNodeFrontInternal:(LNode *)n {
    if (self.size == 0) {
        self.first = self.last = LNodeMake(n.obj, nil, nil);
    } else {
        self.first.prev = LNodeMake(n.obj, self.first, nil);
        self.first = self.first.prev;
    }

    self.size++;
}

- (void)dumpList {
    LNode *n = nil;
    for (n = self.first; n; n = n.next) {
        DDLogVerbose(@"%p", n);
    }
}

//FIXED
- (void)dealloc {
    [self removeAllObjectsInternal];
}

//FIXED
- (NSString *)description {
    return [NSString stringWithFormat:@"PEXConcurrentLinkedList with %d objects", self.size];
}

@end

LNode *LNodeMake(id obj, LNode *next, LNode *prev) {
    LNode * n = [[LNode alloc] init];
    n.next = next;
    n.prev = prev;
    n.obj = obj;
//    LNode *n = malloc(sizeof(LNode));
//    n.next = next;
//    n.prev = prev;
//    n.obj = obj;
    return n;
};

