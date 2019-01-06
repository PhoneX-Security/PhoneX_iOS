//
//  PEXGuiFileUtils.h
//  Phonex
//
//  Created by Matej Oravec on 06/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXGuiFileRepresentation : NSObject

@property (nonatomic) NSString * abrevation;
@property (nonatomic) NSDecimalNumber * sizeNumber;

- (NSString *) sizeAsString;

@end

@interface PEXGuiFileUtils : NSObject

+ (CGImageRef) generateThumnailForFileUrlCG: (NSURL * const) url;
+ (CGImageRef) generateThumnailForFileUrlCG: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels;
+ (UIImage *) generateThumnailForFileUrl: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels;
+ (UIImage *)generateThumnailFromFileUrlForItemView: (NSURL * const) url;

+ (bool) canGenerateThumbnail: (NSString * const) filename;

+ (bool) isAssetUrl: (NSURL * const) url;
+ (bool) isSavedUrl: (NSURL * const) url;

+ (NSURL *) refreshedSavedFileUrl: (NSURL * const)url;
+ (NSString *) refreshedSavedFilePath: (NSString * const)path;

+ (NSString *) getDocumentsPath;
+ (NSString *) getFileTransferPath;

+ (PEXGuiFileRepresentation *) bytesToRepresentation: (const uint64_t) bytes;

@end
