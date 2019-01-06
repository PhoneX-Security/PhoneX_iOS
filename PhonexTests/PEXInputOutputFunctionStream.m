//
//  PEXInputOutputFunctionStream.m
//  Phonex
//
//  Created by Dusan Klinec on 03.02.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXCopyInputStream.h"
#import "NSBundle+PEXResCrypto.h"
#import "PEXCipher.h"
#import "PEXAESCipher.h"
#import "PEXInputFunctionStream.h"
#import "PEXOutputFunctionStream.h"
#import "PEXStreamedCipher.h"
#import "PEXUtils.h"

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

@interface PEXInputOutputFunctionStream : XCTestCase
@property(nonatomic) NSData * inputDataTest;
@property(nonatomic) NSUInteger randomExtraChars;

@property(nonatomic) NSData * dataTest1;
@property(nonatomic) NSData * dataTest2;
@property(nonatomic) NSData * dataTest3;
@property(nonatomic) NSData * dataTest4;
@property(nonatomic) NSData * dh1;
@property(nonatomic) NSData * dh2;

@property(nonatomic) NSInputStream * fisDh1;
@property(nonatomic) NSInputStream * fisDh2;
@property(nonatomic) NSInputStream * fisAll;

@property(nonatomic) NSData * aesKey;
@property(nonatomic) NSData * aesIV;
@property(nonatomic) PEXCipher * cipEnc1;
@property(nonatomic) PEXCipher * cipEnc2;
@property(nonatomic) PEXCipher * cipEnc3;
@property(nonatomic) PEXCipher * cipDec1;
@property(nonatomic) PEXCipher * cipDec2;
@property(nonatomic) PEXCipher * cipDec3;

@property(nonatomic) dispatch_semaphore_t readingFinished;
@property(nonatomic) volatile BOOL runloopQuit;
@property(nonatomic) NSMutableData * accumulator;
@property(nonatomic) NSUInteger buffSize;
@property(nonatomic) NSUInteger idx;

@end

@implementation PEXInputOutputFunctionStream

- (void)setUp {
    [super setUp];
    srand(time(NULL));
    _dataTest1 = [@"alpha .... " dataUsingEncoding:NSASCIIStringEncoding];
    _dataTest2 = [@"beta  ==== " dataUsingEncoding:NSASCIIStringEncoding];
    _dataTest3 = [@"gamma ++++ " dataUsingEncoding:NSASCIIStringEncoding];
    _dataTest4 = [bufferTestString dataUsingEncoding:NSASCIIStringEncoding];
    _dh1 = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForDHGroupId:1]];
    _dh2 = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForDHGroupId:2]];

    NSMutableData * mutDat = [[NSMutableData alloc] init];
    [mutDat appendData:_dataTest1];
    [mutDat appendData:_dataTest2];
    [mutDat appendData:_dh1];
    [mutDat appendData:_dataTest4];
    [mutDat appendData:_dh1];
    [mutDat appendData:_dataTest3];
    _inputDataTest = [NSData dataWithData:mutDat];

    _fisDh1 = [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:1]];
    _fisDh2 = [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForDHGroupId:2]];
    _fisAll = [NSInputStream inputStreamWithData:_inputDataTest];

    _aesKey  = [PEXAESCipher generateKey];
    _aesIV   = [PEXAESCipher generateIV];
    _cipEnc1 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:YES key:_aesKey iv:_aesIV];
    _cipEnc2 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:YES key:_aesKey iv:_aesIV];
    _cipEnc3 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:YES key:_aesKey iv:_aesIV];
    _cipDec1 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:NO key:_aesKey iv:_aesIV];
    _cipDec2 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:NO key:_aesKey iv:_aesIV];
    _cipDec3 = [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:NO key:_aesKey iv:_aesIV];

    _accumulator = [NSMutableData data];
    _runloopQuit = NO;
    _idx = 1;
}

- (void)tearDown {
    [_fisDh1 close];
    [_fisDh2 close];
    [_fisAll close];
    [super tearDown];
}

-(NSInputStream *) getStream: (NSUInteger) idx {
    if (idx == 1){
        return _fisDh1;
    } else if (idx == 2){
        return _fisAll;
    }

    return nil;
}

- (NSData *) getTemplate: (NSUInteger) idx {
    if (idx == 1){
        return _dh1;
    } else if (idx == 2){
        return _inputDataTest;
    }

    return nil;
}

-(void) testPollingReading1{
    _buffSize = 1;
    [self pollingInputTest:1];
    [self pollingInputTest:2];
    [self pollingInputChainIdentityTest: 1];
    [self pollingInputChainIdentityTest: 2];
}

-(void) testPollingReading13{
    _buffSize = 13;
    [self pollingInputTest:1];
    [self pollingInputTest:2];
    [self pollingInputChainIdentityTest: 1];
    [self pollingInputChainIdentityTest: 2];
}

-(void) testPollingReading32{
    _buffSize = 32;
    [self pollingInputTest:1];
    [self pollingInputTest:2];
    [self pollingInputChainIdentityTest: 1];
    [self pollingInputChainIdentityTest: 2];
}

-(void) testPollingReading256{
    _buffSize = 256;
    [self pollingInputTest:1];
    [self pollingInputTest:2];
    [self pollingInputChainIdentityTest: 1];
    [self pollingInputChainIdentityTest: 2];
}

-(void) testPollingReadingHuge{
    _buffSize = 8048576;
    [self pollingInputTest:1];
    [self pollingInputTest:2];
    [self pollingInputChainIdentityTest: 1];
    [self pollingInputChainIdentityTest: 2];
}

- (void)pollingInputTest: (NSUInteger) streamNum {
    [self setUp];
    _idx = streamNum;
    NSUInteger internalBufferSize = (NSUInteger) (1 + (random() % 2049));

    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_accumulator setData:[NSData data]];

    NSInputStream * streamInp = [self getStream:streamNum];
    PEXInputFunctionStream * stream = [PEXInputFunctionStream streamWithCanceller:nil function:_cipEnc1 subStream:streamInp buffSize:internalBufferSize];
    [stream open];

    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
    for(;;){
        NSInteger read = [stream read:readBytes maxLength:_buffSize];
        if (read == 0){
            break;
        } else if (read < 0){
            XCTFail(@"Error reading stream");
            return;
        }

        [_accumulator appendData:[NSData dataWithBytes:readBytes length:(NSUInteger) read]];
    }

    // Encrypt template, compare ciphertexts.
    NSData * inputTemplate = [self getTemplate:_idx];
    PEXStreamedCipher * scipEnc = [PEXStreamedCipher cipherWithCip:_cipEnc2 canceller:nil progressMonitor:nil buffSize:2048];
    NSData * ciphertext2 = [scipEnc doCipher:inputTemplate];
    /*DDLogVerbose(@"\nCip1[%d]: %@\nCip2[%d]: %@\n",
            [_accumulator length], [PEXUtils bytesToHex:_accumulator maxLen:128],
            [ciphertext2 length],  [PEXUtils bytesToHex:ciphertext2 maxLen:128]);
    [DDLog flushLog];*/
    XCTAssert([ciphertext2 isEqualToData:_accumulator], @"Ciphertext does not match");

    // Decrypt now.
    PEXStreamedCipher * scipDec = [PEXStreamedCipher cipherWithCip:_cipDec1 canceller:nil progressMonitor:nil buffSize:2048];
    NSData * decrypted = [scipDec doCipher:_accumulator];
    /*DDLogVerbose(@"\nDec1[%d]: %@\nOrig[%d]: %@\n",
            [decrypted length],     [PEXUtils bytesToHex:decrypted maxLen:128],
            [inputTemplate length], [PEXUtils bytesToHex:inputTemplate maxLen:128]);
    [DDLog flushLog]; */
    XCTAssert([inputTemplate isEqualToData:decrypted], @"Cannot decrypt encrypted.");
}

-(void) pollingInputChainIdentityTest: (NSUInteger) idx {
    [self setUp];
    _idx = idx;

    NSUInteger internalBufferSize1 = (NSUInteger) (1 + (random() % 2049));
    NSUInteger internalBufferSize2 = (NSUInteger) (1 + (random() % 2049));

    NSMutableData * data = [NSMutableData dataWithLength:_buffSize];
    [_accumulator setData:[NSData data]];

    NSInputStream * streamInp = [self getStream:idx];
    PEXInputFunctionStream * streamEnc = [PEXInputFunctionStream streamWithCanceller:nil function:_cipEnc1 subStream:streamInp buffSize:internalBufferSize1];
    PEXInputFunctionStream * streamDec = [PEXInputFunctionStream streamWithCanceller:nil function:_cipDec1 subStream:streamEnc buffSize:internalBufferSize2];
    [streamDec open];

    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
    for(;;){
        NSInteger read = [streamDec read:readBytes maxLength:[data length]];
        if (read == 0){
            break;
        } else if (read < 0){
            XCTFail(@"Error reading stream");
            return;
        }

        [_accumulator appendData:[NSData dataWithBytes:readBytes length:(NSUInteger) read]];
    }

    // Compare to plaintext template
    NSData * inputTemplate = [self getTemplate:_idx];
    XCTAssert([inputTemplate isEqualToData:_accumulator], @"Identity was not obtained.");
}

-(void) testPollingWriting1{
    _buffSize = 1;
    [self pollingOutputTest:1];
    [self pollingOutputTest:2];
}

-(void) testPollingWriting13{
    _buffSize = 13;
    [self pollingOutputTest:1];
    [self pollingOutputTest:2];
}

-(void) testPollingWriting32{
    _buffSize = 32;
    [self pollingOutputTest:1];
    [self pollingOutputTest:2];
}

-(void) testPollingWriting256{
    _buffSize = 256;
    [self pollingOutputTest:1];
    [self pollingOutputTest:2];
}

-(void) testPollingWritingHuge{
    _buffSize = 8048576;
    [self pollingOutputTest:1];
    [self pollingOutputTest:2];
}

- (void) pollingOutputTest: (NSUInteger) streamNum {
    [self setUp];
    _idx = streamNum;
    NSUInteger internalBufferSize = (NSUInteger) (1 + (random() % 2049));
    [_accumulator setData:[NSData data]];

    NSData * template = [self getTemplate:_idx];
    NSOutputStream * outStream = [NSOutputStream outputStreamToMemory];
    PEXOutputFunctionStream * stream = [PEXOutputFunctionStream streamWithCanceller:nil function:_cipEnc1 subStream:outStream buffSize:internalBufferSize];
    [stream open];

    const NSInteger dataLen = [template length];
    uint8_t * bytes = (uint8_t *)[template bytes];
    NSInteger totalWritten = 0;
    for(;(dataLen-totalWritten) > 0;){
        NSInteger written = [stream write:bytes+totalWritten maxLength:(NSUInteger)(dataLen-totalWritten)];
        if (written == 0){
            break;
        } else if (written < 0){
            XCTFail(@"Error reading stream");
            return;
        }

        totalWritten+=written;
    }
    [stream flush];
    [stream closeData];

    NSData * writtenBytes = [outStream propertyForKey: NSStreamDataWrittenToMemoryStreamKey];

    // Encrypt template, compare ciphertexts.
    PEXStreamedCipher * scipEnc = [PEXStreamedCipher cipherWithCip:_cipEnc2 canceller:nil progressMonitor:nil buffSize:2048];
    NSData * ciphertext2 = [scipEnc doCipher:template];
    XCTAssert([ciphertext2 isEqualToData:writtenBytes], @"Ciphertext does not match");
}

@end
