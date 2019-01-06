//
// Created by Dusan Klinec on 05.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

// Block using for map enumeration.
typedef void (^map_enumerate_block)(id<NSCopying> aKey, id anObject, BOOL *stop);

@interface PEXMapEntry : NSObject {}
@property(nonatomic) id<NSCopying> key;
@property(nonatomic) id obj;
@end

@interface PEXConcurrentHashMap : NSObject
- (instancetype) initWithQueue: (dispatch_queue_t) queue;
- (instancetype) initWithQueueName: (NSString *) queueName;

-(NSUInteger) count;
-(BOOL) isEmpty;
-(id) get: (id<NSCopying>) aKey;
- (void) put: (id) anObject key: (id<NSCopying>) aKey async: (BOOL) async;
- (id)   put: (id) anObject key: (id<NSCopying>) aKey;
- (void) remove: (id<NSCopying>) aKey async: (BOOL) async;
- (void) clear: (BOOL) async;

/**
* Inserts all objects from the input array.
*/
- (void) addAll: (NSDictionary*) input;
- (void) addAll:(NSDictionary *)input async: (BOOL) async;

-(NSSet *) keyset;
-(NSDictionary *) copyData;
-(NSMutableDictionary *) mutableCopyData;

- (void) enumerateAsync: (BOOL) async usingBlock: (map_enumerate_block) block;

/**
* Update single element in the map.
*/
- (void) updateAsync: (BOOL) async key: (id<NSCopying>) key usingBlock: (map_enumerate_block) block;

/**
* Update queue in synchronized block.
* Warning, this provides access to low level structure, API may be unstable.
*/
- (void) updateAsync: (BOOL) async usingBlock: (void (^)(NSMutableDictionary *))block;

@end