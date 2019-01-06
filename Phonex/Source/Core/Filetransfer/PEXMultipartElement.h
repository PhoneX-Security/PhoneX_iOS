//
// Created by Dusan Klinec on 24.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"

FOUNDATION_EXPORT NSString * PEX_CONTENT_TYPE_TEXT;
FOUNDATION_EXPORT NSString * PEX_CONTENT_TYPE_OCTET;

@class PEXMultipartElement;

/**
* Block to inform about reading progress of the multipart element.
*/
typedef void (^MultipartElementProgressBlock)(PEXMultipartElement * e, NSInteger read, int64_t totalLength, int64_t deliveredLength, BOOL indeterminate);

/**
* InputStream providing single Multipart element.
*
* Reading this stream gives a properly formatted element to the multipart request.
* Used in PEXMultipartUploadStream.
*/
@interface PEXMultipartElement : PEXRunLoopInputStream<NSStreamDelegate>
/**
* User can set this tag to the element so (s)he can identity it in progress callbacks & so on.
*/
@property(nonatomic) NSUInteger tag;

/**
* Index assigned by the upload stream, set when adding to the upload stream.
*/
@property(nonatomic) NSUInteger idx;

/**
* Stream body of the element used for reading.Stream body of the element used for reading.
*/
@property(nonatomic, readonly) NSInputStream * body;

/**
* Length of the headers part.
*/
@property(nonatomic, readonly) NSUInteger headersLength;

/**
* YES if the final size of this stream is not known prior reading.
*/
@property(nonatomic, readonly) BOOL sizeUnknown;

/**
* Total length of the stream. This value might change during reading
* if total size of the body stream was unknown prior reading.
*/
@property(nonatomic, readonly) int64_t length;

/**
* Number of bytes read from the stream.
*/
@property(nonatomic, readonly) int64_t delivered;

/**
* Number of bytes in the body stream. May change during reading.
*/
@property(nonatomic, readonly) int64_t bodyLength;

/**
* Block for reading progress monitoring.
*/
@property(nonatomic, copy) MultipartElementProgressBlock progressBlock;

- (id)initWithName:(NSString *)name boundary:(NSString *)boundary string:(NSString *)string;
- (id)initWithName:(NSString *)name boundary:(NSString *)boundary data:(NSData *)data contentType:(NSString *)contentType;
- (id)initWithName:(NSString *)name boundary:(NSString *)boundary data:(NSData *)data contentType:(NSString *)contentType filename:(NSString*)filename;
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary path:(NSString *)path;
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary stream:(NSInputStream *)stream streamLength:(NSUInteger)streamLength;
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary stream:(NSInputStream *)stream;

-(BOOL) isWritingHeaderData;
-(BOOL) isWritingStreamData;
-(BOOL) isWritingFooterData;

@end
