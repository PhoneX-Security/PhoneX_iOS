//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDhKeyHelper.h"

@class PEXPbUploadFileXb;
@class PEXDH;
@class PEXPbRESTUploadPost;
@class PEXFtDownloader;
@class PEXFileToSendEntry;
@class PEXPbMetaFileDetailBuilder;
@class PEXPbMetaFileDetail;

// Number of main elements in file transfer protocol. (Meta archive, archive).
#define PEX_FTHOLDER_NUM_ELEMS 2

/**
* Class stores file transfer protocol dependent data.
*
* @author ph4r05
*
*/
@interface PEXFtHolder : NSObject
@property(nonatomic) NSData * saltb; //byte[]
@property(nonatomic) NSData * nonceb; //byte[]
@property(nonatomic) PEXDH * kp; //KeyPair
@property(nonatomic) NSData * c; //byte[]
@property(nonatomic) NSData * salt1; //byte[]
@property(nonatomic) NSMutableArray * ci; //byte[][]
@property(nonatomic) NSData * MB; //byte[]
@property(nonatomic) PEXPbUploadFileXb * XB; //UploadFileXb
@property(nonatomic) NSData * encXB; //byte[]
@property(nonatomic) NSData * macEncXB; //byte[]
@property(nonatomic) NSData * nonce2; //byte[]

// Aux data for uploader. Redundant field, to enable easy serialization and upload resumption.
@property(nonatomic) NSData * ukeyData; // PEXPbUploadFileKey, codedToNSData.

// Not required for crypto operation.
@property(nonatomic) NSString * nonce1; // base64encoded.

// Meta and archive files. MetaIdx=0, archiveIdx=1
@property(nonatomic) NSMutableArray * fileIv; //byte[][]
@property(nonatomic) NSMutableArray * fileMac; //byte[][]
@property(nonatomic) NSMutableArray * fileHash; //byte[][]

@property(nonatomic) NSMutableArray * filePath; //NSString[], Path to the already created file (encrypted).
@property(nonatomic) NSMutableArray * fileSize; //long[], Just informative for progress bar during sending.
@property(nonatomic) NSMutableArray * filePrepRec; //long[], File prepend record containing IV and MAC.

@property(nonatomic) uint64_t srcFilesTotalSize;
@property(nonatomic) uint64_t thumbFilesTotalSize;
@property(nonatomic) NSMutableArray * fileCipher; //PEXCipher[]
@property(nonatomic) NSMutableArray * filePackPath; //NSString[], Path to the ZIP files
@property(nonatomic) NSMutableArray * zipFiles; //ZipFile[].
@property(nonatomic) NSMutableSet * fnames; // file names for duplicity detection.
@property(nonatomic) NSMutableArray * orderedFnames; // ordered list of file names for building notification message.
@property(nonatomic) BOOL fnameCollisionFound;

-(void) resetFileData;
-(NSData *) getGyData;
@end

/**
* Holder class for files to be added to the ZIP archive.
* @author ph4r05
*/
@interface PEXFtFileEntry : NSObject {}
@property(nonatomic) NSURL * file;
@property(nonatomic) BOOL isAsset;
@property(nonatomic) NSString * fname;
@property(nonatomic) NSString * ext;
@property(nonatomic) uint64_t size;
@property(nonatomic) NSData * sha256;
@property(nonatomic) BOOL doGenerateThumb;
@property(nonatomic) PEXPbMetaFileDetailBuilder *metaB;
@property(nonatomic) PEXPbMetaFileDetail *metaMsg;
@property(nonatomic) PEXFileToSendEntry * fEntry;
@end

/**
* Options for unpacking ZIP archive from file transfer.
*/
@interface PEXFtUnpackingOptions : NSObject {}
@property(nonatomic) NSString * destinationDirectory;
@property(nonatomic) NSString * fnamePrefix;
@property(nonatomic) BOOL createDirIfMissing;
@property(nonatomic) PEXFtFilenameConflictCopyAction actionOnConflict;  // throw
@property(nonatomic) BOOL deleteArchiveOnSuccess;
@property(nonatomic) BOOL deleteMetaOnSuccess;

/**
* If some exception happens during extracting files,
* and this attribute is set to true, all previous files
* will be removed as well.
*/
@property(nonatomic) BOOL deleteNewFilesOnException;
@end

/**
* Result of the files extraction.
* @author ph4r05
*/
@interface PEXFtUnpackingResult : NSObject  {}
@property (nonatomic) BOOL finishedOK;
@property (nonatomic) NSException * exc;
@property (nonatomic) NSError     * err;
@property (nonatomic) NSArray     * files;
@end

@interface PEXFtUnpackingFile : NSObject  {}
@property (nonatomic) NSString * originalFname;
@property (nonatomic) NSString * destination;
@property (nonatomic) NSData * sha256;
- (instancetype)initWithOriginalFname:(NSString *)originalFname destination:(NSString *)destination;
+ (instancetype)fileWithOriginalFname:(NSString *)originalFname destination:(NSString *)destination;
@end

/**
* Holder for the upload response.
* @author ph4r05
*
*/
@interface PEXFtUploadResult : NSObject <NSCoding, NSCopying> {}
@property (nonatomic) NSInteger code;
@property (nonatomic) NSString * message;
@property (nonatomic) int uploaderFinishCode;
@property (nonatomic) PEXPbRESTUploadPost *response;
@property (nonatomic) NSError * error;
- (NSString *)description;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end

@interface PEXFtFileDownloadResult : NSObject <NSCoding, NSCopying> {}
@property (nonatomic) NSInteger code;
@property (nonatomic) int downloaderFinishCode;

@property (nonatomic) PEXFtDownloader * task;
@property (nonatomic) NSError * error;
- (NSString *)description;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end

/**
* Holder used during download operation to store information about file in archive.
* Stores information from meta file + thumbnail details.
*/
@interface PEXFtDownloadFile : NSObject {}
// Fields from meta file detail.
@property (nonatomic, strong) NSString * fileName;
@property (nonatomic, strong) NSString * extension;
@property (nonatomic, strong) NSString * mimeType;
@property (nonatomic)         NSNumber * fileSize;
@property (nonatomic, strong) NSData   * xhash;
@property (nonatomic)         NSNumber * prefOrder;
@property (nonatomic, strong) NSString * thumbNameInZip;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * desc;
@property (nonatomic)         NSNumber * fileTimeMilli;

// Additional fields.
@property (nonatomic)         NSString * thumbFname;
@property (nonatomic)         NSString * thumbPath;
@property (nonatomic)         NSNumber * receivedFileId;

- (instancetype)initWithMeta:(PEXPbMetaFileDetail *)meta;
+ (instancetype)fileWithMeta:(PEXPbMetaFileDetail *)meta;
@end

@interface PEXFtPreUploadFilesHolder : NSObject {}
@property (nonatomic) PEXPbMetaFile * mf;
@property (nonatomic) NSMutableArray * files2send; // Array of PEXFtFileEntry *
@end



