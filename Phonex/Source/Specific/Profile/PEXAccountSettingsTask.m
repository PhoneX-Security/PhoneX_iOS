//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAccountSettingsTask.h"
#import "PEXSOAPResult.h"
#import "hr.h"
#import "PEXUtils.h"


@implementation PEXAccountSettingsTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.retryCount = 0;
        self.curRetry = 0;
    }

    return self;
}

- (void)requestWithRetryCount {
    // Reset completion handler so it is called only after retry count is reached.
    void(^completionHandler)(PEXAccountSettingsTask *) = self.completionHandler;
    self.completionHandler = nil;

    // Iterate until retry count is reached or successful query was made.
    for(self.curRetry = 0; self.curRetry <= self.retryCount; self.curRetry ++){
        DDLogVerbose(@"Settings update retry: %d/%d", self.curRetry, self.retryCount);
        self.lastResponse = [self request:self.privData cancelBlock:self.cancelBlock res:nil];
        if (_lastResult.code == PEX_SOAP_CALL_RES_OK){
            break;
        }
    }

    self.completionHandler = completionHandler;
    [self taskCompletion];
}

- (hr_accountSettingsUpdateV1Response *)request:(PEXUserPrivate *)privData
                                    cancelBlock:(cancel_block)cancelBlock
                                            res:(PEXSOAPResult **)res
{
    _lastResult = [[PEXSOAPResult alloc] init];

    @try {
        if (privData == nil || privData.username == nil){
            DDLogError(@"Cannot call requestUserInfo with empty privData.");
            _lastResult.code = PEX_SOAP_CALL_RES_ERROR;
            [_lastResult setToRef:res];

            [self taskCompletion];
            return nil;
        }

        // Build request with settings.
        hr_accountSettingsUpdateV1Request * req = [[hr_accountSettingsUpdateV1Request alloc] init];

        // Settings are set in local properties.
        NSMutableDictionary * settings = [[NSMutableDictionary alloc] init];
        if (self.loggedOut != nil){
            settings[@"loggedIn"] = @(![self.loggedOut boolValue]);
        }

        if (self.muteUntilMilli != nil){
            settings[@"mutePush"] = self.muteUntilMilli;
        }

        if (self.muteSoundUntilMilli != nil){
            settings[@"muteSound"] = self.muteSoundUntilMilli;
        }

        if (self.recoveryEmail != nil){
            settings[@"recoveryEmail"] = self.recoveryEmail;
        }

        // Encode to JSON, set to request body.
        NSError * encodingError = nil;
        NSDictionary * reqRoot = @{@"settingsUpdate" : settings};
        req.requestBody = [PEXUtils serializeToJSON:reqRoot error:&encodingError];

        // JSON encoding failed?
        if (req.requestBody == nil || encodingError != nil){
            DDLogError(@"Error in JSON encoding: %@", encodingError);
            _lastResult.err = encodingError != nil ? encodingError : [NSError errorWithDomain:PEXRuntimeDomain code:-10 userInfo:@{}];
            _lastResult.soapTaskError = PEX_SOAP_ERROR_TASK_ERROR;
            _lastResult.code = PEX_SOAP_CALL_RES_ERROR;
            [_lastResult setToRef:res];

            [self taskCompletion];
            return nil;
        }

        // Create SOAP envelope
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.accountSettings"];

        task.logXML = YES;
        [task prepareSOAP:privData];

        // Prepare SOAP operation.
        task.desiredBody = [hr_accountSettingsUpdateV1Response class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return cancelBlock != nil && cancelBlock(); };
        task.srcOperation = [[PhoenixPortSoap11Binding_accountSettingsUpdateV1 alloc]
                initWithBinding:task.getBinding delegate:task accountSettingsUpdateV1Request:req];

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

            [self taskCompletion];
            return nil;
        }

        // Error check block.
        if ([task finishedWithError] || task.responseBody == nil) {
            _lastResult.soapTaskError = task.taskError;
            _lastResult.code = PEX_SOAP_CALL_RES_ERROR;
            _lastResult.err = task.error;
            [_lastResult setToRef:res];

            [self taskCompletion];
            return nil;
        }

        _lastResult.code = PEX_SOAP_CALL_RES_OK;
        [_lastResult setToRef:res];
        hr_accountSettingsUpdateV1Response * resp = (hr_accountSettingsUpdateV1Response *) task.responseBody;

        [self taskCompletion];
        return resp;

    } @catch (NSException * e) {
        DDLogError(@"Exception in account settings update, exception=%@", e);

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