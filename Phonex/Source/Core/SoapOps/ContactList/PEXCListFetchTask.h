//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"
#import "PEXUserPrivate.h"
#import "PEXCListFetchParams.h"
#import "hr.h"

extern NSString * PEX_CLIST_FETCH_LAST_FINISH_TSTAMP;

// Define ID of the Clist fetch tasks.
typedef enum PEXCListFetchTaskID : NSInteger {
    PCLT_FETCH_CL=0,
    PCLT_PROCESS_CL,
    PCLT_CERT_REFRESH,
    PCLT_CERT_PROCESS,
    PCLT_STORE,
    PCLT_MAX
} PEXCListFetchTaskID;

@interface PEXCListFetchTask : PEXTaskContainer
@property (nonatomic) PEXCListFetchParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@property (nonatomic) hr_contactlistGetResponse * response;
@end