//
// Created by Matej Oravec on 31/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDhKeyHelper.h"
#import "PEXBase.h"

@protocol PEXCanceller;
@class PEXPbRESTUploadPost;
@class PEXSOAPSSLManager;
@class PEXUserPrivate;
@class PEXUploader;

typedef void (^PEXUploaderFinished)(PEXUploader * uploader);
@interface PEXUploader : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property(nonatomic) NSURLSessionConfiguration * sessionConfig;
@property(nonatomic) NSURLSession * session;
@property(nonatomic) NSURLSessionUploadTask * updTask;
@property(nonatomic) PEXSOAPSSLManager * tlsManager;
@property(nonatomic) NSOperationQueue * opQueue;

@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, copy) PEXTransferProgressBlock progressBlock;
@property(nonatomic, copy) dispatch_block_t finishBlock;
@property(nonatomic, copy) PEXUploaderFinished finishBlock2;
@property(nonatomic, copy) cancel_block cancelBlock;
@property(nonatomic, assign) BOOL wasCancelled;

@property(nonatomic, readonly) int64_t uploadLength;
@property(nonatomic, readonly) NSInteger statusCode;
@property(nonatomic, readonly) int64_t expectedContentLength;
@property(nonatomic, readonly) int64_t totalBytesSent;
@property(nonatomic, readonly) PEXPbRESTUploadPost * restResponse;

@property(nonatomic) NSString * user;

@property(nonatomic) BOOL securityError;
@property(nonatomic) NSError * error;

- (void) configureSession;
- (void) prepareSecurity: (PEXUserPrivate *) privData;
- (void) prepareSession;
- (void) doCancel;
- (void) uploadFilesForUser: (NSString *) user url: (NSString *) url2upload;
- (int) uploadFilesBlockingForUser: (NSString *) user url: (NSString *) url2upload;

@end