//
//  PEXGuiFileUtils.m
//  Phonex
//
//  Created by Matej Oravec on 06/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import "PEXGuiFileUtils.h"
#import "PEXGuiUtils.h"
#import "PEXFileTypeHolder.h"

static const CGFloat DEFAULT_THUMBNAIL_SIZE_IN_POINTS = 160.0f;

static NSString * const PEX_FILE_TRANSFER_SUBFOLDER = @"fileTransfer";

@implementation PEXGuiFileRepresentation : NSObject

- (NSString *) description
{
    return [NSString stringWithFormat:@"%.2f %@", [self.sizeNumber doubleValue], self.abrevation];
}

- (NSString *) sizeAsString
{
    return [NSString stringWithFormat:@"%.0f", [self.sizeNumber doubleValue]];
}


@end

@implementation PEXGuiFileUtils

+ (CGImageRef) generateThumnailForFileUrlCG: (NSURL * const) url
{
    return [self generateThumnailForFileUrlCG:url maxSizeInPixels:nil];
}

+ (CGImageRef) generateThumnailForFileUrlCG: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels
{
    CGImageRef result = NULL;

    const PEXFileTypeHolder * const holder = [[PEXFileTypeHolder alloc] initWithFilename:url.path];

    if ([holder isImage])
        result = [self generateThumnailForImageFileUrlCG: url maxSizeInPixels: pixels];
    else
    if ([holder isMovie])
        result = [self generateThumnailForVideoFileUrlCG: url maxSizeInPixels: pixels];
    else
    if ([holder isPdf])
        result = [self generateThumnailForPdfFileUrlCG:url maxSizeInPixels:pixels];

    return result;
}

/**
* Attempts to generate a tumbnail from the first page of the PDF.
*/
+ (CGImageRef) generateThumnailForPdfFileUrlCG: (NSURL *) url maxSizeInPixels: (NSNumber * const) pixels
{
    UIImage * result;
    const CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);

    if (CGPDFDocumentGetNumberOfPages(pdfDocument) > 0)
    {
        const CGFloat maxSizeInPoints = pixels ?
                [PEXGuiUtils pixelsToPoints:pixels.floatValue] :
                DEFAULT_THUMBNAIL_SIZE_IN_POINTS;


        // released by document release
        const CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, 1);
        const CGRect pageSize = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);

        const CGFloat longestSide = (pageSize.size.width > pageSize.size.height) ?
                pageSize.size.width :
                pageSize.size.height;

        const CGFloat scaleIndex = longestSide / maxSizeInPoints;

        const CGRect thumbnailDim = CGRectMake(0.0f, 0.0f,
                pageSize.size.width / scaleIndex,
                pageSize.size.height / scaleIndex);

        UIGraphicsBeginImageContext(thumbnailDim.size);
        const CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);

        /* ADJUSTMENT START */

        CGContextTranslateCTM(context, 0.0f, thumbnailDim.size.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextSetGrayFillColor(context, 1.0f, 1.0f);
        CGContextFillRect(context, thumbnailDim);
        const CGAffineTransform pdfTransform =  CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, thumbnailDim, 0, true);
        CGContextConcatCTM(context, pdfTransform);

        /* ADJUSTMENT END */

        CGContextDrawPDFPage(context, page);

        result = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();
        CGContextRestoreGState(context);
    }

    CGPDFDocumentRelease(pdfDocument);

    return CGImageRetain(result.CGImage);
}

+ (CGImageRef) generateThumnailForVideoFileUrlCG: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels
{
    AVAsset * const asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator * const imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];

    if (pixels)
        imageGenerator.maximumSize = CGSizeMake(pixels.floatValue, pixels.floatValue);

    const CMTime time = CMTimeMake(1, 1);
    const CGImageRef result = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];

    return result;
}

+ (CGImageRef) generateThumnailForImageFileUrlCG: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels
{
    NSDictionary * const imageOptions = @{(NSString *) kCGImageSourceShouldCache : (id)kCFBooleanTrue};

    const CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef) imageOptions);

    if (!imageSource){
        DDLogError(@"Image source is NULL.");
        return NULL;
    }

    NSMutableDictionary * const thumbnailOptions = [[NSMutableDictionary alloc] init];
    thumbnailOptions[(NSString *) kCGImageSourceCreateThumbnailWithTransform] = (id) kCFBooleanTrue;
    thumbnailOptions[(NSString *) kCGImageSourceCreateThumbnailFromImageIfAbsent] = (id) kCFBooleanTrue;
    if (pixels)
        thumbnailOptions[(NSString *) kCGImageSourceThumbnailMaxPixelSize] = pixels;


    const CGImageRef result = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)((NSDictionary*)thumbnailOptions));
    CFRelease(imageSource);

    if (!result){
        DDLogDebug(@"Thumbnail image not created from image source.");
        return NULL;
    }

    return result;
}

+ (UIImage *) generateThumnailForFileUrl: (NSURL * const) url maxSizeInPixels: (NSNumber * const) pixels;
{
    const CGImageRef refImg = [self generateThumnailForFileUrlCG:url maxSizeInPixels:pixels];
    UIImage * const result = [[UIImage alloc] initWithCGImage:refImg];

    return result;
}

+ (UIImage *) generateThumnailFromFileUrlForItemView: (NSURL * const) url
{
    NSNumber * const pixels = @([PEXGuiUtils pointsToPixels:[PEXResValues getThumbnailSize]]);

    return [self generateThumnailForFileUrl:url maxSizeInPixels:pixels];
}

+ (bool) canGenerateThumbnail: (NSString * const) filename
{
    const PEXFileTypeHolder * const holder = [[PEXFileTypeHolder alloc] initWithFilename:filename];

    const bool result =
            ([holder isImage] ||
                    [holder isMovie] ||
                    [holder isPdf]);

    return result;
}

/////////

+ (bool) isAssetUrl: (NSURL * const) url
{
    return [[url scheme] isEqualToString:@"assets-library"];
}

+ (bool) isSavedUrl: (NSURL * const) url
{
    return [url.path rangeOfString:PEX_FILE_TRANSFER_SUBFOLDER].length != 0;
}

+ (NSURL *) refreshedSavedFileUrl: (NSURL * const)url
{
    return [NSURL fileURLWithPath:[self refreshedSavedFilePath:url.path]];
}

+ (NSString *) refreshedSavedFilePath: (NSString * const)path
{
    return [[PEXGuiFileUtils getFileTransferPath] stringByAppendingPathComponent:path.lastPathComponent];
}

+ (NSString *) getDocumentsPath
{
    return (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES))[0];
}

// Also create the
+ (NSString *) getFileTransferPath
{
    NSString * const result = [[[self getDocumentsPath] stringByAppendingPathComponent:PEX_FILE_TRANSFER_SUBFOLDER]
                               stringByAppendingPathComponent:[[PEXAppState instance] getPrivateData].username];


    // create if does not exit
    if (![[NSFileManager defaultManager] fileExistsAtPath:result])
        [[NSFileManager defaultManager] createDirectoryAtPath:result
                                  withIntermediateDirectories:NO attributes:nil error:nil];

    return result;
}

+ (PEXGuiFileRepresentation *) bytesToRepresentation: (const uint64_t) bytes
{
    static const uint64_t KILO = 1024ULL;
    static const uint64_t MEGA = 1024ULL * 1024ULL;
    static const uint64_t GIGA = 1024ULL * 1024ULL * 1024ULL;

    PEXGuiFileRepresentation * const result = [[PEXGuiFileRepresentation alloc] init];
    uint64_t divider = 1LL;

    if (bytes < KILO)
    {
        result.abrevation = @"B";
    }
    else if (bytes < MEGA)
    {
        result.abrevation = @"KB";
        divider = KILO;
    }
    else if (bytes < GIGA)
    {
        result.abrevation = @"MB";
        divider = MEGA;
    }
    else
    {
        result.abrevation = @"GB";
        divider = GIGA;
    }

    result.sizeNumber = (NSDecimalNumber*)[((NSDecimalNumber*)[NSDecimalNumber numberWithUnsignedLongLong:bytes]) decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithUnsignedLongLong:divider]];

    return result;
}

@end
