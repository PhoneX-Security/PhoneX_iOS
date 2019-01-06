//
// Created by Dusan Klinec on 18.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXUploader.h"

@class PEXSOAPSSLManager;
@protocol PEXCanceller;
@class PEXPaymentUploadJob;

typedef void (^PEXPaymentUploadFinishBlock)(PEXPaymentUploadJob * job, NSString * response, NSError * error);

@interface PEXPaymentUploadManager : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property (nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) NSURLSessionConfiguration * sessionConfig;
@property(nonatomic) NSURLSession * session;
@property(nonatomic) PEXSOAPSSLManager * tlsManager;
@property(nonatomic) NSOperationQueue * opQueue;

@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, copy) cancel_block cancelBlock;
@property(nonatomic) BOOL wasCancelled;

@property(nonatomic) NSError * error;
@property(nonatomic) BOOL securityError;


- (void) configureSession;
- (void) prepareSecurity: (PEXUserPrivate *) privData;
- (void) prepareSession;
- (void) doCancel;

-(void) addUploadJob: (PEXPaymentUploadJob *) job;
@end