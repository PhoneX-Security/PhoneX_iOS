//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertificateUpdateTask.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXConcurrentHashMap.h"
#import "PEXCertRefreshParams.h"
#import "PEXCertCheckListEntry.h"
#import "PEXCertUpdateProgress.h"
#import "PEXDbUserCertificate.h"
#import "PEXDBUserProfile.h"
#import "PEXUserPrivate.h"
#import "PEXCertRefreshTask.h"
#import "PEXUtils.h"
#import "PEXCanceller.h"
#import "hr.h"
#import "PEXCertRefreshTaskState.h"
#import "PEXDbAppContentProvider.h"
#import "PEXCertificateUpdateWorker.h"
#import "PEXService.h"

#define CERT_CHECK_SIMUL 15
#define MAX_WAIT_LOOPS 5

@interface PEXCertificateUpdateTask () {}
@property(nonatomic) BOOL showNotifications;
@property(nonatomic) BOOL volatile manualCancel;
@end

@implementation PEXCertificateUpdateTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.showNotifications = NO;
        self.manualCancel = NO;
        self.acceptingNewJobs = YES;
    }

    return self;
}

/**
* Cancels ongoing task.
* @param manualCancel the manualCancel to set
*/
-(void) doManualCancel: (BOOL) manualCancel {
    self.manualCancel = YES;
    if (self.manualCancel && self.showNotifications){
        // TODO: cancel notifications.
        //s.getNotificationManager().cancelCertUpd();
    }
}

-(BOOL) wasCancelled {
    return self.manualCancel || (self.canceller != nil && [self.canceller isCancelled]);
}

-(void)setCanAcceptNewJobs:(BOOL)acceptingNewJobs {
    self.acceptingNewJobs = acceptingNewJobs;
}

/**
* Groups requests by domain name.
*/
+(NSMutableDictionary *) groupByDomain: (NSArray *) chunks existingDict: (NSMutableDictionary *) existingDict{
    NSMutableDictionary * dict = existingDict != nil ? existingDict : [[NSMutableDictionary alloc] init];
    if (chunks == nil || [chunks count] == 0){
        return dict;
    }

    for(PEXCertCheckListEntry * e in chunks){
        if (e == nil || e.usr == nil || [PEXUtils isEmpty:e.usr]){
            continue;
        }

        NSString * domain = [PEXSipUri getDomainFromSip:e.usr parsed:nil];

        // Create key if does not exist.
        NSMutableArray * arr = dict[domain];
        if (arr == nil){
            arr = [[NSMutableArray alloc] init];
            dict[domain] = arr;
        }

        [arr addObject:e];
    }

    return dict;
}

/**
* Main entry point for this task.
*/
-(void) main {
    [self setCanAcceptNewJobs:YES];
    @try {
        [self runInternal];
    } @catch(NSException * e){
        DDLogError(@"Exception in certificate refresh. Exception=%@", e);
    }

    // Finished, finalize all internal statuses.
    [self setCanAcceptNewJobs:NO]; // Fail safe, should be already NO.
    [self.mgr resetState];
    [self.mgr bcastState];

    // Cancel Android notification.
    if (self.showNotifications){
        //s.getNotificationManager().cancelCertUpd();
    }
}

-(void) runInternal {
    //tv = SSLSOAP.getDefaultTrustManager(ctxt);
    self.manualCancel = NO;

    PEXUserPrivate * privData = self.privData;
    if (privData == nil){
        DDLogError(@"Priv data is null!");
        return;
    }

    // Display notification to the status bar
    if (self.showNotifications){
        // TODO: implement notifications.
//        final StatusbarNotifications notificationManager = s.getNotificationManager();
//        synchronized(notificationManager){
//            notificationManager.notifyCertificateUpdate();
//        }
    }

    // Reset existing progress information.
    [self.mgr resetState];
    PEXService * svc = [PEXService instance];

    // Group requests by domains.
    NSMutableDictionary * domainRequests = [[NSMutableDictionary alloc] init];
    int totalProcessed = 0;
    int totalProcessedSize = 0;

    // Do while there are still some user names in certCheckList
    // certCheckList is a concurrent structure.
    while(![self.certCheckList isEmpty] && ![self wasCancelled] && [svc isConnectivityWorking]){
        // Small time window here, since discovery the queue is not empty we wait
        // a few milliseconds, if requests are send one by one we may catch more in
        // one batch.

        int toProcess = 0;
        int waitLoops = 0;
        for(; waitLoops < MAX_WAIT_LOOPS && toProcess <= CERT_CHECK_SIMUL && [svc isConnectivityWorking]; waitLoops++){
            // Do not accept new jobs in the last stage, has to wait for next one.
            if ((waitLoops + 1) == MAX_WAIT_LOOPS){
                [self setCanAcceptNewJobs:NO];
            }

            // Get given amount of jobs from job queue.
            NSArray * curProcChunk = [self.certCheckList pollN: (CERT_CHECK_SIMUL - toProcess)];
            const int curToProcess = [curProcChunk count];

            // Group requests w.r.t. domains to dictionary.
            [PEXCertificateUpdateTask groupByDomain:curProcChunk existingDict:domainRequests];

            // Add fragment gathered in this loop to the accumulator array.
            toProcess += curToProcess;

            // Accepting new jobs?
            if ((waitLoops + 1) == MAX_WAIT_LOOPS || toProcess > CERT_CHECK_SIMUL){
                [self setCanAcceptNewJobs:NO];
            } else {
                // Pause CPU for a while, let new request to come.
                [NSThread sleepForTimeInterval:0.1];
            }
        }

        totalProcessed += toProcess;
        totalProcessedSize = [domainRequests count];
        if (toProcess == 0){
            continue;
        }

        // Process X certificates simultaneously. By default process 15 certificates.
        DDLogVerbose(@"CertSync: started, toProcess=%d", toProcess);

        // Here multiple workers can be spawned to process requests.
        // Currently we have only one worker, domains are processed in a serial way.
        for(NSString * curDomain in domainRequests){
            PEXCertificateUpdateWorker * worker = [[PEXCertificateUpdateWorker alloc] init];
            worker.domain = curDomain;
            worker.privData = self.privData;
            worker.mgr = self.mgr;
            worker.canceller = self.canceller;
            worker.queue = domainRequests[curDomain];

            // Do the job, blocking call.
            // On fail this call will return processed entries back to the manager's queue.
            DDLogVerbose(@"Going to update certificates for domain: %@, batchsize=%lu", curDomain, (unsigned long)[worker.queue count]);
            [worker processRequestQueue];
            if (worker.requestFailed){
                [_mgr failCountInc];
            }
        }

        [domainRequests removeAllObjects];
    } // End of while(certQueue==empty)

    [self setCanAcceptNewJobs:NO];
    DDLogVerbose(@"Certificate update task finished. ToProcess=%d, SizeProcessed=%d", totalProcessed, totalProcessedSize);
}


@end