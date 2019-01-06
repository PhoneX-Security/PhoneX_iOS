//
// Created by Matej Oravec on 23/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"

@class PEXDbContact;
@protocol PEXCanceller;


@interface PEXCheckCertificateTask : PEXTask

@property (nonatomic) PEXDbContact * contact;
@property (nonatomic) id<PEXCanceller> canceller;
@property (nonatomic, readonly) BOOL requestSuccess;

@end