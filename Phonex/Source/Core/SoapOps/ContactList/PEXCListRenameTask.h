//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"
#import "PEXUserPrivate.h"
#import "PEXCListChangeParams.h"

// Define ID of the Clist remove tasks.
typedef enum PEXCListRenameTaskID : NSInteger {
    PCLRT_PREPARE=0,
    PCLRT_RENAME_SOAP,
    PCLRT_RENAME_LOCALLY,
    PCLRT_MAX
} PEXCListRenameTaskID;

FOUNDATION_EXPORT NSString * const PEXCListRenameErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXCListRenameErrorUserNotFound;
FOUNDATION_EXPORT NSInteger const PEXCListRenameErrorServerSide;

@interface PEXCListRenameTask : PEXTaskContainer
@property (nonatomic) PEXCListChangeParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@end
