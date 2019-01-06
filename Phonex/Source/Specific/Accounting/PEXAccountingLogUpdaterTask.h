//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

@class PEXSOAPResult;
@class hr_accountingSaveResponse;


@interface PEXAccountingLogUpdaterTask : NSObject<PEXTaskListener>
@property (nonatomic, weak) PEXUserPrivate * privData;
@property (nonatomic, readonly) PEXSOAPResult * lastResult;

-(hr_accountingSaveResponse *)uploadLogs:(cancel_block)cancelBlock res: (PEXSOAPResult **) res;
@end