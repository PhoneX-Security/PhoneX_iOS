//
// Created by Dusan Klinec on 12.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTrialEventTask.h"
#import "PEXTaskEvent.h"
#import "PEXSOAPResult.h"
#import "hr.h"


@implementation PEXTrialEventTask {

}

-(hr_trialEventSaveResponse *) requestUserInfo: (PEXUserPrivate *) privData eventType: (int) eventType cancelBlock: (cancel_block) cancelBlock res: (PEXSOAPResult **) res {
    PEXSOAPResult * mres = [[PEXSOAPResult alloc] init];

    @try {
        if (privData == nil || privData.username == nil){
            DDLogError(@"Cannot call requestUserInfo with empty privData.");
            mres.code = PEX_SOAP_CALL_RES_ERROR;
            [mres setToRef:res];

            return nil;
        }

        // Build request. By default no additional setting is needed.
        hr_trialEventSaveRequest * req = [[hr_trialEventSaveRequest alloc] init];
        req.etype = @(eventType);

        // Create SOAP envelope
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.trialEventSave"];

        task.logXML = YES;
        [task prepareSOAP:privData];

        // Prepare SOAP operation.
        task.desiredBody = [hr_trialEventSaveResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return cancelBlock != nil && cancelBlock(); };
        task.srcOperation = [[PhoenixPortSoap11Binding_trialEventSave alloc]
                initWithBinding:task.getBinding delegate:task trialEventSaveRequest:req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        mres.cancelDetected = task.cancelDetected;
        mres.timeoutDetected = task.timeoutDetected;
        [mres setToRef:res];

        // Cancelled check block.
        if ([task cancelDetected]) {
            mres.soapTaskError = task.taskError;
            mres.code = PEX_SOAP_CALL_RES_CANCELLED;
            [mres setToRef:res];
            return nil;
        }

        // Error check block.
        if ([task finishedWithError] || task.responseBody == nil) {
            mres.soapTaskError = task.taskError;
            mres.code = PEX_SOAP_CALL_RES_ERROR;
            mres.err = task.error;
            [mres setToRef:res];
            return nil;
        }

        mres.code = PEX_SOAP_CALL_RES_OK;
        [mres setToRef:res];
        hr_trialEventSaveResponse * resp = (hr_trialEventSaveResponse *) task.responseBody;
        return resp;

    } @catch (NSException * e) {
        DDLogError(@"Exception in account info fetch, exception=%@", e);

        mres.code = PEX_SOAP_CALL_RES_EXCEPTION;
        mres.ex = e;
        [mres setToRef:res];
        return nil;
    }
}

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskEnded:(const PEXTaskEvent *const)event {

}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}

@end