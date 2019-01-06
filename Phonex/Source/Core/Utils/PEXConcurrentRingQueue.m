//
// Created by Dusan Klinec on 30.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//
#import "PEXConcurrentRingQueue.h"
#import "PEXUtils.h"

@interface PEXConcurrentRingQueue () {
    // Dispatch serial queue to use for list control.
    dispatch_queue_t _queue;
}

@property (nonatomic) NSMutableArray * ring;
@property (nonatomic) NSUInteger curElements;
@property (nonatomic) NSUInteger maxSize;
@property (nonatomic) NSUInteger posBeg;
@property (nonatomic) NSUInteger posEnd;

@end

@implementation PEXConcurrentRingQueue { }

- (instancetype)initWithQueue:(dispatch_queue_t)queue1 capacity: (NSUInteger) capacity {
    if ((self = [super init]) == nil) return nil;
    if (queue1 == nil){
        // Create a new serial queue if none is provided.
        _queue = dispatch_queue_create("concurrent_ring_queue", DISPATCH_QUEUE_SERIAL);
    } else {
        _queue = queue1;
    }

    _ring = [[NSMutableArray alloc] initWithCapacity:capacity];
    _maxSize = capacity;
    _posBeg = 0;
    _posEnd = 0;
    _curElements = 0;
    for(int i=0; i < capacity; i++){
        [_ring addObject:[NSNull null]];
    }

    return self;
}

- (instancetype)initWithQueueName:(NSString *)queueName capacity: (NSUInteger) capacity {
    return [self initWithQueue:dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL) capacity:capacity];
}

- (id)init {
    return [self initWithQueue:nil capacity:8];
}

+(NSUInteger) idealByteArraySize: (NSUInteger) need {
    for (NSUInteger i = 4; i < 32; i++) {
        if (need <= (1 << i) - 12){
            return ((NSUInteger)1 << i) - 12;
        }
    }

    return need;
}

// Not thread safe, has to be executed in a serial queue.
- (void) resizeInternal: (NSUInteger) minimalSize {
    NSUInteger curCount = _maxSize;
    NSUInteger candidateSize = MAX(minimalSize, curCount == 0u ? 4u : curCount * 2u);
    NSUInteger newCount = [PEXConcurrentRingQueue idealByteArraySize: candidateSize];

    // Create a larger copy
    NSMutableArray * copy = [[NSMutableArray alloc] initWithCapacity:newCount];
    NSUInteger curPos = _posBeg;
    NSUInteger newPos = 0;
    NSUInteger curCtr = 0;
    for(; curCount > 0 && curCtr < _curElements; curCtr++){
        copy[newPos] = _ring[curPos];
        curPos = (curPos + 1) % curCount;
        newPos = (newPos + 1) % newCount;
    }

    // Null loop
    for(NSUInteger i = newPos; i < newCount; i++){
        [_ring addObject:[NSNull null]];
    }

    _ring = copy;
    _posBeg = 0;
    _posEnd = newPos;
    _maxSize = newCount;
}

// Ensure given ring buffer has required size.
-(void) ensureSize: (NSUInteger) size {
    if (size < _maxSize){ // keep 1 block free.
        return;
    }

    [self resizeInternal:size];
}

- (void)pushBack:(id)anObject {
    [self pushBack:anObject async:NO];
}

- (void)pushBack:(id)anObject async:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        // Resize if needed.
        [self ensureSize:_curElements + 1];

        // Add, now we have space.
        _ring[_posEnd] = anObject;
        _posEnd = (_posEnd + 1) % _maxSize;
        _curElements += 1;
    }];
}

- (BOOL)pushBackOnlyIfNonFull:(id)anObject async:(BOOL)async {
    __block BOOL toReturn = NO;
    [PEXUtils executeOnQueue:_queue async:async block:^{
        if ([self isFullUnsafe]){
            return;
        }

        // Add, now we have space.
        _ring[_posEnd] = anObject;
        _posEnd = (_posEnd + 1) % _maxSize;
        _curElements += 1;

        if (!async){
            toReturn = YES;
        }
    }];

    return toReturn;
}

- (id)popFront {
    __block id toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            return;
        }

        toReturn = _ring[_posBeg];
        _ring[_posBeg] = [NSNull null]; // free reference.
        _posBeg = (_posBeg + 1) % _maxSize;
        _curElements -= 1;
    }];

    return toReturn;
}

- (void)removeAllObjects {
    [self removeAllObjectsAsync:NO];
}

- (void)removeAllObjectsAsync:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        if (_curElements == 0){
            return;
        }

        for(NSUInteger i = 0; i < _maxSize; i++){
            _ring[i] = [NSNull null];
        }

        _posBeg = 0;
        _posEnd = 0;
        _curElements = 0;
    }];
}

- (BOOL)containsObject:(id)anObject {
    __block BOOL contains = NO;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            return;
        }

        NSUInteger curPos = _posBeg;
        NSUInteger curCtr = 0;
        for(; curCtr < _curElements; curCtr++){
            if (_ring[curPos] == anObject){
                contains = YES;
                break;
            }

            curPos = (curPos + 1) % _maxSize;
        }
    }];

    return contains;
}

- (NSUInteger)count {
    __block NSUInteger count = 0;
    dispatch_sync(_queue, ^{
        count = _curElements;
    });

    return count;
}

- (BOOL)isEmpty {
    __block BOOL isEmpty = YES;
    dispatch_sync(_queue, ^{
        isEmpty = _curElements == 0;
    });

    return isEmpty;
}

- (BOOL)isEmptyUnsafe {
    return _curElements == 0;
}

- (BOOL) isFull {
    __block BOOL isFull = YES;
    dispatch_sync(_queue, ^{
        isFull = [self isFullUnsafe];
    });

    return isFull;
}

- (BOOL) isFullUnsafe {
    return (_curElements + 1) >= _maxSize;
}

- (id)lastObject {
    __block id toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            return;
        }

        NSUInteger prevPos = _posEnd == 0 ? _maxSize - 1 : _posEnd - 1;
        toReturn = _ring[prevPos];
    }];

    return toReturn;
}

- (id)firstObject {
    __block id toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            return;
        }

        toReturn = _ring[_posBeg];
    }];

    return toReturn;
}

- (id)top {
    return [self firstObject];
}

- (NSArray *)allObjects {
    __block NSArray * toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        toReturn = [_ring copy];
    }];

    return toReturn;
}

- (NSArray *)peekN:(int)count {
    __block NSArray * toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            toReturn = [[NSArray alloc] init];
            return;
        }

        NSMutableArray * tmpArray = [NSMutableArray arrayWithCapacity:count];
        NSUInteger curPos = _posBeg;
        NSUInteger curCtr = 0;
        for(; curCtr < _curElements && curCtr < count; curCtr++){
            [tmpArray addObject:_ring[curPos]];
            curPos = (curPos + 1) % _maxSize;
        }

        toReturn = [tmpArray copy];
    }];

    return toReturn;
}

- (NSArray *)pollN:(int)count {
    __block NSArray * toReturn = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        if (_curElements == 0){
            toReturn = [[NSArray alloc] init];
            return;
        }

        NSMutableArray * tmpArray = [NSMutableArray arrayWithCapacity:count];

        NSUInteger prevCount = _curElements;
        NSUInteger curCtr = 0;
        for(; curCtr < prevCount && curCtr < count; curCtr++){
            [tmpArray addObject:_ring[_posBeg]];
            _ring[_posBeg] = [NSNull null]; // release reference.
            _posBeg = (_posBeg + 1) % _maxSize;
            _curElements -= 1;
        }

        toReturn = [tmpArray copy];
    }];

    return toReturn;
}

- (void)addAll:(NSArray *)input {
    [self addAll:input async:NO];
}

- (void)addAll:(NSArray *)input async:(BOOL)async {
    if (input == nil || [input count] == 0){
        return;
    }

    [PEXUtils executeOnQueue:_queue async:async block:^{
        NSUInteger addSize = [input count];

        // Resize if needed.
        [self ensureSize:_curElements + addSize];

        // Add, now we have space.
        for(id anObject in input){
            _ring[_posEnd] = anObject;
            _posEnd = (_posEnd + 1) % _maxSize;
            _curElements += 1;
        }
    }];
}

- (void)enumerateAsync:(BOOL)async usingBlock:(list_enumerate_block)block {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        if (_curElements == 0){
            return;
        }

        BOOL stop = NO;
        NSUInteger curPos = _posBeg;
        NSUInteger curCtr = 0;
        for(; curCtr < _curElements; curCtr++){
            block(_ring[curPos], curCtr, &stop);
            if (stop){
                break;
            }

            curPos = (curPos + 1) % _maxSize;
        }
    }];
}


@end