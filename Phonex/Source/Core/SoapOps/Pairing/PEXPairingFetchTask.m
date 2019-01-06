//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPairingFetchTask.h"
#import "PEXCListFetchParams.h"
#import "hr.h"
#import "PEXPairingFetchParams.h"
#import "PEXSOAPTask.h"
#import "PEXTask_Protected.h"
#import "PEXDbContactNotification.h"
#import "PEXUtils.h"
#import "PEXDbContact.h"

@interface PEXPairingFetchTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic, readwrite) NSDate * lastFetchTime;
@property(atomic) NSError * lastError;
@property(atomic) hr_pairingRequestFetchResponse *fetchResponse;
@end

@implementation PEXPairingFetchTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.lastError = nil;
        self.fetchResponse = nil;
    }

    return self;
}

@end

// Private part of the PEXPairingFetchTask
@interface PEXPairingFetchTask ()  { }
@property(atomic) PEXPairingFetchTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXPairingFetchSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXPairingFetchTaskState * state;
@property (nonatomic, weak) PEXPairingFetchParams * params;
@property (nonatomic, weak) PEXPairingFetchTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXPairingFetchTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXPairingFetchSubtask {}
- (id) initWithDel:(PEXPairingFetchTask *)delegate andName: (NSString *) taskName {
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
@interface PEXPairingFetchSOAPTask : PEXPairingFetchSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXPairingFetchProcessTask : PEXPairingFetchSubtask { }
@end

//
// Implementation part
//
@implementation PEXPairingFetchSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.pairingfetch.soap"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Construct request.
    hr_pairingRequestFetchRequest *request = [[hr_pairingRequestFetchRequest alloc] init];
    DDLogVerbose(@"Request constructed %@, for user=%@", request, self.privData.username);

    // Prepare SOAP operation.
    __weak __typeof(self) weakSelf = self;
    self.state.lastFetchTime = [NSDate date];
    self.soapTask.desiredBody = [hr_pairingRequestFetchResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_pairingRequestFetch alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask pairingRequestFetchRequest:request];

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
    hr_pairingRequestFetchResponse *body = (hr_pairingRequestFetchResponse *) self.soapTask.responseBody;
    self.state.fetchResponse = body;
}
@end

@implementation PEXPairingFetchProcessTask
- (void)subMain {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    @try {
        // Load all database records, indexed by their server IDs.
        NSMutableDictionary * localRecords = [NSMutableDictionary dictionary];
        // Server IDs of records to delete from local database (not present on the server)
        NSMutableSet * localRecordsToDelete = [NSMutableSet set];
        // Server IDs of records that were updated - seen flag set to 0 again.
        NSMutableSet * localRecordsUpdated = [NSMutableSet set];
        PEXDbCursor * c = [cr query:[PEXDbContactNotification getURI] projection:[PEXDbContactNotification getFullProjection] selection:@" WHERE 1" selectionArgs:@[] sortOrder:nil];
        while([c moveToNext]){
            PEXDbContactNotification * curNotif = [PEXDbContactNotification contactNotificationFromCursor:c];
            localRecords[curNotif.serverId] = curNotif;
            // Mark for deletion, if present in server response -> remove from the set.
            [localRecordsToDelete addObject:curNotif.serverId];
        }

        // Load all contacts - requests for adding to contact lists for existing contacts are ignored.
        NSArray * contacts = [PEXDbContact getListForAccount:cr accountId:self.params.dbId];
        NSMutableSet * contactNames = [NSMutableSet set];
        for (PEXDbContact * contact in contacts){
            [contactNames addObject:contact.sip];
        }

        // Process remote notifications.
        NSMutableArray * newRecordsToInsert = [NSMutableArray array];
        for(hr_pairingRequestElement * elem in self.state.fetchResponse.requestList.elements){
            // For now we are only interested in NONE elements, thus not resolved, waiting for action.
            // Thus even if element with this server ID exists in local database it gets deleted -> desired action.
            if (elem.resolution != hr_pairingRequestResolutionEnum_none){
                continue;
            }

            // Test if is not already in our contact list, if YES, ignore request.
            if ([contactNames containsObject:elem.fromUser]){
                continue;
            }

            // Present in server request, keep it in the local database.
            [localRecordsToDelete removeObject:elem.id_];

            // Insert or update?
            if (localRecords[elem.id_] == nil){
                // Insert a new element.
                PEXDbContactNotification * newNotif = [[PEXDbContactNotification alloc] init];
                newNotif.serverId = elem.id_;
                newNotif.date = [PEXUtils dateFromMillis: (uint64_t) [elem.tstamp longLongValue]];
                newNotif.username = elem.fromUser;
                newNotif.type = @(elem.resolution);
                newNotif.seen = @(0);
                [newRecordsToInsert addObject:newNotif];
                continue;
            }

            // Update existing notification, if there is a reason.
            BOOL updated = NO;
            PEXDbContactNotification * notif = localRecords[elem.id_];
            NSDate * recDate = [PEXUtils dateFromMillis: (uint64_t) [elem.tstamp longLongValue]];
            if ([notif.date compare:recDate] == NSOrderedAscending){
                notif.date = recDate;
                updated = YES;
            }

            // Should not ever happen, only in case user got renamed.
            if (![notif.username isEqualToString:elem.fromUser]){
                notif.username = elem.fromUser;
                updated = YES;
            }

            if (updated){
                notif.seen = @(0);
                [localRecordsUpdated addObject:notif.serverId];
            }
        }

        // Reflect changes to the database.
        // 1. Remove existing requests.
        if ([localRecordsToDelete count] > 0){
            NSString * where = [NSString stringWithFormat:@"WHERE %@ IN (%@)",
                            PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID,
                            [PEXUtils generateDbPlaceholders:(int)[localRecordsToDelete count]]];

            NSMutableArray * ids = [NSMutableArray array];
            for (NSNumber * serverId in localRecordsToDelete){
                [ids addObject: [serverId stringValue]];
            }

            [cr delete:[PEXDbContactNotification getURI] selection:where selectionArgs:ids];
        }

        // 2. Bulk insert of a new requests.
        if ([newRecordsToInsert count] > 0){
            NSMutableArray * cvs = [NSMutableArray array];
            for (PEXDbContactNotification * notif in newRecordsToInsert){
                [cvs addObject: [notif getDbContentValues]];
            }

            [cr bulk:[PEXDbContactNotification getURI] insert:cvs];
        }

        // 3. Update existing, one by one.
        if ([localRecordsUpdated count] > 0){
            for (NSNumber * serverId in localRecordsUpdated){
                PEXDbContactNotification * notif = localRecords[serverId];

                [cr update:[PEXDbContactNotification getURI] ContentValues:[notif getDbContentValues]
                      selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID]
                  selectionArgs:@[[serverId stringValue]]];
            }
        }
    } @catch(NSException * e){
        DDLogError(@"Exception during processing pairing request list, exception: %@", e);
        //toThrow = e;
        [self subCancel];
        @throw e;
    }
}
@end

@implementation PEXPairingFetchTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"PairingFetch";

        // Initialize empty state
        [self setState: [[PEXPairingFetchTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PPAIR_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXPairingFetchSOAPTask          alloc] initWithDel:self andName:@"FetchPair"]     id:PPAIR_FETCH_PAIRING];
    [self setSubTask:[[PEXPairingFetchProcessTask       alloc] initWithDel:self andName:@"ProcessPair"]   id:PPAIR_PROCESS_PAIRING];

    // Add dependencies to the tasks.
    [self.tasks[PPAIR_PROCESS_PAIRING]    addDependency:self.tasks[PPAIR_FETCH_PAIRING]];

    // Mark last task so we know what to wait for.
    [self.tasks[PPAIR_PROCESS_PAIRING] setIsLast:YES];
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
