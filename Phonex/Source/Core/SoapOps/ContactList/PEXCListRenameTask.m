//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListRenameTask.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXSipUri.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbContact.h"
#import "PEXTask_Protected.h"
#import "PEXDbCallLog.h"

// Error exports
NSString * const PEXCListRenameErrorDomain = @"PEXCListRenameErrorDomain";
NSInteger const PEXCListRenameErrorUserNotFound = 1;
NSInteger const PEXCListRenameErrorServerSide = 2;

// Main task state.
@interface PEXCListRenameTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSError * lastError;
@property(nonatomic) NSString * user2add;
@property(nonatomic) NSString * contactDomain;
@property(nonatomic) BOOL userServerUpdated;
@end

@implementation PEXCListRenameTaskState {}
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

// Private part of the PEXCListRenameTask - with state.
@interface PEXCListRenameTask ()  { }
@property(atomic) PEXCListRenameTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXCListRenameSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXCListRenameTaskState * state;
@property (nonatomic, weak) PEXCListChangeParams * params;
@property (nonatomic, weak) PEXCListRenameTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXCListRenameTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXCListRenameSubtask {}
- (id) initWithDel:(PEXCListRenameTask *)delegate andName: (NSString *) taskName {
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
@interface PEXCListRenamePrepareTask : PEXCListRenameSubtask { }
@end

// Delete contact from the server.
@interface PEXCListRenameSOAPTask : PEXCListRenameSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Commit local contact storage, delete artifacts.
@interface PEXCListRenameDeleteTask : PEXCListRenameSubtask { }
@end

//
// Implementation part
//
@implementation PEXCListRenamePrepareTask
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
        [self subError:[NSError errorWithDomain:PEXCListRenameErrorDomain code:PEXCListRenameErrorUserNotFound userInfo:nil]];
        return;
    }
}

@end

@implementation PEXCListRenameSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];
    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clistrename.soap"];
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
    cElem.action = hr_contactlistAction_update;
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
        DDLogWarn(@"Empty response for updating a contact from contact list");
        [self subError:[NSError errorWithDomain:PEXCListRenameErrorDomain code:PEXCListRenameErrorServerSide userInfo:nil]];
    }

    id resp = body.return_[0];
    if (resp == nil || ![resp isKindOfClass:[hr_contactlistReturn class]]){
        DDLogWarn(@"Response [0] is nil or of improper format");
        [self subError:[NSError errorWithDomain:PEXCListRenameErrorDomain code:PEXCListRenameErrorServerSide userInfo:nil]];
    }

    hr_contactlistReturn * clReturn = (hr_contactlistReturn * ) resp;
    if (clReturn.resultCode == nil || [clReturn.resultCode compare:@0] == NSOrderedAscending){
        DDLogWarn(@"Something wrong during updating from contact list, server response: %@", clReturn.resultCode);
        [self subError:[NSError errorWithDomain:PEXCListRenameErrorDomain code:PEXCListRenameErrorServerSide userInfo:nil]];
    }

    self.state.userServerUpdated = YES;
}
@end

@implementation PEXCListRenameDeleteTask
- (void)prepareProgress {
    self.progress = [NSProgress progressWithTotalUnitCount: 2];
}

- (void)subMain {
    BOOL isNowHidden = NO;
    NSString * newAlias = [PEXDbContact stripHidePrefix:self.params.diplayName wasPresent:&isNowHidden];

    // Rename locally
    @try {
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEX_DBCL_FIELD_DISPLAY_NAME string:newAlias];
        [cv put:PEX_DBCL_FIELD_HIDE_CONTACT boolean:isNowHidden];

        [self.params.cr update:[PEXDbContact getURI]
                 ContentValues:cv
                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                 selectionArgs:@[self.state.user2add]];

        DDLogVerbose(@"Update task: contact updated");
    } @catch(NSException * ex){
        DDLogError(@"Exception during deleting contact in rollback phase. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }

    // Rename in call log.
    @try {
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME string: newAlias];

        [self.params.cr update:[PEXDbCallLog getURI]
                 ContentValues:cv
                selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS]
            selectionArgs:@[self.state.user2add]];

        DDLogVerbose(@"Rename task: call log updated");
    } @catch(NSException * ex){
        DDLogError(@"Exception during renaming contact calllog. Exception=%@", ex);
    } @finally{
        [self incProgressOnMain:1 async:NO];
    }
}
@end

@implementation PEXCListRenameTask {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.params = nil;
        self.privData = nil;

        self.taskName = @"ContactlistRename";

        // Initialize empty state
        [self setState: [[PEXCListRenameTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PCLRT_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXCListRenamePrepareTask       alloc] initWithDel:self andName:@"Prepare"]    id:PCLRT_PREPARE];
    [self setSubTask:[[PEXCListRenameSOAPTask          alloc] initWithDel:self andName:@"SOAPRename"] id:PCLRT_RENAME_SOAP];
    [self setSubTask:[[PEXCListRenameDeleteTask         alloc] initWithDel:self andName:@"Update"]    id:PCLRT_RENAME_LOCALLY];

    // Add dependencies to the tasks.
    [self.tasks[PCLRT_RENAME_SOAP]    addDependency:self.tasks[PCLRT_PREPARE]];
    [self.tasks[PCLRT_RENAME_LOCALLY] addDependency:self.tasks[PCLRT_RENAME_SOAP]];

    // Mark last task so we know what to wait for.
    [self.tasks[PCLRT_RENAME_LOCALLY] setIsLast:YES];
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