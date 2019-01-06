//
// Created by Matej Oravec on 08/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLicenceCheckTask.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXSOAPResult.h"
#import "PEXUtils.h"
#import "PEXLoginTask.h"
#import "PEXAccountingHelper.h"
#import "PEXService.h"
#import "PEXLicenceManager.h"
#import "PEXReferenceTimeManager.h"

@implementation PEXLicenceCheckTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticAppSettingsProcessing = YES;
        self.automaticAccountSettingsProcessing = YES;
        self.automaticPolicyProcessing = YES;
        self.settingsProcessingSync = NO;
        self.policyProcessingSync = NO;
        self.accountSettingsProcessingSync = NO;
        self.policyUpdateOK = NO;
        self.settingsUpdateOK = NO;
        self.accountSettingsUpdateOK = NO;
        self.shouldUpdateReferenceTime = YES;
    }

    return self;
}

-(hr_accountInfoV1Response *) requestUserInfo: (PEXUserPrivate *) privData cancelBlock: (cancel_block) cancelBlock res: (PEXSOAPResult **) res {
    _lastResult = [[PEXSOAPResult alloc] init];

    @try {
        if (privData == nil || privData.username == nil){
            DDLogError(@"Cannot call requestUserInfo with empty privData.");
            _lastResult.code = PEX_SOAP_CALL_RES_ERROR;
            [_lastResult setToRef:res];

            [self totalCompletion];
            return nil;
        }

        // Build request. By default no additional setting is needed.
        hr_accountInfoV1Request * req = [[hr_accountInfoV1Request alloc] init];

        // app_version update in aux_json.
        NSDictionary * auxJsonDict = @{@"app_version" : [PEXUtils getAppVersion]};
        req.auxJSON = [PEXUtils serializeToJSON:auxJsonDict error:nil];

        // Create SOAP envelope
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.accountInfo"];

        task.logXML = YES;
        [task prepareSOAP:privData];

        // Prepare SOAP operation.
        task.desiredBody = [hr_accountInfoV1Response class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return cancelBlock != nil && cancelBlock(); };
        task.srcOperation = [[PhoenixPortSoap11Binding_accountInfoV1 alloc]
                initWithBinding:task.getBinding delegate:task accountInfoV1Request:req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        _lastResult.cancelDetected = task.cancelDetected;
        _lastResult.timeoutDetected = task.timeoutDetected;
        [_lastResult setToRef:res];

        // Cancelled check block.
        if ([task cancelDetected]) {
            _lastResult.soapTaskError = task.taskError;
            _lastResult.code = PEX_SOAP_CALL_RES_CANCELLED;
            [_lastResult setToRef:res];

            [self totalCompletion];
            return nil;
        }

        // Error check block.
        if ([task finishedWithError] || task.responseBody == nil) {
            _lastResult.soapTaskError = task.taskError;
            _lastResult.code = PEX_SOAP_CALL_RES_ERROR;
            _lastResult.err = task.error;
            [_lastResult setToRef:res];

            [self totalCompletion];
            return nil;
        }

        _lastResult.code = PEX_SOAP_CALL_RES_OK;
        [_lastResult setToRef:res];
        hr_accountInfoV1Response * resp = (hr_accountInfoV1Response *) task.responseBody;

        // IPH-330: process settings pushed by the server.
        [self updateReferenceTime:resp privData:privData];
        [self appSettingsProcessing:resp privData:privData];
        [self accountSettingsProcessing:resp privData:privData];
        [self appPolicyProcessing:resp privData:privData];

        [self taskCompletion];
        return resp;

    } @catch (NSException * e) {
        DDLogError(@"Exception in account info fetch, exception=%@", e);

        _lastResult.code = PEX_SOAP_CALL_RES_EXCEPTION;
        _lastResult.ex = e;
        [_lastResult setToRef:res];

        [self taskCompletion];
        return nil;
    }
}

-(void) taskCompletion {
    if (self.completionHandler){
        self.completionHandler(self);
    }
}

-(void) policyCompletion {
    if (self.completionPolicyHandler){
        self.completionPolicyHandler(self);
    }
}

-(void) settingsCompletion {
    if (self.completionSettingsHandler){
        self.completionSettingsHandler(self);
    }
}

-(void) accountSettingsCompletion {
    if (self.completionSettingsHandler){
        self.completionSettingsHandler(self);
    }
}

-(void) totalCompletion {
    [self accountSettingsCompletion];
    [self settingsCompletion];
    [self policyCompletion];
    [self taskCompletion];
}

- (void) updateReferenceTime: (hr_accountInfoV1Response *) resp privData: (PEXUserPrivate *) privData {
    if (!self.shouldUpdateReferenceTime) {
        return;
    }

    PEXReferenceTimeManager * timeMgr = [[PEXAppState instance] referenceTimeManager];
    if (timeMgr == nil){
        DDLogError(@"Time manager is nil");
        return;
    }

    if (resp.serverTime == nil){
        DDLogError(@"Server time not provided in the response");
        return;
    }

    DDLogVerbose(@"Going to update server time"); // To detect potential deadlock in the time manager.
    NSDate * oldRefTime = [timeMgr currentTimeSinceReference:[NSDate date]];
    self.lastRefTime = [timeMgr setReferenceServerTime:resp.serverTime];
    NSDate * newRefTime = [timeMgr currentTimeSinceReference:[NSDate date]];

    DDLogVerbose(@"Reference time updated, old time: %@, new time %@", oldRefTime, newRefTime);
}

- (void) appPolicyProcessing: (hr_accountInfoV1Response *) resp privData: (PEXUserPrivate *) privData {
    if (!self.automaticPolicyProcessing) {
        [self policyCompletion];
        return;
    }

    // Configuring block to execute.
    // Have a strong reference to self, as the block can be executed when task is already out of scope.
    dispatch_block_t toExec = ^{
        @try {
            NSDictionary * auxJson = [PEXLoginTask parseAuxJson:resp.auxJSON pError:nil];
            [PEXLoginTask processAppServerPolicy:auxJson privData:privData];
            self.policyUpdateOK = YES;

        } @catch (NSException * e){
            DDLogError(@"Exception in processing app settings, %@", e);
        }

        [self policyCompletion];
    };

    // Block execution.
    if (self.policyProcessingSync){
        toExec();
    } else {
        [[PEXService instance].licenceManager executeOnPermissionUpdateQueue:toExec];
    }
}

- (void) appSettingsProcessing: (hr_accountInfoV1Response *) resp privData: (PEXUserPrivate *) privData {
    if (!self.automaticAppSettingsProcessing) {
        [self settingsCompletion];
        return;
    }

    // Configuring block to execute.
    // Have a strong reference to self, as the block can be executed when task is already out of scope.
    dispatch_block_t toExec = ^{
        @try {
            NSDictionary *auxJson = [PEXLoginTask parseAuxJson:resp.auxJSON pError:nil];
            [PEXLoginTask processAppServerSettings:auxJson privData:privData];
            self.settingsUpdateOK = YES;

        } @catch (NSException *e) {
            DDLogError(@"Exception in processing app settings, %@", e);
        }

        [self settingsCompletion];
    };

    // Block execution.
    if (self.settingsProcessingSync){
        toExec();
    } else {
        [[PEXService instance] executeAsync:YES block:toExec];
    }
}

- (void) accountSettingsProcessing: (hr_accountInfoV1Response *) resp privData: (PEXUserPrivate *) privData {
    if (!self.automaticAccountSettingsProcessing) {
        [self accountSettingsCompletion];
        return;
    }

    // Configuring block to execute.
    // Have a strong reference to self, as the block can be executed when task is already out of scope.
    dispatch_block_t toExec = ^{
        @try {
            NSDictionary *auxJson = [PEXLoginTask parseAuxJson:resp.auxJSON pError:nil];
            [PEXLoginTask processAccountServerSettings:auxJson privData:privData];
            self.accountSettingsUpdateOK = YES;

        } @catch (NSException *e) {
            DDLogError(@"Exception in processing app settings, %@", e);
        }

        [self accountSettingsCompletion];
    };

    // Block execution.
    if (self.accountSettingsProcessingSync){
        toExec();
    } else {
        [[PEXService instance] executeAsync:YES block:toExec];
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