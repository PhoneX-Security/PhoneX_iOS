//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUploader.h"

#import "PEXDhKeyHelper.h"

@class PEXSOAPSSLManager;
@class PEXFtHolder;
@protocol PEXCanceller;
@class PEXPbRESTUploadPost;
@class PEXUserPrivate;

FOUNDATION_EXPORT NSString * PEX_FT_UPLOAD_DOMAIN;
FOUNDATION_EXPORT const NSInteger PEX_FT_UPLOAD_UNKNOWN_RESPONSE;

@interface PEXFtUploader : PEXUploader

@property(nonatomic, weak) PEXFtHolder * holder;

@end