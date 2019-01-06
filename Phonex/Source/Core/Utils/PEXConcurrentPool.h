//
// Created by Dusan Klinec on 19.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Pool of objects.
 *
 * Idea of use on an example: NSDataDetector is a heavy object to construct and deconstruct.
 * So not to create and destruct it for each time it is needed, worker threads could peek this pool
 * for available NSDataDetector (detector is not thread safe). When it takes object from pool, it is removed
 * from this collection atomically. Once the worker is done with object it returns it to the pool.
 *
 * Pool could also support a lazy initialization of detectors. I.e., if capacity of pool > size of pool and
 * none object is available, worker could register itself as a generator of the object. This would increase its size.
 * Once the generator thread is done with the object, it puts a new (already used) detector to the pool.
 *
 * TODO: implement.
 */
@interface PEXConcurrentPool : NSObject
@end