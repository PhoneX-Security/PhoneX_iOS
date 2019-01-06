//
//  PEXCopyInputStreamTest.m
//  Phonex
//
//  Created by Dusan Klinec on 26.01.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXCopyInputStream.h"
#import "NSBundle+PEXResCrypto.h"
#import "PEXResCrypto.h"

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

@interface PEXCopyInputStreamTest : XCTestCase<NSStreamDelegate>
@property(nonatomic) PEXCopyInputStream * cis1;
@property(nonatomic) PEXCopyInputStream * cis2;
@property(nonatomic) NSString * cis2DesiredString;

@property(nonatomic) dispatch_semaphore_t readingFinished;
@property(nonatomic) volatile BOOL runloopQuit;
@property(nonatomic) NSMutableData * accumulator;
@property(nonatomic) NSUInteger buffSize;
@end

@implementation PEXCopyInputStreamTest

- (void)setUp {
    [super setUp];
    _cis1 = [[PEXCopyInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:[bufferTestString dataUsingEncoding:NSASCIIStringEncoding]]];
    _cis2 = [[PEXCopyInputStream alloc] initWithStream:[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:1]]];
    _cis2DesiredString = [[NSString alloc] initWithData:[PEXResCrypto loadDHGroupId:1] encoding:NSASCIIStringEncoding];
    _accumulator = [NSMutableData data];
    _runloopQuit = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) checkMis: (PEXCopyInputStream *) stream idx: (int) idx {
    NSString * proucedString = [[NSString alloc] initWithData:_accumulator encoding:NSASCIIStringEncoding];
    NSString * copyString = [[NSString alloc] initWithData:[stream getData] encoding:NSASCIIStringEncoding];
    NSString const * desiredString = idx == 1 ? bufferTestString : _cis2DesiredString;

    XCTAssert(proucedString != nil && [proucedString length] > 0, "Produced string is empty for idx: %d", idx);
    XCTAssert(copyString != nil && [copyString length] > 0, "Copy string is empty for idx: %d", idx);
    XCTAssert([proucedString isEqualToString:copyString], "Copying is not working properly for idx: %d", idx);
    XCTAssert([proucedString isEqualToString:desiredString], "Reading does not work properly for idx: %d", idx);
}

-(void) testPollingReading1{
    _buffSize = 1;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

-(void) testPollingReading13{
    _buffSize = 13;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

-(void) testPollingReading17{
    _buffSize = 17;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

-(void) testPollingReading32{
    _buffSize = 32;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

-(void) testPollingReading256{
    _buffSize = 256;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

-(void) testPollingReadingHuge{
    _buffSize = 8048576;
    [self pollingReading: 1];
    [self pollingReading: 2];
}

- (void)testPollingReadingPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        [self setUp];
        _buffSize = 32;
        [self pollingReading: 1];
        [self pollingReading: 2];
    }];
}

- (void)pollingReading: (int) streamNum {
    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_accumulator setData:[NSData data]];

    PEXCopyInputStream * stream = streamNum == 1 ? _cis1 : _cis2;
    stream.copyStream = YES;
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
}

-(void) testRunloopReading13{
    _buffSize = 13;
    [self runloopReading: 1];
    [self runloopReading: 2];
}

-(void) testRunloopReading17{
    _buffSize = 17;
    [self runloopReading: 1];
    [self runloopReading: 2];
}

-(void) testRunloopReading32{
    _buffSize = 32;
    [self runloopReading: 1];
    [self runloopReading: 2];
}

-(void) testRunloopReading256{
    _buffSize = 256;
    [self runloopReading: 1];
    [self runloopReading: 2];
}

-(void) testRunloopReadingHuge{
    _buffSize = 8048576;
    [self runloopReading: 1];
    [self runloopReading: 2];
}

- (void)runloopReading: (int) streamNum {
    _readingFinished = dispatch_semaphore_create(0);
    _runloopQuit = NO;
    [_accumulator setData:[NSData data]];

    PEXCopyInputStream * stream = streamNum == 1 ? _cis1 : _cis2;

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
        stream.copyStream = YES;
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
