//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"

@class hr_pairingRequestFetchResponse;
@class PEXPairingFetchParams;

// Define ID of the Clist fetch tasks.
typedef enum PEXPairingFetchTaskID : NSInteger {
    PPAIR_FETCH_PAIRING=0,
    PPAIR_PROCESS_PAIRING,
    PPAIR_MAX
} PEXPairingFetchTaskID;

@interface PEXPairingFetchTask : PEXTaskContainer
@property (nonatomic) PEXPairingFetchParams * params;
@property (nonatomic) PEXUserPrivate * privData;
@property (nonatomic) hr_pairingRequestFetchResponse * response;

@end