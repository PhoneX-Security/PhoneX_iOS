//
// Created by Matej Oravec on 27/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXObjcZipWrap.h"
#import "ZipException.h"
#import "ZipWriteStream.h"
#import "ZipFile.h"


@implementation PEXObjcZipWrap {

}

+ (ZipFile *) createZipFile: (NSString * const) filepath
{
    ZipFile * result = nil;

    @try
    {
        result = [[ZipFile alloc] initWithFileName:filepath
                                              mode:ZipFileModeCreate
                                       allow64Mode:false];
    }
    @catch(ZipException * const exception)
    {
        DDLogWarn(@"Zipping: Creating zip file failed: %@", [exception description]);
        result = nil;
    }

    return result;
}

+ (bool) closeZipFile: (ZipFile * const) zipFile
{
    bool result = true;

    @try
    {
        [zipFile close];
    }
    @catch(ZipException * const exception)
    {
        DDLogWarn(@"Zipping: Creating zip file failed: %@", [exception description]);
        result = false;
    }

    return result;
}

+ (ZipWriteStream *) createZipStreamForFile: (ZipFile * const) zipFile
                        destinationFilename: (NSString * const) filename
{
    ZipWriteStream * result = nil;

    @try
    {
        result = [zipFile writeFileInZipWithName:filename
                                compressionLevel:ZipCompressionLevelBest];
    }
    @catch(ZipException * const exception)
    {
        DDLogWarn(@"Zipping files failed with exception: %@", [exception description]);
        result = nil;
    }

    return result;
}

+ (bool) writeData: (NSData * const) data toZipStream:(ZipWriteStream * const) stream
{
    bool result = true;

    @try
    {
        [stream writeData:data];
    }
    @catch(ZipException * const exception)
    {
        DDLogWarn(@"Zipping: writing data failed with exception: %@", [exception description]);
        result = false;
    }

    return result;
}

+ (bool) finishZipStream: (ZipWriteStream * const) zipStream
{
    bool result = true;

    @try
    {
        [zipStream finishedWriting];
    }
    @catch(ZipException * const exception)
    {
        DDLogWarn(@"Zipping: closing stream failed: %@", [exception description]);
        result = false;
    }

    return result;
}

@end