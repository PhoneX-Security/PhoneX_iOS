//
// Created by Dusan Klinec on 27.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXFileToSendEntry : NSObject <NSCoding, NSCopying>
/**
* Mandatory part identifying particular file to send.
*/
@property(nonatomic) NSURL * file;
@property(nonatomic) BOOL isAsset;

@property(nonatomic) NSString * origFileName;
@property(nonatomic) int64_t origSize;

/**
* Preferred file name to be used, if original one is not suitable.
* If nil, original one is used.
*/
@property(nonatomic) NSString * prefFileName;

/**
* Preferred MIME type to be used. Can signalize voice message and other message types.
* If nil, mime type will be automatically detected from file.
*/
@property(nonatomic) NSString * mimeType;

/**
* Should file transfer generate thumb for this file if it is able to do it?
*/
@property(nonatomic) BOOL doGenerateThumbIfPossible;

/**
* Datetime to be associated with send file.
* If nil, original one is taken.
*/
@property(nonatomic) NSDate * fileDate;

/**
* Title directly associated to this file.
*/
@property(nonatomic) NSString * title;

/**
* Description associated to this file.
*/
@property(nonatomic) NSString * desc;

- (instancetype)initWithFile:(NSString *)file;
+ (instancetype)entryWithFile:(NSString *)file;
- (instancetype)initWithURL:(NSURL *)url;
+ (instancetype)entryWithURL:(NSURL *)url;
- (instancetype)initWithFile:(NSURL *)file isAsset:(BOOL)isAsset;
+ (instancetype)entryWithFile:(NSURL *)file isAsset:(BOOL)isAsset;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToEntry:(PEXFileToSendEntry *)entry;
- (NSUInteger)hash;
- (NSString *)description;

@end