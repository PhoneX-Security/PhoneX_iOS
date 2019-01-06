//
//  PEXChunkInputStreamTest.m
//  Phonex
//
//  Created by Dusan Klinec on 27.01.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXChunkInputStream.h"

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

@interface PEXChunkInputStreamTest : XCTestCase<NSStreamDelegate>
@property(nonatomic) PEXChunkInputStream * cis1;
@property(nonatomic) PEXChunkInputStream * cis2;
@property(nonatomic) int idx;

@property(nonatomic) dispatch_semaphore_t readingFinished;
@property(nonatomic) volatile BOOL runloopQuit;
@property(nonatomic) NSMutableData * accumulator;
@property(nonatomic) NSUInteger buffSize;
@property(nonatomic) NSThread * thread;
@end

@implementation PEXChunkInputStreamTest

- (void)setUp {
    [super setUp];
    _cis1 = [[PEXChunkInputStream alloc] initWithBodyBufferSize:19];
    _cis2 = [[PEXChunkInputStream alloc] init];

    _accumulator = [NSMutableData data];
    _runloopQuit = NO;
    _idx = 1;
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(genThreadMain:) object:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (PEXChunkInputStream *) getStream: (int) idx {
    if (idx == 1){
        return _cis1;
    } else if (idx == 2){
        return _cis2;
    } else {
        return nil;
    }
}

- (void)genThreadMain:(id)__unused object {
    PEXChunkInputStream * cis = [self getStream:_idx];
    [NSThread sleepForTimeInterval:0.015];

    // Write chunks
    NSData * dat = [bufferTestString dataUsingEncoding:NSASCIIStringEncoding];
    uint8_t const * bytes = [dat bytes];
    NSUInteger len = [dat length];
    NSInteger writtenTotal = 0;
    NSInteger written = 0;
    while(writtenTotal < len){
        written = [cis writeChunk:bytes + writtenTotal maxLength:len - writtenTotal writeAll:NO];
        if (written == 0){
            DDLogVerbose(@"Write returned 0");
            XCTFail("@Returned negative number of written bytes");
            return;

        } else if (written < 0){
            DDLogVerbose(@"Write returned negative, error.");
            XCTFail("@Returned negative number of written bytes");
            break;

        }

        writtenTotal += written;

        // Sleep for a while to simulate NSURLConnection behavior.
        [NSThread sleepForTimeInterval:0.0005];
    }

    // Now try to write same data but block until whole is written.
    written = [cis writeDataChunk:dat];
    XCTAssert(written == len, @"Written chunk is not equal to demanded write");

    // Now write several random pieces of data.
    NSData * data;

    data = [@"alpha ===== " dataUsingEncoding:NSASCIIStringEncoding];
    written = [cis writeDataChunk:data];
    XCTAssert(written == [data length], @"Written chunk is not equal to demanded write");
    [NSThread sleepForTimeInterval:0.1];

    data = [@"beta ----- " dataUsingEncoding:NSASCIIStringEncoding];
    written = [cis writeDataChunk:data];
    XCTAssert(written == [data length], @"Written chunk is not equal to demanded write");
    [NSThread sleepForTimeInterval:0.1];

    data = [@"gamma +++++ " dataUsingEncoding:NSASCIIStringEncoding];
    written = [cis writeDataChunk:data];
    XCTAssert(written == [data length], @"Written chunk is not equal to demanded write");
    [NSThread sleepForTimeInterval:0.1];

    // Will cause stream to end.
    [cis finishWrite];
}

-(void) checkMis: (PEXChunkInputStream *) stream idx: (int) idx {
    NSString *producedString = [[NSString alloc] initWithData:_accumulator encoding:NSASCIIStringEncoding];

    XCTAssert(producedString != nil && [producedString length] > 5, "Produced string is empty for idx: %d", idx);
    XCTAssert([producedString containsString:@"gamma +++++ "], "Result string does not contain gamma string");
    XCTAssert([producedString containsString:bufferTestString], "Result string does not contain test string");
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
        _buffSize = 64;
        [self pollingReading: 1];
        [self pollingReading: 2];
    }];
}

- (void)pollingReading: (int) streamNum {
    [self setUp];
    _idx = streamNum;
    [_thread start];

    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_accumulator setData:[NSData data]];

    PEXChunkInputStream * stream = [self getStream:streamNum];
    [stream open];

    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
    while(1){
//        if (![stream hasBytesAvailable]){
//            [NSThread sleepForTimeInterval:0.01];
//            continue;
//        }

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
    [self setUp];
    _idx = streamNum;
    _readingFinished = dispatch_semaphore_create(0);
    _runloopQuit = NO;
    [_accumulator setData:[NSData data]];

    PEXChunkInputStream * stream = [self getStream:streamNum];

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
        [_thread start];
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
