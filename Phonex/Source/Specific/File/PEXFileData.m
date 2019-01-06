//
//  PEXAssetData.m
//  Phonex
//
//  Created by Matej Oravec on 06/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "PEXFileData.h"
#import "PEXGuiFileUtils.h"
#import "PEXBlockThread.h"
#import "PEXAssetLibraryManager.h"

@implementation PEXFileData

// return nil if saved is unreachable
+ (NSURL *) getRefreshedSavedUrlForUrl: (NSURL * const) lameUrl isAsset: (const bool) isAsset
{
    NSURL * result;

    if (lameUrl)
    {
        NSURL * const url = (isAsset) ?
                lameUrl :
                [NSURL fileURLWithPath:lameUrl.path];

        if (url) {
            // When saved, the path to our app may be changed by restart,
            // so we need to refresh the URL
            // else try to open Asset or external file ... we cant do much about their paths
            if ([PEXGuiFileUtils isSavedUrl:url])
                result = [PEXGuiFileUtils refreshedSavedFileUrl:url];
            else
                result = url;
        }
    }

    return result;
}

+ (PEXFileData *)fileDataFromUrl: (NSURL * const) url
{
    return ([PEXGuiFileUtils isAssetUrl:url]) ?
            [self assetFileDataFromUrl:url] :
            [self fileDataNonAssetFromPath:url.path];
}

+ (PEXFileData *)fileDataNonAssetFromPath:(NSString * const)fullPath
{
    return [self fileDataNonAssetFromPath:[fullPath stringByDeletingLastPathComponent] filename:fullPath.lastPathComponent];
}

+ (PEXFileData *)fileDataNonAssetFromPath:(NSString *const)path filename: (NSString * const) filename
{
    PEXFileData *result;

    NSString * const fullPath = [path stringByAppendingPathComponent:filename];

    NSDictionary * const attrs = [[NSFileManager defaultManager]
            attributesOfItemAtPath:fullPath error:nil];
    if (attrs != nil)
    {
        result = [[PEXFileData alloc] init];
        result.date = attrs[NSFileCreationDate];
        result.thumbnail = [self generateThumbnailForNonAsset:fullPath];
        result.filename = filename;
        result.size = [((NSNumber*) attrs[NSFileSize]) unsignedLongLongValue];
        result.url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:filename]];
        result.isAsset = false;
    }
    else
    {
        // not found
        // cannot happen?
    }

    return result;
}

+ (UIImage *)generateThumbnailForNonAsset: (NSString * const) fullPath
{
    UIImage * result;

    if ([PEXGuiFileUtils canGenerateThumbnail:fullPath])
    {
        UIImage * const imageThumbnail =
                [PEXGuiFileUtils generateThumnailFromFileUrlForItemView:[NSURL fileURLWithPath:fullPath]];

        if (imageThumbnail) {
            result = imageThumbnail;
        }
        else
            result = PEXImg(@"file");
    }
    else
    {
        result = PEXImg(@"file");
    }

    return result;
}

+ (PEXFileData *)assetFileDataFromUrl:(NSURL * const) url
{
    ALAssetsLibrary * const assetsLibrary = [[PEXAssetLibraryManager instance] getAssetLibrary];

    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError * assetsError = nil;
    __block PEXFileData * result;

    // Load asset from library.
    WEAKSELF;
    PEXBlockThread * const thread = [[PEXBlockThread alloc] initWithBlock:^{
        [assetsLibrary assetForURL:url
                       resultBlock:^(ALAsset *asset) {
                           result = [weakSelf fileDataFromAsset:asset];
                           dispatch_semaphore_signal(semaphore);
                       }
                      failureBlock:^(NSError *error) {
                          assetsError = error;
                          dispatch_semaphore_signal(semaphore);
                      }
        ];
    }];
    [thread start];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    [[PEXAssetLibraryManager instance] releaseAssetLibrary];

    return result;
}

+ (PEXFileData *)fileDataFromAsset: (ALAsset * const)asset
{
    PEXFileData * const result = [[PEXFileData alloc] init];
    result.date = [asset valueForProperty:ALAssetPropertyDate];
    // alternativelly with ALAssetRepresentation::metaDat

    result.thumbnail = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];

    const ALAssetRepresentation * const assetRepresentation = [asset defaultRepresentation];
    result.filename = [assetRepresentation filename];
    result.size = [assetRepresentation size];
    result.url = assetRepresentation.url;
    result.isAsset = true;

    return result;
}

- (BOOL) isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToAssetData:other];
}

- (BOOL) isEqualToAssetData:(const PEXFileData * const)object
{
    if (self == object)
        return YES;
    if (object == nil)
        return NO;
    if (self.url != object.url && ![self.url.absoluteString isEqualToString:object.url.absoluteString])
        return NO;
    return YES;
}

@end
