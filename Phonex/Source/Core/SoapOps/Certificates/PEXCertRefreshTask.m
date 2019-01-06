//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertRefreshTask.h"
#import "PEXCertRefreshParams.h"
#import "PEXUserPrivate.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "PEXCertificate.h"
#import "PEXSOAPTask.h"
#import "PEXDbContentProvider.h"
#import "hr.h"
#import "PEXCertRefreshTaskState.h"
#import "PEXCertRefreshResult.h"
#import "NSProgress+PEXAsyncUpdate.h"
#import "PEXCanceller.h"
#import "PEXX509.h"
#import "PEXCertUtils.h"

double CERTIFICATE_OK_RECHECK_PERIOD = 60.0 * 1;
double CERTIFICATE_NOK_RECHECK_PERIOD = 10.0;
double CERTIFICATE_PUSH_TIMEOUT = 60.0 * 2;
long CERTIFICATE_PUSH_MAX_UPDATES = 64;

@implementation PEXCertRefreshTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.privData = nil;
        self.state = [[PEXCertRefreshTaskState alloc] init];
        self.doProgressMonitoring = YES;
    }

    return self;
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

+ (instancetype)taskWithPrivData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithPrivData:privData];
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData params:(PEXCertRefreshParams *)params {
    self = [self init];
    if (self) {
        self.privData = privData;
        self.state.requests = @[params];
    }

    return self;
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData paramsArray:(NSArray *)params {
    self = [self init];
    if (self) {
        self.privData = privData;
        self.state.requests = params;
    }

    return self;
}

- (void)prepareOverallProgress {
    self.state.overallProgress = [NSProgress progressWithTotalUnitCount: 100];

    // Part 1 - remote call.
    [self.state.overallProgress becomeCurrentWithPendingUnitCount:50];
    [self prepareCallProgress];
    [self.state.overallProgress resignCurrent];

    // Part 2 - processing.
    [self.state.overallProgress becomeCurrentWithPendingUnitCount:50];
    self.state.processProgress = [NSProgress progressWithTotalUnitCount:1];
    [self.state.overallProgress resignCurrent];
}

- (void)prepareCallProgress {
    self.state.callProgress = [NSProgress progressWithTotalUnitCount: 1];
    [self.state.callProgress becomeCurrentWithPendingUnitCount:1];

    // Init soap task and prepare its progress in this thread so it gets associated to the
    // parent progress so it works together.
    self.state.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.certrefresh"];
    [self.state.soapTask prepareProgress];

    // By now the parent progress is tied to the child progress so it waits on it. If there would be no
    // progress initialized in soaptask, parent progress would move now.
    [self.state.callProgress resignCurrent];
}

- (NSProgress *)getCallProgress {
    return self.state.callProgress;
}

- (NSProgress *)getOverallProgress{
    return self.state.overallProgress;
}

-(BOOL)shouldCancel {
    if (self.canceller != nil && [self.canceller isCancelled]){
        return YES;
    }

    if (self.state == nil || self.state.callProgress == nil){
        return NO;
    }

    BOOL overallCancelled = self.state.overallProgress != nil && [self.state.overallProgress isCancelled];
    if (overallCancelled){
        return YES;
    }

    return [self.state.callProgress isCancelled];
}

/**
* Determines whether certificate re-check is needed.
* If yes, certificate is pre-loaded to the internal state of this
* object to continue with certificate refresh.
*
* Certificate may be old, missing or invalid.
*
* @return
*/
-(BOOL) isCertRefreshNeeded: (NSArray *) params results: (NSMutableDictionary *) results {
    BOOL atLeastOneNeeds = NO;
    if (params == nil || params.count == 0){
        return NO;
    }

    // Chunking of the problem size is a parent problem.
    // Still we store the results to the results parameter, have to process all, no memory saving.
    // ;
    // Iterate over to create a list of user names.
    // Initialize results if they are not.
    NSMutableArray * userNameList = [[NSMutableArray alloc] initWithCapacity:params.count];
    for(PEXCertRefreshParams * param in params){
        if (param == nil || param.user == nil){
            continue;
        }

        [userNameList addObject:param.user];
        if (results[param.user] == nil){
            results[param.user] = [[PEXCertRefreshResult alloc] initWithParams:param];
        }
    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Load all locally stored certificates in a bulk.
    NSDictionary * dict = [PEXDbUserCertificate loadCertificatesForUsers:userNameList cr:cr projection:[PEXDbUserCertificate getFullProjection]];

    // Iterate over parameters, check if stored certificate was found for a particular user.
    // If yes check its state. Recheck if certificate is too old.
    for(PEXCertRefreshParams * param in params){
        if (param == nil || param.user == nil){
            continue;
        }

        PEXCertRefreshResult * curRes = results[param.user];
        if (curRes == nil){
            DDLogError(@"Inconsistent state! No result found for user %@", param.user);
            continue;
        }

        // Initialize state.
        curRes.remoteCertObj = nil;
        curRes.remoteCert = nil;
        BOOL recheckNeeded = NO;

        PEXDbUserCertificate * remoteCert = dict[param.user];
        if (remoteCert == nil){
            // No certificate found.
            curRes.statusCode = -1;
            curRes.recheckNeeded = @(YES);
            continue;
        }

        NSDate * lastQuery = remoteCert.dateCreated;

        // Is certificate stored in database OK?
        if (remoteCert.certificateStatus != nil && [remoteCert.certificateStatus isEqualToNumber:@(CERTIFICATE_STATUS_OK)]){
            // Certificate is valid, maybe we still need some re-check (revocation status for example)
            NSDate * boundary = [NSDate dateWithTimeInterval:-CERTIFICATE_OK_RECHECK_PERIOD sinceDate:[NSDate date]];
            recheckNeeded = [lastQuery compare:boundary] == NSOrderedAscending || param.forceRecheck;
            @try {
                curRes.remoteCertObj = [PEXCertificate certificateWithCert:[remoteCert getCertificateObj]];
                curRes.remoteCert = remoteCert;
                curRes.certHash = remoteCert.certificateHash;
                DDLogVerbose(@"Certificate stored locally, valid, recheck: false");
            } @catch(NSException * ex){
                DDLogError(@"Cannot parse stored certificate");
                recheckNeeded = YES;
            }
        } else {
            // Certificate is invalid, missing or revoked or broken somehow.
            // should re-check be performed?
            NSDate * boundary = [NSDate dateWithTimeInterval:-CERTIFICATE_NOK_RECHECK_PERIOD sinceDate:[NSDate date]];
            recheckNeeded = [lastQuery compare:boundary] == NSOrderedAscending || param.forceRecheck;
            curRes.certHash = nil;

            DDLogDebug(@"Certificate stored locally, invalid, recheck: %d; record=%@; certificateStatus=%@",
                    recheckNeeded, remoteCert, remoteCert.certificateStatus);
        }

        curRes.recheckNeeded = @(recheckNeeded);
        atLeastOneNeeds |= recheckNeeded;
    }

    return atLeastOneNeeds;
}

/**
* Constructs certificate refresh request from the local state.
* If there is 0 certificates to refresh, nil is returned since SOAP call is pointless.
*/
-(hr_getCertificateRequest *) prepareRequestFromState {
    // Get all certificates for users.
    // If certificate is already stored in database, validate it with hash only
    int totalCount = 0;
    hr_getCertificateRequest * certRequest = [[hr_getCertificateRequest alloc] init];
    for (PEXCertRefreshParams * param in self.state.requests) {
        PEXCertRefreshResult * curRes = self.state.responses[param.user];
        // Init response for the user if there is none.
        if (param.loadCertificateToResult && curRes == nil){
            curRes = [PEXCertRefreshResult resultWithParams:param];
            self.state.responses[param.user] = curRes;
        }

        // Check if re-check is needed.
        if (curRes != nil && curRes.recheckNeeded != nil && ![curRes.recheckNeeded boolValue]){
            DDLogVerbose(@"Recheck not needed for user: %@", param.user);
            continue;
        }

        hr_certificateRequestElement * cre = [[hr_certificateRequestElement alloc] init];
        cre.user = [param.user copy];

        // If we have a cert hash, add it here to save a bandwidth if certificate is OK.
        NSString * certHashId = param.existingCertHash2recheck;
        if (curRes != nil && curRes.certHash != nil) {
            DDLogVerbose(@"SIP: %@ found among stored hashes", param.user);
            cre.certificateHash = curRes.certHash;
        } else if (certHashId != nil){
            DDLogVerbose(@"SIP: %@ found among stored hashes", curRes.certHash);
            cre.certificateHash = certHashId;
            curRes.certHash = certHashId;
        }

        [certRequest.element addObject:cre];
        totalCount += 1;
    }

    return (totalCount == 0) ? nil : certRequest;
}

/**
* Call certificate refresh SOAP from state.
*/
-(void) soapRequest: (hr_getCertificateRequest *) certRequest {
    // Construct service binding.
    self.state.certResponse = nil;

    // Fail safe init of the soap task.
    if (self.state.soapTask == nil) {
        self.state.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.certrefresh"];
    }

    self.state.soapTask.logXML = YES;
    [self.state.soapTask prepareSOAP:self.privData];

    // Prepare SOAP operation.
    __weak __typeof(self) weakSelf = self;
    self.state.soapTask.desiredBody = [hr_getCertificateResponse class];
    self.state.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };

    self.state.soapTask.srcOperation = [[PhoenixPortSoap11Binding_getCertificate alloc]
            initWithBinding:self.state.soapTask.getBinding delegate:self.state.soapTask getCertificateRequest:certRequest];

    // Start task, sync blocking here, on purpose.
    [self.state.soapTask start];

    // Cancelled check block.
    if ([self.state.soapTask cancelDetected] || [self shouldCancel]) {
        [self subCancel];
        return;
    }

    // Error check block.
    if ([self.state.soapTask finishedWithError]) {
        [self subError:self.state.soapTask.error];
        return;
    }

    // Extract answer
    hr_getCertificateResponse *body = (hr_getCertificateResponse *) self.state.soapTask.responseBody;
    self.state.certResponse = body;
    self.state.soapTaskFinishState = PEX_TASK_FINISHED_OK;
}

-(void) subCancel{
    if (self.state != nil){
        self.state.soapTaskFinishState = PEX_TASK_FINISHED_CANCELLED;
    }
}

-(void) subError: (NSError *) error {
    if (self.state != nil){
        self.state.soapTaskFinishState = PEX_TASK_FINISHED_ERROR;
        self.state.soapTaskError = error;
    }
}

-(void) prepareState {
    if (self.state.overallProgress == nil){
        [self prepareOverallProgress];
    }

    if (self.cr == nil){
        self.cr = [PEXDbAppContentProvider instance];
    }
}

-(void) doRequest {
    // GetCertificateRequest is called here. List of users is added for which we are
    // interested in certificates.
    hr_getCertificateRequest * certRequest = [self prepareRequestFromState];
    [self soapRequest: certRequest];
}

/**
* Processes one certificate record from the server.
* Updates status in-memory certificate records, if there are such.
* Updates certificate database.
*
* Uses internal state.
*/
-(void) processOneResponseRecord: (hr_certificateWrapper *) wr{
    NSString * user = wr.user;
    __block PEXCertRefreshResult * curRes = self.state.responses[user];

    // test if we provided some certificate. If yes, look on certificate status.
    // If status = OK then update database (last query), otherwise delete record
    // because the new one with provided answer will be inserted afterwards.
    if (curRes != nil && curRes.certHash != nil){
        hr_certificateStatus providedStatus = wr.providedCertStatus;
        DDLogVerbose(@"Provided status for user: %@; status: %d", user, providedStatus);

        // Check if we have valid certificate of the user.
        if (providedStatus == hr_certificateStatus_ok){
            // Certificate is valid. Update last certificate check time in database so
            // we avoid redundant certificate checks.
            [PEXDbUserCertificate updateCertificateStatus:@(CERTIFICATE_STATUS_OK) owner:user cr:self.cr];

            // In memory data update.
            if (curRes.remoteCert != nil){
                curRes.remoteCert.certificateStatus = @(CERTIFICATE_STATUS_OK);
                curRes.remoteCert.dateLastQuery = [NSDate date];
            }

            DDLogVerbose(@"Certificate for user: %@; updated in database (query time also)", user);
            // We don't have to continue, certificate is valid -> move to next user.
            return;

        } else {
            // something is wrong with stored certificate,
            // deleting from certificate database.
            int deleteResult = [PEXDbUserCertificate deleteCertificateForUser:user cr:self.cr error:nil];
            DDLogInfo(@"Certificate for user [%@] removed; int: %d", user, deleteResult);
            // In memory data update.
            if (curRes != nil) {
                if (curRes.remoteCert != nil) {
                    curRes.remoteCert.certificateStatus = @(providedStatus);
                    curRes.remoteCert.dateLastQuery = [NSDate date];
                }

                curRes.remoteCertObj = nil;
            }
        }
    }

    // If we are here then
    //	a) user had no certificate stored
    //	b) or user had certificate stored, but was invalid
    // thus process this result - new certificate should be provided or error code if
    // something is wrong with certificate on server side (missing, invalid, revoked).
    @try {
        // Store certificate to database in each case (invalid vs. ok), both is
        // useful to know. We than have fresh data stored in database (no need to re-query
        // in case of error).
        int errorCode = 0;
        PEXX509 * crt = nil;
        PEXDbUserCertificate * crt2db = [[PEXDbUserCertificate alloc] init];

        errorCode = [PEXCertUtils processNewCertificate:wr user:user dbcrt:crt2db newCrt:&crt];
        if (errorCode != 0){
            if (curRes != nil){
                curRes.remoteCertObj = nil;
                curRes.statusCode = errorCode;
                if (curRes.remoteCert != nil){
                    curRes.remoteCert.certificateStatus = crt2db.certificateStatus;
                }
            }
        } else { // In memory update.
            if (curRes != nil) {
                curRes.remoteCertObj = [PEXCertificate certificateWithCert:crt];
                curRes.certHash = crt2db.certificateHash;
            }
        }

        // Store result of this query to DB. Can also have error code - usable not to query for
        // certificate too often.
        [PEXDbUserCertificate insertUnique:user cr:self.cr cv:crt2db.getDbContentValues];

        // Load new ID of the cert.
        if (curRes != nil && curRes.params.loadCertificateToResult && curRes.params.loadNewCertificateAfterInsert){
            PEXDbUserCertificate * tmpCrt = [PEXDbUserCertificate
                    newCertificateForUser:crt2db.owner cr:self.cr
                               projection: [PEXDbUserCertificate getNormalProjection]];

            crt2db.id = tmpCrt.id;
        }

        // In memory update - set new certificate to response.
        if (curRes != nil && curRes.params.loadCertificateToResult){
            curRes.remoteCert = crt2db;
        }

    } @catch (NSException * e) {
        DDLogError(@"Exception in certificate refresh thrown: %@", e);
    }
}

/**
* Process certificate fetch response stored in the state.
*/
-(void) doProcessResponse {
    [self doProcessResponseWithParentProgress:nil];
}

/**
* Process certificate fetch response stored in the state with custom parent progress.
* Progress monitoring is performed on the iteration basis.
*/
-(void) doProcessResponseWithParentProgress: (NSProgress *) parentProgress {
    if (self.cr == nil){
        self.cr = [PEXDbAppContentProvider instance];
    }

    // Get response from the state, check its sanity.
    hr_getCertificateResponse *resp = self.state.certResponse;
    if (resp==nil
            || resp.return_==nil
            || [resp.return_ count]==0){
        // Nothing to do, empty response.
        DDLogVerbose(@"Empty certificate response, nothing to do");
        return;
    }

    // If parent progress was provided, do the progress monitoring.
    NSProgress * progress = nil;
    if (parentProgress != nil && [parentProgress isEqual:[NSProgress currentProgress]]) {
        progress = [NSProgress alloc];
        [NSProgress doInitWithParentOnMainSync:progress parent:parentProgress userInfo:nil];
        [progress setProgressOnMain:[resp.return_ count] completedCount:0];
    } else {
        progress = [NSProgress progressWithTotalUnitCount:[resp.return_ count]];
    }

    // Iterate over returned array of certificate wrappers.
    for (id wrId in resp.return_) {
        if (wrId == nil || ![wrId isKindOfClass:[hr_certificateWrapper class]]) {
            DDLogError(@"Invalid element in certificate response, certificateWrapper expected; got=%@", wrId);
            if (self.doProgressMonitoring && progress != nil){
                [progress incProgressOnMain:1];
            }
            continue;
        }

        // Cancellation support.
        if (self.doProgressMonitoring && [progress isCancelled]){
            DDLogVerbose(@"Cancellation signal detected in certificate response provessing");
            self.state.overallTaskState = PEX_TASK_FINISHED_CANCELLED;
            break;
        }

        // Support for fine grained progress monitoring.
        if (self.doProgressMonitoring && progress != nil){
            [progress becomeCurrentWithPendingUnitCount:1];
        }

        // Process the response.
        hr_certificateWrapper * wr = (hr_certificateWrapper *) wrId;
        [self processOneResponseRecord: wr];

        // Increment progress on the main.
        if (self.doProgressMonitoring && progress != nil){
            [progress resignCurrent];
        }
    }

    // Task finished properly - update state.
    if (self.state.overallTaskState == PEX_TASK_FINISHED_NA){
        self.state.overallTaskState = PEX_TASK_FINISHED_OK;
    }
}

/**
* Wrapper for the whole certificate refresh process.
* Used when async nature, cancellation and detailed progress monitoring is not important.
*/
-(void) refreshCertificates {
    [self prepareState];

    // Certificate pre-load, determine if a remote cert fetch is needed.
    [self isCertRefreshNeeded:self.state.requests results:self.state.responses];

    // Do the request.
    [self doRequest];
    if (self.state.soapTaskFinishState != PEX_TASK_FINISHED_OK){
        DDLogVerbose(@"SOAP task failed somehow, cannot continue with processing");
        self.state.overallTaskState = self.state.soapTaskFinishState;
        return;
    }

    // Process response.
    [self doProcessResponseWithParentProgress:self.state.processProgress];
}

-(void) cancelRefresh{
    if (self.state.overallProgress != nil){
        [self.state.overallProgress cancel];
    }

    if (self.state.callProgress != nil){
        [self.state.callProgress cancel];
    }

    if (self.state.processProgress != nil){
        [self.state.processProgress cancel];
    }
}

-(PEX_TASK_FINIHED_STATE) getFinishedState {
    return self.state.overallTaskState;
}

-(BOOL) didLoadedValidCertificateForUser: (NSString *) user {
    // Whole operation has to be finished with OK.
    if (self.state.overallTaskState != PEX_TASK_FINISHED_OK){
        return NO;
    }

    // Response has to exist.
    PEXCertRefreshResult * curRes = [self getResultForUser:user];
    if (curRes == nil){
        return NO;
    }

    // If status code is negative, there was an error.
    if (curRes.statusCode < 0){
        return NO;
    }

    // There was something wrong with the certificate.
    if (curRes.params != nil
            && curRes.params.loadCertificateToResult
            && curRes.remoteCert != nil
            && curRes.remoteCert.certificateStatus != nil
            && ![curRes.remoteCert.certificateStatus isEqualToNumber:@(CERTIFICATE_STATUS_OK)])
    {
        return NO;
    }

    return YES;
}

-(PEXCertRefreshResult *) getResultForUser: (NSString *) user {
    if (self.state.responses == nil){
        return nil;
    }

    PEXCertRefreshResult * curRes = self.state.responses[user];
    return curRes;
}

-(PEXCertificate *) getResultCertificate: (NSString *) user {
    PEXCertRefreshResult * curRes = [self getResultForUser:user];
    if (curRes == nil){
        return nil;
    }

    return curRes.remoteCertObj;
}

-(PEXDbUserCertificate *) getResultDBCertForUser: (NSString *) user {
    PEXCertRefreshResult * curRes = [self getResultForUser:user];
    if (curRes == nil){
        return nil;
    }

    return curRes.remoteCert;
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