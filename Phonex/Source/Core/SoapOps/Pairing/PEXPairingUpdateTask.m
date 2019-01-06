//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPairingUpdateTask.h"
#import "PEXPairingUpdateParams.h"
#import "hr.h"
#import "PEXPairingUpdateTask.h"
#import "PEXCListFetchParams.h"
#import "hr.h"
#import "PEXPairingUpdateParams.h"
#import "PEXSOAPTask.h"
#import "PEXTask_Protected.h"
#import "PEXDbContactNotification.h"
#import "PEXUtils.h"
#import "PEXDbContact.h"

@interface PEXPairingUpdateTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSError * lastError;
@property(atomic) hr_pairingRequestUpdateResponse *updateResponse;
@end

@implementation PEXPairingUpdateTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.lastError = nil;
        self.updateResponse = nil;
    }

    return self;
}

@end

// Private part of the PEXPairingUpdateTask
@interface PEXPairingUpdateTask ()  { }
@property(atomic) PEXPairingUpdateTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXPairingUpdateSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXPairingUpdateTaskState * state;
@property (nonatomic, weak) PEXPairingUpdateParams * params;
@property (nonatomic, weak) PEXPairingUpdateTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXPairingUpdateTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXPairingUpdateSubtask {}
- (id) initWithDel:(PEXPairingUpdateTask *)delegate andName: (NSString *) taskName {
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
@interface PEXPairingUpdateSOAPTask : PEXPairingUpdateSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXPairingUpdateProcessTask : PEXPairingUpdateSubtask { }
@end

//
// Implementation part
//
@implementation PEXPairingUpdateSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.pairingupdate.soap"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Construct request.
    hr_pairingRequestUpdateRequest *request = [[hr_pairingRequestUpdateRequest alloc] init];
    hr_pairingRequestUpdateList * updList = [[hr_pairingRequestUpdateList alloc] init];
    request.updateList = updList;
    [updList.updates addObjectsFromArray:self.params.requestChanges];
    DDLogVerbose(@"Request constructed %@, for user=%@", request, self.privData.username);

    // Prepare SOAP operation.
    __weak __typeof(self) weakSelf = self;
    self.soapTask.desiredBody = [hr_pairingRequestUpdateResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_pairingRequestUpdate alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask pairingRequestUpdateRequest:request];

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
    hr_pairingRequestUpdateResponse *body = (hr_pairingRequestUpdateResponse *) self.soapTask.responseBody;
    if (body.errCode == nil || [body.errCode integerValue] != 0){
        DDLogError(@"Pairing request update went wrong, error code: %@", body.errCode);
    }

    self.state.updateResponse = body;
}
@end

@implementation PEXPairingUpdateProcessTask
- (void)subMain {
    self.ownDelegate.response = self.state.updateResponse;
}
@end

@implementation PEXPairingUpdateTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"PairingUpdate";

        // Initialize empty state
        [self setState: [[PEXPairingUpdateTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PUPAIR_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXPairingUpdateSOAPTask          alloc] initWithDel:self andName:@"UpdatePair"]  id:PUPAIR_UPDATE];
    [self setSubTask:[[PEXPairingUpdateProcessTask       alloc] initWithDel:self andName:@"ProcessPair"] id:PUPAIR_PROCESS];

    // Add dependencies to the tasks.
    [self.tasks[PUPAIR_PROCESS]    addDependency:self.tasks[PUPAIR_UPDATE]];

    // Mark last task so we know what to wait for.
    [self.tasks[PUPAIR_PROCESS] setIsLast:YES];
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
