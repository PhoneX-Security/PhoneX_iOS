//
//  PEXMergedInputStreamTest.m
//  Phonex
//
//  Created by Dusan Klinec on 26.01.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXMergedInputStream.h"
#import "PEXResCrypto.h"
#import "NSBundle+PEXResCrypto.h"

static const NSString * bufferTestString = @"79vJOGsHRVrZ1N5mpoeGkTIaB4BAWexI26JU3ziVBVe0oZRbw8FT1hrzvJUF\n"
        "C2RVX1dphJmW0AA2nj3x6DwySSj6fCLawgRcaxfAvfhspJXGbUKx99oJACjZzOtZl9QfpTqo8klHvbQm\n"
        "mcGqhdP5dBA42W9mZdK1tl2FnkK6QAPObI1XZs8YMrRIzAcFYxXYZB2gTeXWzALiEflWZfZlBs3oUReW\n"
        "S1FMZiZdyTVVuZeMGoN2L8Zr8TtarslId1IfDqdvpMpumWYSBDTGlgP5pF2jj8mUvp68BK8XQENMKi9O\n"
        "ylgPSDYzfbr08X7FR8VWqvym5AJvLuEx9Er2ET1bawpEl3kfCqwyMgiwU4FZHU0tw77ilLHeOuJz6dde\n"
        "XyYv3QjOTJbVTsGM7GIj6AgfMlry7Kmei1oH5HKfRj9sozNtnGlyPyxtsUCF9WXmV1BvJDSDKGF3TcR2\n"
        "YRKvD72R2Ha6gA6UuIUjMwd1rCnurTmPOXroAKUSoMj43cSaQqR00eIDcsNulDZs3PXTJJtolBo8raXe\n"
        "VXqVWu5u1KkxmedDuVXx7lJggogZmfqz2YHjL3kV9gOZLiTeQVNi6vjM5KHef5OHhTHfoqYGSyKqB6WI\n"
        "eie0KPNx0znIFJer9Q7KO2K4l3QvdVdca3RdJIrxhp4zrmbyHmej9b70yLVsMAfAxoh1EeGfCj0r5wHH\n"
        "kf4YZVDCnRo8f3bgU4qzMvLK7LWDEsCSLn9yfMurUUU7AAIi6Wuo5H8dwwA8sGoKbfqbpoR4e1o5Ntwv\n"
        "c236PauaU2kJCZ9TlSriVgoKIlEtNa9qCrYmzFHxp492Xx5VHXuElcklKX1pxBNDa248UKAqZgrOjWaw\n"
        "44YEN6ydnWQ75iNIO7q0UVNWTNiOVkBh28WoDMu2vWAqFDCKHx06WI8K8Kouw7tZwCdmcqBsiicuv16z\n"
        "ag7W3DkaZWMDW8TEFIJhdRwlKPJf6v1W8GuMxMhQGh0ySIHBLQnhDTyNCzC4yd8OT6nWgshlrRYbSXL6\n"
        "9Y6PsXzWW1RKgg5KQlvecrlcf18EXgYbSHbJa2vzbuyI2nYTOMK8xKS9vFRu0yEZIWIL1nKLHzBRfLZb\n"
        "emp8un88tPPJvXcxwPdLdPhkw48DFKRSf3wCMnHgZO8offOALA1YTkewdsCqYv7HFvrPEDs99LXsnpoF\n"
        "g0x6FqSkGkj72YaNRJoM";

@interface PEXMergedInputStreamTest : XCTestCase<NSStreamDelegate>
@property(nonatomic) PEXMergedInputStream * cis1;
@property(nonatomic) PEXMergedInputStream * cis2;
@property(nonatomic) PEXMergedInputStream * cis3;

@property(nonatomic) dispatch_semaphore_t readingFinished;
@property(nonatomic) volatile BOOL runloopQuit;
@property(nonatomic) NSMutableData * accumulator;
@property(nonatomic) NSUInteger buffSize;

@end

@implementation PEXMergedInputStreamTest

- (void)setUp {
    [super setUp];
    _cis1 = [[PEXMergedInputStream alloc] initWithStream
            :[NSInputStream inputStreamWithData:[bufferTestString dataUsingEncoding:NSASCIIStringEncoding]]
            :[NSInputStream inputStreamWithData:[@"alpha +++++++ " dataUsingEncoding:NSASCIIStringEncoding]]
            :[NSInputStream inputStreamWithData:[@"beta  ------- " dataUsingEncoding:NSASCIIStringEncoding]]
            :[NSInputStream inputStreamWithData:[@"gamma ======= " dataUsingEncoding:NSASCIIStringEncoding]]];

    _cis2 = [[PEXMergedInputStream alloc] initWithStream:
             [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:1]]
            :[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:2]]
            :[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:3]]
            :[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:4]]
            :[NSInputStream inputStreamWithData:[@"gamma ======= " dataUsingEncoding:NSASCIIStringEncoding]]];

    _cis3 = [[PEXMergedInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:[@"gamma ======= " dataUsingEncoding:NSASCIIStringEncoding]]];

    _accumulator = [NSMutableData data];
    _runloopQuit = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (PEXMergedInputStream *) getStream: (int) idx {
    if (idx == 1){
        return _cis1;
    } else if (idx == 2){
        return _cis2;
    } else {
        return _cis3;
    }
}

-(void) checkMis: (PEXMergedInputStream *) stream idx: (int) idx {
    NSString *producedString = [[NSString alloc] initWithData:_accumulator encoding:NSASCIIStringEncoding];

    XCTAssert(producedString != nil && [producedString length] > 5, "Produced string is empty for idx: %d", idx);
    XCTAssert([producedString containsString:@"gamma ======= "], "Result string does not contain gamma string");

    int desiredLen;
    if (idx == 1){
        desiredLen = 1257;
    } else if (idx == 2){
        desiredLen = 3090;
    } else {
        desiredLen = 14;
    }

    XCTAssertEqual(desiredLen, [producedString length], "Result string length does not match");
}

-(void) testPollingReading1{
    _buffSize = 1;
    [self pollingReading: 1];
    [self pollingReading: 2];
    [self pollingReading: 3];
}

-(void) testPollingReading13{
    _buffSize = 13;
    [self pollingReading: 1];
    [self pollingReading: 2];
    [self pollingReading: 3];
}

-(void) testPollingReading32{
    _buffSize = 32;
    [self pollingReading: 1];
    [self pollingReading: 2];
    [self pollingReading: 3];
}

-(void) testPollingReading256{
    _buffSize = 256;
    [self pollingReading: 1];
    [self pollingReading: 2];
    [self pollingReading: 3];
}

-(void) testPollingReadingHuge{
    _buffSize = 8048576;
    [self pollingReading: 1];
    [self pollingReading: 2];
    [self pollingReading: 3];
}

- (void)testPollingReadingPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        [self setUp];
        _buffSize = 64;
        [self pollingReading: 1];
        [self pollingReading: 2];
        [self pollingReading: 3];
    }];
}

- (void)pollingReading: (int) streamNum {
    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_accumulator setData:[NSData data]];

    PEXMergedInputStream * stream = [self getStream:streamNum];
    [stream open];

    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
    while(1){
        if (![stream hasBytesAvailable]){
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }

        NSInteger read = [stream read:readBytes maxLength:[data length]];
        if (read == 0){
            break;
        } else if (read < 0){
            XCTFail(@"Error reading stream");
            return;
        }

        [_accumulator appendData:[NSData dataWithBytes:readBytes length:(NSUInteger) read]];
    }
    [self checkMis:stream idx:streamNum];
    [stream close];
}

- (void) ignore:(id)_ {

}

-(void) testRunloopReading1{
    _buffSize = 1;
    [self runloopReading: 1];
    [self runloopReading: 2];
    [self runloopReading: 3];
}

-(void) testRunloopReading13{
    _buffSize = 13;
    [self runloopReading: 1];
    [self runloopReading: 2];
    [self runloopReading: 3];
}

-(void) testRunloopReading32{
    _buffSize = 32;
    [self runloopReading: 1];
    [self runloopReading: 2];
    [self runloopReading: 3];
}

-(void) testRunloopReading256{
    _buffSize = 256;
    [self runloopReading: 1];
    [self runloopReading: 2];
    [self runloopReading: 3];
}

-(void) testRunloopReadingHuge{
    _buffSize = 8048576;
    [self runloopReading: 1];
    [self runloopReading: 2];
    [self runloopReading: 3];
}

- (void)runloopReading: (int) streamNum {
    _readingFinished = dispatch_semaphore_create(0);
    _runloopQuit = NO;
    [_accumulator setData:[NSData data]];

    PEXMergedInputStream * stream = [self getStream:streamNum];

    // We are running main thread -> run runloop.
    // We can't run the run loop unless it has an associated input source or a timer.
    // So we'll just create a timer that will never fire - unless the server runs for decades.
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                     target:self selector:@selector(ignore:) userInfo:nil repeats:YES];

    NSThread *currentThread = [NSThread currentThread];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    BOOL isCancelled = [currentThread isCancelled];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (unsigned long long)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [stream setDelegate:self];
        [stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
    });

    // Run the runloop.
    while (!_runloopQuit && !isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        isCancelled = [currentThread isCancelled];
    }

    dispatch_semaphore_wait(_readingFinished, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        [stream setDelegate:self];
        [stream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [stream close];
    });
    [self checkMis:stream idx:streamNum];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
            uint8_t *readBytes = (uint8_t *)[data mutableBytes];

            NSInteger len = [(NSInputStream *)aStream read:readBytes maxLength:[data length]];
            if (len == 0){
                return;
            } else if (len < 0){
                XCTFail(@"Stream reading error");
                return;
            }

            [_accumulator appendData:[NSData dataWithBytes:readBytes length:len]];
            break;
        }

        case NSStreamEventEndEncountered:
        {
            DDLogVerbose(@"Stream ended");
            _runloopQuit = YES;
            dispatch_semaphore_signal(_readingFinished);
            break;
        }

        default:
            break;
    };

}

@end
