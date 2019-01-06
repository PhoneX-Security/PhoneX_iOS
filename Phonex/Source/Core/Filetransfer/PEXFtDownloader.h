//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDhKeyHelper.h"

@class PEXSOAPSSLManager;
@protocol PEXCanceller;
@class PEXFtHolder;

@interface PEXFtDownloader : NSObject<NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property(nonatomic, readonly) NSURLSessionConfiguration * sessionConfig;
@property(nonatomic, readonly) NSURLSession * session;
@property(nonatomic, readonly) PEXSOAPSSLManager * tlsManager;
@property(nonatomic, readonly) NSURLSessionDownloadTask * dwnTask;
@property(nonatomic, readonly) NSOperationQueue * opQueue;

@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, copy) PEXTransferProgressBlock progressBlock;
@property(nonatomic, copy) dispatch_block_t finishBlock;
@property(nonatomic, copy) cancel_block cancelBlock;

@property(nonatomic, readonly) NSInteger statusCode;
@property(nonatomic, readonly) int64_t downloadLength;
@property(nonatomic, readonly) int64_t totalBytesReceived;

@property(nonatomic, weak) PEXFtHolder * holder;
@property(nonatomic) NSString * user;

@property(nonatomic, readonly) BOOL securityError;
@property(nonatomic, readonly) NSError * error;
@property(nonatomic) NSString * destinationFile;

- (void) configureSession;
- (void) prepareSecurity: (PEXUserPrivate *) privData;
- (void) prepareSession;
- (void) setRangeFrom: (NSUInteger) rangeBytes;
- (void) setTimeouts: (NSNumber *) reqTimeout resTimeout: (NSNumber *) resTimeout;

- (void) downloadFile: (NSString *) urlStr;
- (int) downloadFileBlocking: (NSString *) urlStr;
- (void) doCancel;


@end