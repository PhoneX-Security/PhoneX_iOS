//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"
#import "PEXUserPrivate.h"
#import "PEXCListChangeParams.h"

// Define ID of the Clist remove tasks.
typedef enum PEXCListRemoveTaskID : NSInteger {
    PCLDT_PREPARE=0,
    PCLDT_DELETE_SOAP,
    PCLDT_DELETE_LOCALLY,
    PCLDT_MAX
} PEXCListRemoveTaskID;

FOUNDATION_EXPORT NSString * const PEXCListRemoveErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXCListRemoveErrorUserNotFound;
FOUNDATION_EXPORT NSInteger const PEXCListRemoveErrorServerSide;

@interface PEXCListRemoveTask : PEXTaskContainer
@property (nonatomic) PEXCListChangeParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@end
