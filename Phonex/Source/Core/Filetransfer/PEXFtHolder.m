//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtHolder.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXDH.h"
#import "PEXDhKeyHelper.h"
#import "PEXPbRest.pb.h"
#import "PEXCryptoUtils.h"
#import "PEXFtDownloader.h"
#import "PEXFileToSendEntry.h"


@implementation PEXFtHolder {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileIv = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _fileMac = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _fileHash = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _filePath = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _fileSize = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _filePrepRec = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _fileCipher = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _filePackPath = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _zipFiles = [NSMutableArray arrayWithCapacity:PEX_FTHOLDER_NUM_ELEMS];
        _fnames = [[NSMutableSet alloc] init];
        _orderedFnames = [[NSMutableArray alloc] init];
        [self resetFileData];
    }

    return self;
}

- (void)resetFileData {
    _fnameCollisionFound = NO;
    _srcFilesTotalSize   = 0;
    _thumbFilesTotalSize = 0;
    for(int i=0; i < PEX_FTHOLDER_NUM_ELEMS; i++){
        [_fileIv addObject:[NSNull null]];
        [_fileMac addObject:[NSNull null]];
        [_fileHash addObject:[NSNull null]];
        [_filePath addObject:[NSNull null]];
        [_fileSize addObject:[NSNull null]];
        [_filePrepRec addObject:[NSNull null]];
        [_fileCipher addObject:[NSNull null]];
        [_filePackPath addObject:[NSNull null]];
        [_zipFiles addObject:[NSNull null]];
    }

    [_fnames removeAllObjects];
    [_orderedFnames removeAllObjects];
}

- (NSData *)getGyData {
    if (_kp == nil || !_kp.isAllocated) {
        DDLogError(@"Cannot get DH public key! Nil encountered");
        return nil;
    }

    return [PEXCryptoUtils exportDHPublicKeyToDER:self.kp.getRaw];
}

@end

@implementation PEXFtFileEntry
- (instancetype)init {
    self = [super init];
    if (self) {
        self.size = 0;
        self.isAsset = NO;
        self.doGenerateThumb = YES;
    }

    return self;
}
@end

@implementation PEXFtUnpackingOptions
- (instancetype)init {
    self = [super init];
    if (self) {
        self.destinationDirectory = nil;
        self.createDirIfMissing = NO;
        self.actionOnConflict = PEX_FILECOPY_OVERWRITE;
        self.deleteArchiveOnSuccess = NO;
        self.deleteMetaOnSuccess = NO;
        self.deleteNewFilesOnException = YES;
        self.fnamePrefix = nil;
    }

    return self;
}

@end

@implementation PEXFtUnpackingResult
- (instancetype)init {
    self = [super init];
    if (self) {
        self.files = [[NSArray alloc] init];
        self.err = nil;
        self.exc = nil;
        self.finishedOK = NO;
    }

    return self;
}

@end

@implementation PEXFtUnpackingFile
- (instancetype)init {
    self = [super init];
    if (self) {
        self.destination = nil;
        self.originalFname = nil;
    }

    return self;
}

- (instancetype)initWithOriginalFname:(NSString *)originalFname destination:(NSString *)destination {
    self = [super init];
    if (self) {
        self.originalFname = originalFname;
        self.destination = destination;
    }

    return self;
}

+ (instancetype)fileWithOriginalFname:(NSString *)originalFname destination:(NSString *)destination {
    return [[self alloc] initWithOriginalFname:originalFname destination:destination];
}

@end

@implementation PEXFtUploadResult
- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.code=%li", (long)self.code];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendFormat:@", self.response=%@", self.response];
    [description appendFormat:@", self.error=%@", self.error];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.code = [coder decodeIntForKey:@"self.code"];
        self.message = [coder decodeObjectForKey:@"self.message"];
        self.uploaderFinishCode = [coder decodeIntForKey:@"self.uploaderFinishCode"];
        self.error = [coder decodeObjectForKey:@"self.error"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.code forKey:@"self.code"];
    [coder encodeObject:self.message forKey:@"self.message"];
    [coder encodeInt:self.uploaderFinishCode forKey:@"self.uploaderFinishCode"];
    [coder encodeObject:self.error forKey:@"self.error"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtUploadResult *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.code = self.code;
        copy.message = self.message;
        copy.uploaderFinishCode = self.uploaderFinishCode;
        copy.response = self.response;
        copy.error = self.error;
    }

    return copy;
}


@end

@implementation PEXFtFileDownloadResult
- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.code=%li", (long)self.code];
    [description appendFormat:@", self.downloaderFinishCode=%i", self.downloaderFinishCode];
    [description appendFormat:@", self.task=%@", self.task];
    [description appendFormat:@", self.error=%@", self.error];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.code = [coder decodeIntForKey:@"self.code"];
        self.downloaderFinishCode = [coder decodeIntForKey:@"self.downloaderFinishCode"];
        self.error = [coder decodeObjectForKey:@"self.error"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.code forKey:@"self.code"];
    [coder encodeInt:self.downloaderFinishCode forKey:@"self.downloaderFinishCode"];
    [coder encodeObject:self.error forKey:@"self.error"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtFileDownloadResult *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.code = self.code;
        copy.downloaderFinishCode = self.downloaderFinishCode;
        copy.task = self.task;
        copy.error = self.error;
    }

    return copy;
}


@end

@implementation PEXFtDownloadFile
- (instancetype)initWithMeta:(PEXPbMetaFileDetail *)meta {
    self = [super init];
    if (self) {
        _fileName       = meta.hasFileName  ? meta.fileName : nil;
        _extension      = meta.hasExtension ? meta.extension : nil;
        _mimeType       = meta.hasMimeType  ? meta.mimeType : nil;
        _fileSize       = meta.hasFileSize  ? @(meta.fileSize) : nil;
        _xhash          = meta.hasXhash     ? meta.xhash : nil;
        _prefOrder      = meta.hasPrefOrder ? @(meta.prefOrder) : nil;
        _thumbNameInZip = meta.hasThumbNameInZip ? meta.thumbNameInZip : nil;
        _title          = meta.hasTitle     ? meta.title : nil;
        _desc           = meta.hasDesc      ? meta.desc  : nil;
        _fileTimeMilli  = meta.hasFileTimeMilli  ? @(meta.fileTimeMilli) : nil;
    }

    return self;
}

+ (instancetype)fileWithMeta:(PEXPbMetaFileDetail *)meta {
    return [[self alloc] initWithMeta:meta];
}

@end

@implementation PEXFtPreUploadFilesHolder
@end
