//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListRemoveTask.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXSipUri.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbContact.h"
#import "PEXTask_Protected.h"
#import "PEXDBMessage.h"
#import "PEXDbCallLog.h"

// Error exports
NSString * const PEXCListRemoveErrorDomain = @"PEXCListRemoveErrorDomain";
NSInteger const PEXCListRemoveErrorUserNotFound = 1;
NSInteger const PEXCListRemoveErrorServerSide = 2;

// Main task state.
@interface PEXCListRemoveTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSError * lastError;
@property(nonatomic) NSString * user2add;
@property(nonatomic) NSString * contactDomain;
@property(nonatomic) BOOL userServerUpdated;
@end

@implementation PEXCListRemoveTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.lastError = nil;
        self.userServerUpdated = NO;
    }

    return self;
}

@end

// Private part of the PEXCListRemoveTask - with state.
@interface PEXCListRemoveTask ()  { }
@property(atomic) PEXCListRemoveTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXCListRemoveSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXCListRemoveTaskState * state;
@property (nonatomic, weak) PEXCListChangeParams * params;
@property (nonatomic, weak) PEXCListRemoveTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXCListRemoveTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXCListRemoveSubtask {}
- (id) initWithDel:(PEXCListRemoveTask *)delegate andName: (NSString *) taskName {
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
@interface PEXCListRemovePrepareTask : PEXCListRemoveSubtask { }
@end

// Delete contact from the server.
@interface PEXCListRemoveSOAPTask : PEXCListRemoveSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Commit local contact storage, delete artifacts.
@interface PEXCListRemoveDeleteTask : PEXCListRemoveSubtask { }
@end

//
// Implementation part
//
@implementation PEXCListRemovePrepareTask
- (void)subMain {
    // Sanitize name to add. Add a default domain if needed.
    self.state.user2add = self.params.userName;
    if ([self.state.user2add rangeOfString:@"@"].location == NSNotFound){
        // Obtain default domain of the current user.

        PEXSIPURIParsedSipContact * contact = [PEXSipUri parseSipContact:self.privData.username];
        if (contact!=nil && contact.domain!=nil){
            self.state.user2add = [NSString stringWithFormat:@"%@@%@", self.params.userName, contact.domain];
        }
    }

    // Are we already in the database?
    PEXDbCursor * c = [self.params.cr query:[PEXDbContact getURI]
                                 projection:[PEXDbContact getLightProjection]
                                  selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                              selectionArgs:@[self.state.user2add]
                                  sortOrder:nil];
    if (c == nil || c.getCount == 0) {
        DDLogInfo(@"Given SIP [%@] not found in database, already deleted?", self.state.user2add);
        [self subError:[NSError errorWithDomain:PEXCListRemoveErrorDomain code:PEXCListRemoveErrorUserNotFound userInfo:nil]];
        return;
    }
}

@end

@implementation PEXCListRemoveSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];
    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clistremove.soap"];
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
    cElem.action = hr_contactlistAction_remove;
    cElem.user = ui2;
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
        DDLogWarn(@"Empty response for deleting a new contact from contact list");
        [self subError:[NSError errorWithDomain:PEXCListRemoveErrorDomain code:PEXCListRemoveErrorServerSide userInfo:nil]];
    }

    id resp = body.return_[0];
    if (resp == nil || ![resp isKindOfClass:[hr_contactlistReturn class]]){
        DDLogWarn(@"Response [0] is nil or of improper format");
        [self subError:[NSError errorWithDomain:PEXCListRemoveErrorDomain code:PEXCListRemoveErrorServerSide userInfo:nil]];
    }

    hr_contactlistReturn * clReturn = (hr_contactlistReturn * ) resp;
    if (clReturn.resultCode == nil || [clReturn.resultCode compare:@0] == NSOrderedAscending){
        DDLogWarn(@"Something wrong during removing from contact list, server response: %@", clReturn.resultCode);
        [self subError:[NSError errorWithDomain:PEXCListRemoveErrorDomain code:PEXCListRemoveErrorServerSide userInfo:nil]];
    }

    self.state.userServerUpdated = YES;
}
@end

@implementation PEXCListRemoveDeleteTask
- (void)prepareProgress {
    self.progress = [NSProgress progressWithTotalUnitCount: 4];
}

- (void)subMain {
    // Local certificate store - delete it.
    @try {
        [self.params.cr delete:[PEXDbUserCertificate getURI]
                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER]
                 selectionArgs:@[self.state.user2add]];
        DDLogVerbose(@"Remove task: deleted certificate");
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact certificate in rollback phase. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }

    // Delete from messages.
    @try {
        [self.params.cr delete:[PEXDbMessage getURI]
                     selection:[NSString stringWithFormat:@"WHERE %@=? OR %@=?", PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO]
                 selectionArgs:@[self.state.user2add, self.state.user2add]];
        DDLogVerbose(@"Remove task: deleted messages");
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact mesages. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }

    // Delete from call firewall.
    // Implicit. Call firewall is based on account database.

    // Delete from call logs.
    @try {
        [self.params.cr delete:[PEXDbCallLog getURI]
                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS]
                 selectionArgs:@[self.state.user2add]];
        DDLogVerbose(@"Remove task: deleted call log");
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact calllog. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }

    // TODO: Delete DH Keys storage.
    // TODO: Delete DH Keys from the server - async, in background, trigger key resync.

    // User local storage - delete it.
    @try {
        [self.params.cr delete:[PEXDbContact getURI]
                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                 selectionArgs:@[self.state.user2add]];
        DDLogVerbose(@"Remove task: deleted contact");
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact in rollback phase. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }
}
@end

@implementation PEXCListRemoveTask {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.params = nil;
        self.privData = nil;

        self.taskName = @"ContactlistRemove";

        // Initialize empty state
        [self setState: [[PEXCListRemoveTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PCLDT_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXCListRemovePrepareTask       alloc] initWithDel:self andName:@"Prepare"]     id:PCLDT_PREPARE];
    [self setSubTask:[[PEXCListRemoveSOAPTask          alloc] initWithDel:self andName:@"SOAPAdd"]     id:PCLDT_DELETE_SOAP];
    [self setSubTask:[[PEXCListRemoveDeleteTask         alloc] initWithDel:self andName:@"StoreUser"]  id:PCLDT_DELETE_LOCALLY];

    // Add dependencies to the tasks.
    [self.tasks[PCLDT_DELETE_SOAP]    addDependency:self.tasks[PCLDT_PREPARE]];
    [self.tasks[PCLDT_DELETE_LOCALLY] addDependency:self.tasks[PCLDT_DELETE_SOAP]];

    // Mark last task so we know what to wait for.
    [self.tasks[PCLDT_DELETE_LOCALLY] setIsLast:YES];
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

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");
}

@end