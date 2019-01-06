//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListAddTask.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXSipUri.h"
#import "PEXDbUserCertificate.h"
#import "PEXMessageDigest.h"
#import "PEXCryptoUtils.h"
#import "PEXDbContact.h"
#import "PEXTask_Protected.h"
#import "PEXDbCursor.h"
#import "PEXStringUtils.h"
#import "PEXService.h"
#import "PEXSecurityCenter.h"
#import "PEXPresenceCenter.h"
#import "PEXDbContactNotification.h"

// Error exports
NSString * const PEXCListAddErrorDomain = @"PEXCListAddErrorDomain";
NSInteger const PEXClistAddErrorUserAlreadyAdded = 1;
NSInteger const PEXClistAddErrorServerSideAdd = 2;

// Main task state.
@interface PEXCListAddTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSError * lastError;
@property(nonatomic) NSString * user2add;
@property(nonatomic) NSString * contactDomain;

@property(nonatomic) BOOL userStored;
@property(nonatomic) BOOL userServerStored;
@property(nonatomic) BOOL certStored;

@property(nonatomic) hr_certificateWrapper * wr;
@property(nonatomic) NSData * certDER;
@property(nonatomic) NSString * certHash;

@property(atomic) hr_getCertificateResponse * certResponse;
@end

@implementation PEXCListAddTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.lastError = nil;
        self.certResponse = nil;
        self.userStored = NO;
        self.certStored = NO;
        self.userServerStored = NO;
    }

    return self;
}

@end

// Private part of the PEXCListAddTask - with state.
@interface PEXCListAddTask ()  { }
@property(atomic) PEXCListAddTaskState * state;
- (void) scheduleRollbackTask;
@end

// Subtask parent - has internal state.
@interface PEXCListAddSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXCListAddTaskState * state;
@property (nonatomic, weak) PEXCListChangeParams * params;
@property (nonatomic, weak) PEXCListAddTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXCListAddTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXCListAddSubtask {}
- (id) initWithDel:(PEXCListAddTask *)delegate andName: (NSString *) taskName {
    self = [super initWith:delegate andName:taskName];
    self.delegate = delegate;
    self.ownDelegate = delegate;
    self.state = [delegate state];
    self.params = [delegate params];
    self.privData = [delegate privData];
    return self;
}

-(void) subCancel {
    [super subCancel];
    self.state.cancelDetected=YES;
}

- (void)subError:(NSError *)error {
    [super subError:error];
    self.state.errorOccurred = YES;
    self.state.lastError = error;
}

- (BOOL)shouldCancel {
    BOOL shouldCancel = [super shouldCancel];
    if (shouldCancel) return YES;

    return  self.state.errorOccurred || self.state.cancelDetected;
}

@end

//
// Subtasks
//

// Prepare for SOAP call / sanitization.
@interface PEXCListAddPrepareTask : PEXCListAddSubtask { }
@end

// SOAP call for certificate fetch.
@interface PEXCListAddCertRefreshTask : PEXCListAddSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Certificate validation & processing.
@interface PEXCListAddCertProcessTask : PEXCListAddSubtask { }
@end

// Store contact on the server.
@interface PEXCListAddSOAPTask : PEXCListAddSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Commit local contact storage, save certificate.
@interface PEXCListAddStoreTask : PEXCListAddSubtask { }
@end

// State cleanup on error / cancellation. Rollback.
@interface PEXCListAddCancelTask : PEXCListAddSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Checks if a rollback is needed, i.e., error occurred.
@interface PEXCListCheckForErrorTask : PEXCListAddSubtask { }
@end

//
// Implementation part
//
@implementation PEXCListAddPrepareTask
- (void)subMain {
    // Sanitize name to add. Add a default domain if needed.
    self.state.user2add = [[PEXService instance] sanitizeUserContact: self.params.userName];

    // Are we already in the database?
    PEXDbCursor * c = [self.params.cr query:[PEXDbContact getURI]
                                 projection:[PEXDbContact getLightProjection]
                                  selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                              selectionArgs:@[self.state.user2add]
                                  sortOrder:nil];

    if (c != nil && c.getCount > 0) {
        DDLogInfo(@"Database already contains given SIP [%@]", self.state.user2add);
        [self subError: [NSError errorWithDomain:PEXCListAddErrorDomain code:PEXClistAddErrorUserAlreadyAdded userInfo:nil]];
        return;
    }

    // Default display name.
    if ([PEXStringUtils isEmpty:self.params.diplayName]) {
        PEXSIPURIParsedSipContact *contact = [PEXSipUri parseSipContact:self.privData.username];
        self.params.diplayName = contact.userName;
    }

    // If add as hidden, prefix with "_".
    if (self.params.addAsHidden){
        self.params.diplayName = [NSString stringWithFormat:@"%s%@", PEX_CONTACT_HIDDEN_PREFIX, self.params.diplayName];
    }
}

@end

@implementation PEXCListAddCertRefreshTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];
    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clistadd.soap.cert"];
    [self.soapTask prepareProgress];
    [self.progress resignCurrent];
}

- (void)subMain {
    hr_getCertificateRequest * certRequest = [[hr_getCertificateRequest alloc] init];
    hr_certificateRequestElement * cre = [[hr_certificateRequestElement alloc] init];
    cre.user = [self.state.user2add copy];
    [certRequest.element addObject:cre];

    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.soapTask.desiredBody = [hr_getCertificateResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_getCertificate alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask getCertificateRequest:certRequest];

    // Start task, sync blocking here, on purpose.
    [self.soapTask start];

    // Cancelled check block.
    if ([self.soapTask cancelDetected] || [self shouldCancel]) {
        [self subCancel];
        return;
    }

    // Error check block.
    if ([self.soapTask finishedWithError]) {
        [self subError:self.soapTask.error];
        return;
    }

    // Extract answer
    hr_getCertificateResponse *body = (hr_getCertificateResponse *) self.soapTask.responseBody;
    self.state.certResponse = body;
}
@end

@implementation PEXCListAddCertProcessTask
- (void)subMain {
    // Reconstruct certificate response.
    hr_getCertificateResponse *resp = self.state.certResponse;
    if (resp==nil
            || resp.return_==nil
            || [resp.return_ count]==0){
        // Nothing to do, empty response.
        DDLogVerbose(@"Empty certificate response, nothing to do");
        return;
    }

    id wrId = resp.return_[0];
    if (wrId == nil || ![wrId isKindOfClass:[hr_certificateWrapper class]]) {
        DDLogError(@"Invalid element in certificate response, certificateWrapper expected; got=%@", wrId);
        return;
    }

    hr_certificateWrapper * wr = (hr_certificateWrapper *) wrId;
    NSString * user = wr.user;
    NSData * cert = wr.certificate;
    self.state.wr = wr;

    // Certificate processing.
    @try {
        do {
            // Returned certificate is valid, process & store it.
            if (wr.status != CERTIFICATE_STATUS_OK || cert == nil || cert.length == 0) {
                break;
            }

            PEXX509 *crt = [PEXCryptoUtils importCertificateFromDERWrap:cert];
            if (!crt.isAllocated) {
                DDLogWarn(@"Problem with a certificate parsing for user %@", user);
                break;
            }

            // check CN match
            NSString *cnFromCert = [PEXCryptoUtils getCNameCrt:crt.getRaw totalCount:nil];
            if (![user isEqualToString:cnFromCert] || ![user isEqualToString:self.state.user2add]) {
                DDLogError(@"Security alert! Server returned certificate with different CN!");
                break;
            } else {
                DDLogVerbose(@"Certificate CN matches for: %@", cnFromCert);
            }

            // Verify new certificate with trust verifier
            BOOL crtOk = [PEXSecurityCenter tryOsslCertValidate:crt settings:[PEXCertVerifyOptions optionsWithAllowOldCaExpired:YES]];
            if (!crtOk){
                break;
            }

            // Sec: Re-export cert to DER to get rid of potential rubbish.
            NSData *certDER = [PEXCryptoUtils exportCertificateToDERWrap:crt];
            if (certDER == nil) {
                DDLogError(@"Cannot export X509 certificate to DER");
                break;
            }

            // Store certificate to database.
            // We now need to compute certificate digest.
            NSString *certificateHash = [PEXMessageDigest getCertificateDigestDER:certDER];
            DDLogVerbose(@"Certificate digest computed[%@]: %@", cnFromCert, certificateHash);

            self.state.certDER = certDER;
            self.state.certHash = certificateHash;
        } while(0);
    } @catch (NSException * e) {
        DDLogWarn(@"Exception thrown: %@", e);
        self.state.certDER = nil;
        self.state.certHash = nil;
    }
}
@end

@implementation PEXCListAddSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];
    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clistadd.soap"];
    [self.soapTask prepareProgress];
    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Construct request.
    hr_contactlistChangeRequest *request = [[hr_contactlistChangeRequest alloc] init];
    hr_contactlistChangeRequestElement *cElem = [[hr_contactlistChangeRequestElement alloc] init];
    hr_userIdentifier * ui2 = [[hr_userIdentifier alloc] init];
    ui2.userSIP = self.state.user2add;
    cElem.action = hr_contactlistAction_add;
    cElem.user = ui2;
    cElem.displayName = self.params.diplayName;
    cElem.whitelistAction = self.params.inWhitelist ? hr_whitelistAction_enable : hr_whitelistAction_disable;
    [request.contactlistChangeRequestElement addObject:cElem];

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.soapTask.desiredBody = [hr_contactlistChangeResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_contactlistChange alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask contactlistChangeRequest:request];

    // Start task, sync blocking here, on purpose.
    [self.soapTask start];

    // Cancelled check block.
    if ([self.soapTask cancelDetected] || [self shouldCancel]) {
        [self subCancel];
        return;
    }

    // Error check block.
    if ([self.soapTask finishedWithError]) {
        [self subError: self.soapTask.error];
        return;
    }

    // Extract answer
    hr_contactlistChangeResponse *body = (hr_contactlistChangeResponse *) self.soapTask.responseBody;

    // Simple answer check.
    if (body.return_ == nil || body.return_.count < 1){
        DDLogWarn(@"Empty response for add a new contact to contact list");
        [self subError: [NSError errorWithDomain:PEXCListAddErrorDomain code:PEXClistAddErrorServerSideAdd userInfo:nil]];
    }

    id resp = body.return_[0];
    if (resp == nil || ![resp isKindOfClass:[hr_contactlistReturn class]]){
        DDLogWarn(@"Response [0] is nil or of improper format");
        [self subError: [NSError errorWithDomain:PEXCListAddErrorDomain code:PEXClistAddErrorServerSideAdd userInfo:nil]];
    }

    hr_contactlistReturn * clReturn = (hr_contactlistReturn * ) resp;
    if (clReturn.resultCode == nil || [clReturn.resultCode compare:@0] == NSOrderedAscending){
        DDLogWarn(@"Something wrong during adding to contact list, server response: %@", clReturn.resultCode);
        [self subError: [NSError errorWithDomain:PEXCListAddErrorDomain code:PEXClistAddErrorServerSideAdd userInfo:nil]];
    }

    self.state.userServerStored = YES;
}
@end

@implementation PEXCListAddStoreTask
- (void)subMain {
    @try {
        PEXDbContact *clist = [[PEXDbContact alloc] init];
        clist.account = @1;
        clist.sip = self.state.user2add;
        clist.displayName = self.params.diplayName;
        clist.inWhitelist = self.params.inWhitelist;
        clist.certificateHash = self.state.certHash;
        clist.dateCreated = [NSDate date];
        clist.dateLastModified = [NSDate date];
        clist.hideContact = @(self.params.addAsHidden);
        [self.params.cr insert:[PEXDbContact getURI] contentValues:[clist getDbContentValues]];

        self.state.userStored = YES;
    } @catch(NSException * ex){
        DDLogError(@"Exception during storing a new contact to the database. Exception=%@", ex);
    }

    // TODO: add to whitelist.
    // Now add to filter to accept incoming calls from white-listed entries.
    //ClistFetchTask.addToFilterWhitelist(this.context, profile.id, par.getUserName());

    // Store certificate to database in each case (invalid vs. ok), both is
    // useful to know. We than have fresh data stored in database (no need to re-query
    // in case of error).
    PEXDbUserCertificate *crt2db = [[PEXDbUserCertificate alloc] init];
    crt2db.dateCreated = [NSDate date];
    crt2db.dateLastQuery = [NSDate date];
    crt2db.certificateStatus = @(self.state.wr.status);
    crt2db.owner = self.state.user2add;
    if (self.state.certDER != nil){
        crt2db.certificate = self.state.certDER;
        crt2db.certificateHash = self.state.certHash;
    }

    [PEXDbUserCertificate insertUnique:crt2db.owner cr:self.params.cr cv:crt2db.getDbContentValues];

    // Remove any contact pairing requests from the database.
    [PEXDbContactNotification deleteRequestsFromUser:self.state.user2add cr:self.params.cr];

    [PEXPresenceCenter broadcastUserAddedChange];
    self.state.certStored = YES;
}
@end

@implementation PEXCListAddCancelTask
- (void)subMain {
    if (self.state.user2add == nil){
        DDLogDebug(@"User2add is nil, cannot continue");
        return;
    }
    DDLogVerbose(@"Rollback task started");

    // Rollback local certificate store - delete it.
    @try {
        if (self.state.certStored) {
            [self.params.cr delete:[PEXDbUserCertificate getURI]
                         selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER]
                     selectionArgs:@[self.state.user2add]];
            self.state.certStored = NO;
            DDLogVerbose(@"Rollback task: deleted certificate");
        }
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact certificate in rollback phase. Exception=%@", ex);
    }

    // Rollback user local storage - delete it.
    @try {
        if (self.state.userStored) {
            [self.params.cr delete:[PEXDbContact getURI]
                         selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                     selectionArgs:@[self.state.user2add]];
            self.state.userStored = NO;
            DDLogVerbose(@"Rollback task: deleted contact");
        }
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact in rollback phase. Exception=%@", ex);
    }

    // Rollback on the server side if needed. Request deletion.
    @try {
        if (self.state.userServerStored) {

            // Construct service binding.
            self.soapTask.logXML = YES;
            [self.soapTask prepareSOAP:self.privData];

            // Construct request.
            hr_contactlistChangeRequest *request = [[hr_contactlistChangeRequest alloc] init];
            hr_contactlistChangeRequestElement *cElem = [[hr_contactlistChangeRequestElement alloc] init];
            hr_userIdentifier * ui2 = [[hr_userIdentifier alloc] init];
            ui2.userSIP = self.state.user2add;
            cElem.action = hr_contactlistAction_remove;
            cElem.user = ui2;
            cElem.displayName = self.params.diplayName;
            cElem.whitelistAction = self.params.inWhitelist ? hr_whitelistAction_enable : hr_whitelistAction_disable;
            [request.contactlistChangeRequestElement addObject:cElem];

            // Prepare SOAP operation.
            self.soapTask.desiredBody = [hr_contactlistChangeResponse class];
            self.soapTask.shouldCancelBlock = nil; // Not cancellable.
            self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_contactlistChange alloc]
                    initWithBinding:self.soapTask.getBinding delegate:self.soapTask contactlistChangeRequest:request];

            // Start task, sync blocking here, on purpose.
            [self.soapTask start];
            DDLogVerbose(@"Rollback task: deleted from the server");
        }
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact in rollback phase. Exception=%@", ex);
    }

    // Cancellation task has to finish.
    DDLogVerbose(@"Cancellation task finished");
}
@end

@implementation PEXCListCheckForErrorTask
- (void)subMain {
    // Check for error, if is rollback needed.
    if (!self.state.errorOccurred){
        DDLogVerbose(@"Error check passed");
        return;
    }

    // Error occurred, rollback is needed.
    [self.ownDelegate scheduleRollbackTask];
    // Give some time to the scheduler to realize new task was added.
    [NSThread sleepForTimeInterval:0.5];
}
@end

@implementation PEXCListAddTask {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.params = nil;
        self.privData = nil;

        self.taskName = @"ContactlistAdd";

        // Initialize empty state
        [self setState: [[PEXCListAddTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PCLAT_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXCListAddPrepareTask       alloc] initWithDel:self andName:@"Prepare"]     id:PCLAT_PREPARE];
    [self setSubTask:[[PEXCListAddCertRefreshTask   alloc] initWithDel:self andName:@"CertFetch"]   id:PCLAT_CERT_FETCH];
    [self setSubTask:[[PEXCListAddCertProcessTask   alloc] initWithDel:self andName:@"CertProcess"] id:PCLAT_CERT_PROCESS];
    [self setSubTask:[[PEXCListAddSOAPTask          alloc] initWithDel:self andName:@"SOAPAdd"]     id:PCLAT_CONTACT_STORE_SOAP];
    [self setSubTask:[[PEXCListAddStoreTask         alloc] initWithDel:self andName:@"StoreUser"]   id:PCLAT_CONTACT_STORE_LOCALLY];
    [self setSubTask:[[PEXCListCheckForErrorTask    alloc] initWithDel:self andName:@"CheckState"]  id:PCLAT_ROLLBACK_NEEDED_CHECK];

    // Add dependencies to the tasks.
    [self.tasks[PCLAT_CERT_FETCH]            addDependency:self.tasks[PCLAT_PREPARE]];
    [self.tasks[PCLAT_CERT_PROCESS]          addDependency:self.tasks[PCLAT_CERT_FETCH]];
    [self.tasks[PCLAT_CONTACT_STORE_SOAP]    addDependency:self.tasks[PCLAT_CERT_PROCESS]];
    [self.tasks[PCLAT_CONTACT_STORE_LOCALLY] addDependency:self.tasks[PCLAT_CONTACT_STORE_SOAP]];
    [self.tasks[PCLAT_ROLLBACK_NEEDED_CHECK] addDependency:self.tasks[PCLAT_CONTACT_STORE_LOCALLY]];

    // Mark last task so we know what to wait for.
    [self.tasks[PCLAT_ROLLBACK_NEEDED_CHECK] setIsLast:YES];
    // Has to be executed anyway, checks for errors.
    [self.tasks[PCLAT_ROLLBACK_NEEDED_CHECK] setRunAnyway:YES];
}

- (void)subTasksFinished:(int)waitResult {
    [super subTasksFinished:waitResult];

    PEXTaskFinishedEvent * finResult;
    // If was cancelled - signalize cancel ended.
    if (waitResult==kWAIT_RESULT_CANCELLED){
        [self cancelEnded:NULL];
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_CANCELLED];
    } else if (self.state.errorOccurred || waitResult==kWAIT_RESULT_TIMEOUTED) {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_ERROR];
        finResult.finishError = self.state.lastError;
    } else {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_OK];
    }

    self.finishedEvent = finResult;
    DDLogVerbose(@"End of waiting loop.");
}

- (void) scheduleRollbackTask {
    // Add alternative cancellation workflow here.
    // Adding a contact manipulates global application
    // state and in case of an error or cancelation event it has to be rolled back
    // properly.
    // At first, disable last task status so its finishing won't stop waiting.
    [self.tasks[PCLAT_ROLLBACK_NEEDED_CHECK] setIsLast:NO];

    // Add a new task for state rollback to the task queue.
    [self setSubTask:[[PEXCListAddCancelTask alloc] initWithDel:self andName:@"Cancel"] id:PCLAT_ROLLBACK];
    // Dependency has to be preserved still.
    [self.tasks[PCLAT_ROLLBACK] addDependency:self.tasks[PCLAT_ROLLBACK_NEEDED_CHECK]];
    // Mark last task so we know what to wait for.
    [self.tasks[PCLAT_ROLLBACK] setIsLast:YES];
    // Set run anyway flag so this task is started in spite of global cancellation - required for cancellation tasks.
    [self.tasks[PCLAT_ROLLBACK] setRunAnyway:YES];

    // Start cancellation task by adding to the operation queue.
    [self.opqueue addOperation:self.tasks[PCLAT_ROLLBACK]];
    DDLogVerbose(@"Rollback task added to the queue.");
}

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");

   [self scheduleRollbackTask];
}

- (BOOL) shouldFinishOnTaskFinished: (const PEXTaskEvent *const)event{
    // Here we implement custom cancellation logic so wait for finishing in any case.
    return NO;
}

@end