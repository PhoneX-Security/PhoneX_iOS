//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCertificateUpdateManagerProtocol.h"

@class PEXConcurrentLinkedList;
@class PEXConcurrentHashMap;
@class PEXUserPrivate;
@protocol PEXCanceller;
@class PEXDbAppContentProvider;
@class PEXDbContact;

@interface PEXCertificateUpdateTask : NSOperation
@property(nonatomic) volatile BOOL acceptingNewJobs;
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, weak) id<PEXCertificateUpdateManagerProtocol> mgr;

/**
* Concurrent queue of certificate check requests.
* Passed from manager.
*/
@property(nonatomic, weak) PEXConcurrentLinkedList * certCheckList;

-(void) doManualCancel: (BOOL) manualCancel;

/**
* Main task entry point.
*/
-(void) main;

@end