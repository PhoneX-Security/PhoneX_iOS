//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUserKeyRefreshQueue.h"
#import "PEXConcurrentPriorityQueue.h"
#import "PEXUserKeyRefreshRecord.h"

@interface PEXUserKeyRefreshQueue() {}
/**
* Concurrent priority user queue to generate keys for, main scheduling structure.
*/
@property(nonatomic) PEXPriorityQueue * userQueue;

/**
* Maps user names to objects located in userqueue. It has to be consistent with userQueue.
*/
@property(nonatomic) NSMutableDictionary * userMap;
@property(nonatomic) dispatch_queue_t queue;
@end

@implementation PEXUserKeyRefreshQueue {}

- (instancetype)initWithQueue:(dispatch_queue_t)queue1 {
    if ((self = [super init]) == nil) return nil;
    if (queue1 == nil){
        // Create a new serial queue if none is provided.
        _queue = dispatch_queue_create("concurrent_hash_map", DISPATCH_QUEUE_SERIAL);
    } else {
        _queue = queue1;
    }

    self.userQueue = [[PEXPriorityQueue alloc] init];
    self.userMap = [[NSMutableDictionary alloc] init];
    return self;
}

- (instancetype)initWithQueueName:(NSString *)queueName {
    return [self initWithQueue:dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
}

- (PEXUserKeyRefreshRecord *)getRecordForUser:(NSString *)user {
    __weak __typeof(self) weakSelf = self;
    __block PEXUserKeyRefreshRecord * rec = nil;

    dispatch_block_t block = ^{
        rec = weakSelf.userMap[user];
    };

    dispatch_sync(_queue, block);
    return [rec copy];
}

- (PEXUserKeyRefreshRecord *)peek {
    __weak __typeof(self) weakSelf = self;
    __block PEXUserKeyRefreshRecord * rec = nil;

    dispatch_block_t block = ^{
        rec = [weakSelf.userQueue first];
    };

    dispatch_sync(_queue, block);
    return [rec copy];
}

- (PEXUserKeyRefreshRecord *)poll {
    __weak __typeof(self) weakSelf = self;
    __block PEXUserKeyRefreshRecord * rec = nil;

    dispatch_block_t block = ^{
        rec = [weakSelf.userQueue pop];

        // Remove object also from user map.
        if (rec != nil && rec.user != nil) {
            [weakSelf.userMap removeObjectForKey:rec.user];
        }
    };

    dispatch_sync(_queue, block);
    return [rec copy];
}

- (void)update:(PEXUserKeyRefreshRecord *)record {
    __weak __typeof(self) weakSelf = self;

    dispatch_block_t block = ^{
        id mapObj = weakSelf.userMap[record.user];
        if (mapObj == nil){
            [record recomputeCost];
            [weakSelf.userQueue addObject:record];
            weakSelf.userMap[record.user] = record;

        } else {
            // Transfer new fields from record object to mapped object - update it in the queue.
            PEXUserKeyRefreshRecord * prevRec = (PEXUserKeyRefreshRecord *) mapObj;
            [prevRec updateFromRecord:record];
            [weakSelf.userQueue resort:prevRec];
        }
    };

    dispatch_sync(_queue, block);
}


@end