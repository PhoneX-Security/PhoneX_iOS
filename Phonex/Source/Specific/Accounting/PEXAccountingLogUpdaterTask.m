//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAccountingLogUpdaterTask.h"
#import "hr.h"
#import "PEXSOAPResult.h"
#import "PEXUtils.h"
#import "PEXXmppCenter.h"
#import "PEXXmppManager.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbAccountingLog.h"
#import "PEXAccountingHelper.h"

@interface PEXAccountingLogUpdaterTask() {}
@property (nonatomic) NSUInteger numRecords;
@property (nonatomic) PEXSOAPResult * lastResult;
@end

@implementation PEXAccountingLogUpdaterTask {

}

/**
 *  {"astore":{
 *     "res":"abcdef123",
 *      "permissions":1,      (optional, if set to 1 AFFECTED permissions are returned)
 *      "aggregate":1,        (optional, if set to 1 AFFECTED aggregate records are returned)
 *      "records":[
 *          {"type":"c.os", "aid":1443185424488, "ctr":1, "vol": "120", "ref":"ed4b607e48009a34d0b79fe70f521cde"},
 *          {"type":"c.os", "aid":1443185524488, "ctr":2, "vol": "10", "perm":{"licId":123, "permId":1}},
 *          {"type":"m.om", "aid":1443185624488, "ctr":3, "vol": "120", "perm":{"licId":123, "permId":2}},
 *          {"type":"m.om", "aid":1443185724488, "ctr":4, "vol": "10", "ag":1, "aidbeg":1443185724488},
 *          {"type":"f.id", "aid":1443185824488, "ctr":5, "vol": "1"}
 *     ]
 * }}
 */
-(void) prepareStoreRequest: (hr_accountingSaveRequest *) req {
    NSString const * res = [[[PEXXmppCenter instance] xmppManager] resourceId];

    NSMutableDictionary * storeBody = [[NSMutableDictionary alloc] init];
    storeBody[@"res"] = res;
    storeBody[@"permissions"] = @(1);

    // Load all permissions from database.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * cursor = nil;
    NSMutableArray * records = [[NSMutableArray alloc] init];
    self.numRecords = 0;

    @try {
        cursor = [cr query:[PEXDbAccountingLog getURI]
                projection:[PEXDbAccountingLog getFullProjection]
                 selection:[NSString stringWithFormat:@""]
             selectionArgs:@[]
                 sortOrder:[NSString stringWithFormat:@" ORDER BY %@, %@", PEX_DBAL_FIELD_ACTION_ID, PEX_DBAL_FIELD_ACTION_COUNTER]];

        while([cursor moveToNext]){
            PEXDbAccountingLog * alog = [PEXDbAccountingLog accountingLogWithCursor:cursor];
            NSMutableDictionary * alogDict = [PEXAccountingHelper accountingLogToDict:alog];
            [records addObject:alogDict];
        }

        self.numRecords = [records count];

    } @catch(NSException * e){
        DDLogError(@"Exception in loading AccountingLogs: %@", e);
    } @finally{
        [PEXUtils closeSilentlyCursor:cursor];
    }

    storeBody[@"records"] = records;

    // app_version update in aux_json.
    NSDictionary * reqBody = @{@"astore" : storeBody};
    req.requestBody = [PEXUtils serializeToJSON:reqBody error:nil];
}

/**
 *  "store":{
 *          "topaid":1443185824488,
 *          "topctr":5,
 *          "permissions:"[
 *              {permission_1}, {permission_2}, ..., {permission_m}
 *          ],
 *          "aggregate":[
 *              {ag_1,} {ag_2}, ..., {ag_n}
 *          ]
 *     }
 */
- (void) processResponse: (hr_accountingSaveResponse *) respx {
    NSString * respBodyStr = respx.responseBody;
    NSError* localError;

    @try {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[respBodyStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0 error:&localError];

        if (resp == nil || localError != nil) {
            DDLogError(@"Error in parsing JSON response: %@", localError);
            return;
        }

        if (resp[@"astore"] == nil) {
            DDLogError(@"Response does not contain \"store\"");
            return;
        }

        NSDictionary *storeResp = resp[@"astore"];

        // 1. Topaid + topctr present -> delete old log records as it was transmitted.
        if (storeResp[@"topaid"] != nil && storeResp[@"topctr"] != nil){
            NSNumber * topaid = storeResp[@"topaid"];
            NSNumber * topctr = storeResp[@"topctr"];
            DDLogVerbose(@"TopAid: %@, topCtr: %@", topaid, topctr);

            int deleted = [PEXDbAccountingLog deleteRecordsOlderThan:topaid actionCtr:topctr cr:[PEXDbAppContentProvider instance]];
            DDLogVerbose(@"AccountingLogs deleted: %d", deleted);
        }

        // 2. Process permission dump, store to server view. Update / insert.
        if (storeResp[@"permissions"] != nil){
            [PEXAccountingHelper updatePermissionsFromServerJson:storeResp[@"permissions"]];
        }

    } @catch(NSException * e){
        DDLogError(@"Exception in parsing response, exc: %@", e);
    }
}

-(hr_accountingSaveResponse *)uploadLogs:(cancel_block)cancelBlock res: (PEXSOAPResult **) res {
    PEXSOAPResult * mres = [[PEXSOAPResult alloc] init];
    self.lastResult = mres;

    @try {
        if (_privData == nil || _privData.username == nil){
            DDLogError(@"Cannot call requestUserInfo with empty privData.");
            mres.code = PEX_SOAP_CALL_RES_ERROR;
            [mres setToRef:res];

            return nil;
        }

        // Build request. By default no additional setting is needed.
        hr_accountingSaveRequest * req = [[hr_accountingSaveRequest alloc] init];
        [self prepareStoreRequest:req];

        // If there is nothing to upload, quit.
        if (self.numRecords == 0){
            mres.soapTaskError = PEX_SOAP_ERROR_NONE;
            mres.code = PEX_SOAP_CALL_RES_OK;
            mres.err = nil;
            [mres setToRef:res];
            return nil;
        }

        // Create SOAP envelope
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.saveAccountingData"];

        task.logXML = YES;
        [task prepareSOAP:_privData];

        // Prepare SOAP operation.
        task.desiredBody = [hr_accountingSaveResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return cancelBlock != nil && cancelBlock(); };
        task.srcOperation = [[PhoenixPortSoap11Binding_accountingSave alloc]
                initWithBinding:task.getBinding delegate:task accountingSaveRequest:req];

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
            DDLogError(@"Log update finished with error %d, %@", (int)task.taskError, task.error);

            mres.soapTaskError = task.taskError;
            mres.code = PEX_SOAP_CALL_RES_ERROR;
            mres.err = task.error;
            [mres setToRef:res];
            return nil;
        }

        mres.code = PEX_SOAP_CALL_RES_OK;
        [mres setToRef:res];
        hr_accountingSaveResponse * resp = (hr_accountingSaveResponse *) task.responseBody;
        [self processResponse:resp];

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