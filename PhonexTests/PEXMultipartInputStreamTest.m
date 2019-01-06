//
//  PEXMultipartInputStreamTest.m
//  Phonex
//
//  Created by Dusan Klinec on 25.01.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXMultipartElement.h"
#import "PEXMultipartUploadStream.h"
#import "NSBundle+PEXResCrypto.h"
#import "PEXResCrypto.h"

@interface PEXMultipartInputStreamTest : XCTestCase<NSStreamDelegate>
@property(nonatomic) PEXMultipartUploadStream * mis;
@property(nonatomic) dispatch_semaphore_t readingFinished;
@property(nonatomic) volatile BOOL runloopQuit;
@property(nonatomic) NSMutableData * accumulator;
@property(nonatomic) NSUInteger buffSize;
@end

@implementation PEXMultipartInputStreamTest

- (void)setUp {
    [super setUp];

    // Set data accumulator;
    _accumulator = [NSMutableData data];

    // Set input stream.
    _mis = [[PEXMultipartUploadStream alloc] init];
    _runloopQuit = NO;

    // Add parts.
    PEXMultipartElement * e = nil;

    e = [[PEXMultipartElement alloc] initWithName:@"field1" boundary:_mis.boundary string:@"data1"];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field2" boundary:_mis.boundary string:@"data2"];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field3" boundary:_mis.boundary data:[NSData data] contentType:@"application/octet-stream"];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field4" boundary:_mis.boundary data:[@"test" dataUsingEncoding:NSASCIIStringEncoding] contentType:@"application/octet-stream" filename:@"file4.txt"];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field5" filename:@"group1" boundary:_mis.boundary
                                       stream:[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:1]]];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field6" filename:@"group2" boundary:_mis.boundary
                                       stream:[NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:2]]];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field7" boundary:_mis.boundary data:[NSData data] contentType:@"application/octet-stream"];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field8" filename:@"group3" boundary:_mis.boundary
                                       stream:[NSInputStream inputStreamWithData:[PEXResCrypto loadDHGroupId:3]]];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field9" filename:@"group4" boundary:_mis.boundary
                                         path:[[NSBundle mainBundle] pathForDHGroupId:4]];
    [_mis addPart:e];

    e = [[PEXMultipartElement alloc] initWithName:@"field10" boundary:_mis.boundary data:[NSData data] contentType:@"application/octet-stream"];
    [_mis addPart:e];

}

- (void)tearDown {
    [super tearDown];
}

-(void) checkMis: (NSString *) proucedString {
    // Contains fieldX?
    for(int i=1; i<=10; i++){
        NSString * fieldName = [NSString stringWithFormat:@"field%d", i];
        XCTAssert([proucedString containsString:fieldName], "Does not contain %@", fieldName);
    }

    // Some body data.
    XCTAssert([proucedString containsString:@"group2"], "Does not contain group2");
    XCTAssert([proucedString containsString:@"group4"], "Does not contain group4");
    XCTAssert([proucedString containsString:@"test"], "Does not contain test");
    XCTAssert([proucedString containsString:@"data1"], "Does not contain data1");
    XCTAssert([proucedString containsString:@"data2"], "Does not contain data2");
    XCTAssert([proucedString containsString:@"octet"], "Does not contain octet");
    XCTAssert([proucedString containsString:@"-----BEGIN"], "Does not contain -----BEGIN");
    XCTAssert([proucedString containsString:@"-----END"], "Does not contain -----END");
    XCTAssert([proucedString containsString:@"PARAMETERS-----"], "Does not contain PARAMETERS-----");

    // Hard final test, character exact.
    XCTAssertEqual(4562, [proucedString length], "Produced data length does not match");
}

-(void) testPollingReading1{
    _buffSize = 1;
    [self pollingReading];
}

-(void) testPollingReading13{
    _buffSize = 13;
    [self pollingReading];
}

-(void) testPollingReading17{
    _buffSize = 17;
    [self pollingReading];
}

-(void) testPollingReading32{
    _buffSize = 32;
    [self pollingReading];
}

-(void) testPollingReading256{
    _buffSize = 256;
    [self pollingReading];
}

-(void) testPollingReadingHuge{
    _buffSize = 8048576;
    [self pollingReading];
}

- (void)testPollingReadingPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        _buffSize = 32;
        [self pollingReading];
    }];
}

- (void)pollingReading {
    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_mis open];

    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
    while(1){
        if (![_mis hasBytesAvailable]){
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }

        NSInteger read = [_mis read:readBytes maxLength:[data length]];
        if (read == 0){
            break;
        } else if (read < 0){
            XCTFail(@"Error reading stream");
            return;
        }

        [_accumulator appendData:[NSData dataWithBytes:readBytes length:(NSUInteger) read]];
    }

    NSString * proucedString = [[NSString alloc] initWithData:_accumulator encoding:NSASCIIStringEncoding];
    [_mis close];
    [self checkMis:proucedString];
}

- (void) ignore:(id)_ {

}

-(void) testRunloopReading1{
    _buffSize = 1;
    [self runloopReading];
}

-(void) testRunloopReading13{
    _buffSize = 13;
    [self runloopReading];
}

-(void) testRunloopReading17{
    _buffSize = 17;
    [self runloopReading];
}

-(void) testRunloopReading32{
    _buffSize = 32;
    [self runloopReading];
}

-(void) testRunloopReading256{
    _buffSize = 256;
    [self runloopReading];
}

-(void) testRunloopReadingHuge{
    _buffSize = 8048576;
    [self runloopReading];
}

- (void)runloopReading {
    _readingFinished = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_main_queue(), ^{
        [_mis setDelegate:self];
        [_mis scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_mis open];
    });

    // We are running main thread -> run runloop.
    // We can't run the run loop unless it has an associated input source or a timer.
    // So we'll just create a timer that will never fire - unless the server runs for decades.
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                     target:self selector:@selector(ignore:) userInfo:nil repeats:YES];

    NSThread *currentThread = [NSThread currentThread];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    BOOL isCancelled = [currentThread isCancelled];
    while (!_runloopQuit && !isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        isCancelled = [currentThread isCancelled];
    }

    dispatch_semaphore_wait(_readingFinished, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mis setDelegate:self];
        [_mis removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_mis close];
    });

    NSString * proucedString = [[NSString alloc] initWithData:_accumulator encoding:NSASCIIStringEncoding];
    [self checkMis:proucedString];
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
            _runloopQuit = YES;
            dispatch_semaphore_signal(_readingFinished);
            break;
        }

        default:
            break;
    };

}

@end
