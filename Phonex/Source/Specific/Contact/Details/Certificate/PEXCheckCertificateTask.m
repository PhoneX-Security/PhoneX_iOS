//
// Created by Matej Oravec on 23/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCheckCertificateTask.h"
#import "PEXDbContact.h"
#import "PEXTask_Protected.h"
#import "PEXUtils.h"
#import "PEXCertificateUpdateWorker.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXCertCheckListEntry.h"
#import "PEXCanceller.h"
#import "PEXCertRefreshParams.h"
#import "PEXSipUri.h"

@interface PEXCheckCertificateTask() {}
@property (nonatomic) BOOL requestSuccess;
@end

@implementation PEXCheckCertificateTask {

}

/**
* Has to be overriden, if perform is called using GCD,
* NSOperationQueue refuses to start a new thread if
* perform is waiting, on some devices.
*/
- (void) start
{
    [self startedProtected];
    [self perform];

    // TODO polish overriding
    //_ended = true;
    [self endedProtected];
}

- (void) perform
{
    if (self.contact == nil){
        DDLogWarn(@"User contact is nil, cannot refresh certificate");
        return;
    }

    self.requestSuccess = NO;
    @try {
        PEXCertRefreshParams * par = [PEXCertRefreshParams paramsWithUser:self.contact.sip forceRecheck:YES];
        PEXCertCheckListEntry * ent = [[PEXCertCheckListEntry alloc] init];
        ent.byPushNotification = NO;
        ent.urgent = YES;
        ent.policyCheck = NO;
        ent.cancelledFlag = NO;
        ent.usr = self.contact.sip;
        ent.params = par;
        NSString * usrDomain = [PEXSipUri getDomainFromSip:self.contact.sip parsed:NULL];

        PEXCertificateUpdateManager * mgr = [PEXCertificateUpdateManager instance];
        PEXCertificateUpdateWorker * worker = [[PEXCertificateUpdateWorker alloc] init];
        worker.domain = usrDomain;
        worker.privData = [[PEXAppState instance] getPrivateData];
        worker.mgr = mgr;
        worker.canceller = self.canceller;
        worker.queue = [NSMutableArray arrayWithArray:@[ent]];

        // Do the job, blocking call.
        // On fail this call will return processed entries back to the manager's queue.
        DDLogVerbose(@"Going to update certificates for domain: %@, user: %@", usrDomain, self.contact.sip);
        [worker processRequestQueue];
        if (worker.requestFailed){
            DDLogWarn(@"Certificate request refresh failed.");
        } else {
            self.requestSuccess = YES;
            DDLogVerbose(@"Certificate request finished for user: %@", self.contact.sip);
        }

    } @catch(NSException * e){
        DDLogError(@"Exception in refreshing certificate. Exception=%@", e);
    }
}

@end