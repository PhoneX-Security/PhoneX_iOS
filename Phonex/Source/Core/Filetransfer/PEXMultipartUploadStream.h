//
// Created by Dusan Klinec on 23.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//
//
// Inspiration sources:
// https://github.com/pyke369/PKMultipartInputStream/blob/master/PKMultipartInputStream.m
// http://bjhomer.blogspot.cz/2011/04/subclassing-nsinputstream.html
// http://blog.octiplex.com/2011/06/how-to-implement-a-corefoundation-toll-free-bridged-nsinputstream-subclass/
//

#import <Foundation/Foundation.h>
#import "PEXMultipartElement.h"

@class PEXMultipartElement;
@class PEXMultipartUploadStream;

/**
* Block for stream read state reporting.
*/
typedef void (^MultipartProgressBlock)(PEXMultipartUploadStream * str, NSInteger read);

/**
* Input stream for POST mutipart HTTP request.
* Can contain multiple entities - PEXMultipartElement.
* Stream has to have at least one element.
*
* Reading from this stream gives properly formatted POST multipart HTTP request body.
* Elements can contain data specified by: NSString, NSData, filename, NSInputStream.
*/
@interface PEXMultipartUploadStream : PEXRunLoopInputStream<NSStreamDelegate>
@property (nonatomic, readonly) NSString *boundary;

/**
* Total length of the input stream.
* If stream contains parts with unknown length this field is subject to change
* during reading as indeterminate parts are read.
*/
@property (nonatomic, readonly) int64_t length;

/**
* Current part being streamed.
*/
@property (nonatomic, readonly) NSUInteger currentPart;

/**
* Number of bytes already read from this stream.
* Should hold: delivered <= length.
*/
@property (nonatomic, readonly) int64_t delivered;

/**
* Total size of all parts together.
*/
@property (nonatomic, readonly) int64_t totalStreamSize;

/**
* YES value signalizes stream was read completely and there is no data left.
*/
@property (nonatomic, readonly) BOOL allDataWritten;

/**
* YES value indicates there is a part in the request with unknown size (i.e., stream with unknown length).
*/
@property (nonatomic, readonly) BOOL indeterminatePart;

/**
* Monitoring progress for the whole stream.
*/
@property(nonatomic, copy) MultipartProgressBlock progressBlock;

/**
* Monitoring progress of individual parts.
*/
@property(nonatomic, copy) MultipartElementProgressBlock elementProgressBlock;

/**
* Add PEXMultipartElement to the multipart request body.
*/
- (void)addPart: (PEXMultipartElement *) part;

/**
* Method re-generates boundary string for request.
*/
- (NSString *)generateBoundary;

/**
* Sets boundary to a given value and regenerates boundary parts.
*/
- (void)setNewBoundary: (NSString *) aBoundary;

/**
* Calling this method causes error in this reading stream.
* Can be used to cancel reading forcefully.
*/
-(void) cancelStreamByError: (NSError *) e;

/**
* Returns copy of the internal array with parts.
*/
-(NSArray *) getParts;

/**
* Adds a simple multipart element to the stream with given name and data.
* Content type is defined as text/plain;charset=utf8 thus data have to be text encoded into NSData.
*/
- (PEXMultipartElement *)writeStringToStream:(NSString *) key data: (NSData *) data;

/**
* Adds a simple multipart element to the stream with given name and a given string.
*/
- (PEXMultipartElement *)writeStringToStream:(NSString *) key string: (NSString *) string;
@end