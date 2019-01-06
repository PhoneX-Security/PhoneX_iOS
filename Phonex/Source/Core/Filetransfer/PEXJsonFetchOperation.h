//
// Created by Dusan Klinec on 23.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;
@class PEXSOAPSSLManager;

FOUNDATION_EXPORT NSString        * PEXFetchErrorDomain;
FOUNDATION_EXPORT const NSInteger   PEXFetchGenericError;
FOUNDATION_EXPORT const NSInteger   PEXFetchNotConnectedError;
FOUNDATION_EXPORT const NSInteger   PEXFetchInvalidResponseError;
FOUNDATION_EXPORT const NSInteger   PEXFetchCancelledError;
FOUNDATION_EXPORT const NSInteger   PEXFetchTimedOutError;

@interface PEXJsonFetchOperation : NSOperation<NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate>
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic) PEXSOAPSSLManager * tlsManager;
@property(nonatomic, copy) dispatch_block_t finishBlock;
@property(nonatomic) BOOL blockingOp;
@property(nonatomic) NSDictionary * userInfo;

@property(nonatomic, readonly) NSError * opError;
@property(nonatomic, readonly) BOOL interruptedDueToConnectionError;

@property(nonatomic) NSString * url;
@property(nonatomic) NSDictionary * params;
@property(nonatomic, readonly) NSDictionary * response;
@property(nonatomic, readonly) NSURLSessionUploadTask * requestTask;
@end