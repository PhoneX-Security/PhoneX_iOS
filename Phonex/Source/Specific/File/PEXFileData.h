//
//  PEXAssetData.h
//  Phonex
//
//  Created by Matej Oravec on 06/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PEXFileData : NSObject

@property (nonatomic) NSURL * url;
@property (nonatomic) NSString * filename;
@property (nonatomic, assign) int64_t size;
@property (nonatomic) UIImage * thumbnail;
@property (nonatomic) NSDate * date;
@property (nonatomic, assign) bool isAsset;

- (BOOL) isEqualToAssetData:(const PEXFileData * const)object;

+ (NSURL *) getRefreshedSavedUrlForUrl: (NSURL * const) lameUrl isAsset: (const bool) isAsset;

+ (PEXFileData *)fileDataFromUrl: (NSURL * const) url;

+ (PEXFileData *)fileDataNonAssetFromPath:(NSString * const)fullPath;
+ (PEXFileData *)fileDataNonAssetFromPath:(NSString *const)path filename: (NSString * const) filename;
+ (UIImage *)generateThumbnailForNonAsset: (NSString * const) fullPath;

+ (PEXFileData *)fileDataFromAsset: (ALAsset * const)asset;
+ (PEXFileData *)assetFileDataFromUrl:(NSURL * const) url;

@end
