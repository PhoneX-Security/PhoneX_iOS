//
// Created by Matej Oravec on 27/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZipWriteStream;
@class ZipFile;

// All Objective-Zip methods throw so here is a wrapper alternative complying noexcept

@interface PEXObjcZipWrap : NSObject

+ (ZipFile *) createZipFile: (NSString * const) filepath;
+ (bool) closeZipFile: (ZipFile * const) zipFile;
+ (ZipWriteStream *) createZipStreamForFile: (ZipFile * const) zipFile
                        destinationFilename: (NSString * const) filename;
+ (bool) writeData: (NSData * const) data toZipStream:(ZipWriteStream * const) stream;
+ (bool) finishZipStream: (ZipWriteStream * const) zipStream;

@end