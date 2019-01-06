//
// Created by Matej Oravec on 09/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "PEXFileTypeHolder.h"

@interface PEXFileTypeHolder ()

@property (nonatomic) NSString * fileUTI;

@end


@implementation PEXFileTypeHolder {

}

- (id) initWithFilename: (NSString * const) filename
{
    self = [super init];

    const CFStringRef fileExtension = (__bridge CFStringRef) [filename pathExtension];
    self.fileUTI = (__bridge_transfer id)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

    return self;
}

- (bool) isImage
{
    return UTTypeConformsTo((__bridge CFStringRef)self.fileUTI, kUTTypeImage);
}

- (bool) isMovie
{
    return UTTypeConformsTo((__bridge CFStringRef)self.fileUTI, kUTTypeMovie);
}

- (bool) isPdf
{
    return UTTypeConformsTo((__bridge CFStringRef)self.fileUTI, kUTTypePDF);
}

- (void) releaseResources
{
    if (self.fileUTI)
    {
        self.fileUTI = nil;
    }
}

- (void) dealloc
{
    [self releaseResources];
}

@end