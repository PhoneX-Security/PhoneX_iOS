//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "PEXDbContentProvider.h"
#import "PEXCListChangeParams.h"
#import "PEXUserPrivate.h"
#import "PEXTaskContainer.h"

// Define ID of the Clist add tasks.
typedef enum PEXCListAddTaskID : NSInteger {
    PCLAT_PREPARE=0,
    PCLAT_CERT_FETCH,
    PCLAT_CERT_PROCESS,
    PCLAT_CONTACT_STORE_SOAP,
    PCLAT_CONTACT_STORE_LOCALLY,
    PCLAT_ROLLBACK_NEEDED_CHECK,
    PCLAT_ROLLBACK,
    PCLAT_MAX
} PEXCListAddTaskID;

FOUNDATION_EXPORT NSString * const PEXCListAddErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXClistAddErrorUserAlreadyAdded;
FOUNDATION_EXPORT NSInteger const PEXClistAddErrorServerSideAdd;

@interface PEXCListAddTask : PEXTaskContainer
@property (nonatomic) PEXCListChangeParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@end
