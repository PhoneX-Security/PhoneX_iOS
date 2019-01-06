//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"

@class PEXPairingUpdateParams;
@class hr_pairingRequestUpdateResponse;

// Define ID of the Clist fetch tasks.
typedef enum PEXPairingUpdateTaskID : NSInteger {
    PUPAIR_UPDATE=0,
    PUPAIR_PROCESS,
    PUPAIR_MAX
} PEXPairingUpdateTaskID;

@interface PEXPairingUpdateTask : PEXTaskContainer
@property (nonatomic) PEXPairingUpdateParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@property (nonatomic) hr_pairingRequestUpdateResponse * response;

@end
