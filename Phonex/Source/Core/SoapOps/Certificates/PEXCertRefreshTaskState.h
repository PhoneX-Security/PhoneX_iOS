//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSOAPTask.h"
#import "PEXTaskFinishedEvent.h"

@class hr_getCertificateResponse;

/**
* Certificate update task state.
*/
@interface PEXCertRefreshTaskState : NSObject
@property(nonatomic) NSArray * requests;
@property(nonatomic) NSMutableDictionary * responses;
@property(nonatomic) NSProgress * overallProgress;
@property(nonatomic) NSProgress * callProgress;
@property(nonatomic) NSProgress * processProgress;

@property(nonatomic) PEX_TASK_FINIHED_STATE overallTaskState;
@property(nonatomic) PEX_TASK_FINIHED_STATE soapTaskFinishState;
@property(nonatomic) NSError * soapTaskError;

// One request at time.
@property(nonatomic) hr_getCertificateResponse * certResponse;
@property(nonatomic) PEXSOAPTask * soapTask;

@end
