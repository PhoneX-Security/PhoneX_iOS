//
// Created by Dusan Klinec on 05.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXConcurrentHashMap.h"
#import "PEXUtils.h"

// Map entry.
@implementation PEXMapEntry
@end

// Keep all properties private in order to preserve thread safety.
@interface PEXConcurrentHashMap () {
    // Dispatch queue to use for list control.
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite) NSMutableDictionary * dict;
@end

@implementation PEXConcurrentHashMap

- (instancetype)initWithQueue:(dispatch_queue_t)queue1 {
    if ((self = [super init]) == nil) return nil;
    if (queue1 == nil){
        // Create a new serial queue if none is provided.
        _queue = dispatch_queue_create("concurrent_hash_map", DISPATCH_QUEUE_SERIAL);
    } else {
        _queue = queue1;
    }

    self.dict = [[NSMutableDictionary alloc] init];
    return self;
}

- (instancetype)initWithQueueName:(NSString *)queueName {
    return [self initWithQueue:dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
}

- (id)init {
    return [self initWithQueue:nil];
}

-(NSUInteger) count {
    __block NSUInteger count = 0;
    dispatch_sync(_queue, ^{
        count = [self.dict count];
    });

    return count;
}

-(BOOL) isEmpty {
    __block BOOL isEmpty = YES;
    dispatch_sync(_queue, ^{
        isEmpty = [self.dict count] != 0;
    });

    return isEmpty;
}

-(id) get: (id<NSCopying>) aKey {
    __block id ret = nil;
    dispatch_sync(_queue, ^{
        ret = self.dict[aKey];
    });

    return ret;
}

- (void)put: (id) anObject key: (id<NSCopying>) aKey async: (BOOL) async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        self.dict[aKey] = anObject;
    }];
}

- (id)put:(id)anObject key:(id <NSCopying>)aKey {
    __block id ret = nil;
    [PEXUtils executeOnQueue:_queue async:NO block:^{
        ret = self.dict[aKey];
        self.dict[aKey] = anObject;
    }];

    return ret;
}

- (void) remove: (id<NSCopying>) aKey async: (BOOL) async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.dict removeObjectForKey:aKey];
    }];
}

- (void) clear: (BOOL) async{
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.dict removeAllObjects];
    }];
}

- (void)addAll:(NSDictionary *)input {
    [self addAll:input async:YES];
}

- (void)addAll:(NSDictionary *)input async:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.dict addEntriesFromDictionary:input];
    }];
}

-(NSSet *) keyset {
    __block NSMutableSet * set = [[NSMutableSet alloc] init];
    dispatch_sync(_queue, ^{
        for (id<NSCopying> curKey in self.dict){
            [set addObject:curKey];
        }
    });

    return [NSSet setWithSet:set];
}

-(NSDictionary *) copyData {
    __block NSDictionary * dict = nil;
    dispatch_sync(_queue, ^{
        dict = [self.dict copy];
    });

    return dict;
}

-(NSMutableDictionary *) mutableCopyData {
    __block NSMutableDictionary * dict = nil;
    dispatch_sync(_queue, ^{
        dict = [self.dict copy];
    });

    return dict;
}

- (void) enumerateAsync: (BOOL) async usingBlock: (map_enumerate_block) block {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        BOOL stop = NO;
        for (id<NSCopying> curKey in self.dict){
            block(curKey, self.dict[curKey], &stop);
            if (stop){
                break;
            }
        }
    }];
}

- (void)updateAsync:(BOOL)async key:(id <NSCopying>) key usingBlock :(map_enumerate_block)block {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        BOOL stop = NO;
        block(key, self.dict[key], &stop);
    }];
}

- (void)updateAsync:(BOOL)async usingBlock:(void (^)(NSMutableDictionary *))block {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        block(self.dict);
    }];
}

@end