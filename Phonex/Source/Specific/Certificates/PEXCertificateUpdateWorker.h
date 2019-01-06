//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;
@protocol PEXCertificateUpdateManagerProtocol;
@class PEXUserPrivate;
@class PEXCertificateUpdateManager;

@interface PEXCertificateUpdateWorker : NSObject
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) NSString * domain;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, weak) id<PEXCertificateUpdateManagerProtocol> mgr;
@property(nonatomic) NSMutableArray * queue;
@property(nonatomic, readonly) BOOL requestFailed;

-(void) processRequestQueue;

@end