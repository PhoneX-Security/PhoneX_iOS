//
// Created by Dusan Klinec on 08.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXSingleLoginWatcher.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXService.h"
#import "PEXStringUtils.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"
#import "PEXPushNewCertEvent.h"

#import "PEXGuiMainNavigationController.h"
#import "PEXGuiLoginController.h"
#import "PEXPushNewCertEvent.h"
#import "PEXCertRefreshParams.h"
#import "PEXCertRefreshTask.h"
#import "PEXCertRefreshTaskState.h"
#import "PEXConnectivityChange.h"
#import "PEXUtils.h"

NSString * PEX_ACTION_CHECK_SINGLE_LOGIN = @"net.phonex.singlelogin.action.check";
NSString * PEX_EXTRA_CHECK_SINGLE_LOGIN = @"net.phonex.singlelogin.obj";

@interface PEXSingleLoginWatcher () {}
@property(nonatomic) BOOL registered;

/**
* Event stored for later processing when connectivity comes on.
* If event was in processing and connectivity was interrupted, we would lose this push message
* since push module marks this event as already delivered and does not take care anymore. Thus
* we need to re-check it after connectivity comes up.
*/
@property(nonatomic) PEXPushNewCertEvent * deferredEvent;
@end

@implementation PEXSingleLoginWatcher {}
- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // Register on certificate updates.
        [center addObserver:self selector:@selector(onCheckTrigger:) name:PEX_ACTION_CHECK_SINGLE_LOGIN object:nil];
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
        self.registered = YES;
    }
}

- (void)dealloc {
    if (self.registered) {
        [self doUnregister];
    }
}

- (void)doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];
        self.registered = NO;
    }
}

/**
* Called when certificate differs. Leads to user logout.
*/
-(void) triggerCertificateDifferent: (NSString *) user dbCrt:(PEXDbUserCertificate *) dbCrt {
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO: logout + show appropriate warning. dbCrt can be used to show WHEN was new certificate created.

        [[PEXGuiLoginController instance] performLogoutWithMessage:PEXStr(@"txt_logout_due_another_login")];

        DDLogInfo(@"About to logout due to duplicate login.");
    });
}

/**
* Certificate check event passed through basic checks, now its time to determine if this event can possibly indicate
* our primary certificate has been changed.
*/
- (void)checkCertEvent:(PEXPushNewCertEvent *)event {
    PEXUserPrivate * privData = [PEXService instance].privData;
    @try {
        // Get current certificate.
        PEXX509 *myCert = privData.cert;
        if (myCert == nil || !myCert.isAllocated){
            DDLogError(@"Current certificate is nil!");
            return;
        }

        // Get current cert date - if notification is older, ignore it.
        NSDate   * notBeforeDate = [PEXCryptoUtils getNotBefore:myCert.getRaw];
        int64_t notBefore        = (int64_t) ceil([notBeforeDate timeIntervalSince1970] * 1000.0);

        // Check according to the request.
        if (event.notBefore < notBefore){
            DDLogVerbose(@"Notification certificate is older than ours, ignoring.");
            return;
        }

        // Current certificate hash - will be checked with SOAP call for validity.
        NSString * localHash = [PEXMessageDigest getCertificateDigestWrap:myCert];
        if (event.notBefore == notBefore && [PEXStringUtils startsWith:localHash prefix:event.certHashPrefix]){
            DDLogVerbose(@"Notification gives our own certificate, ignoring.");
            return;
        }

        // Re-use re-check certificate code
        PEXCertRefreshParams * refreshParam = [PEXCertRefreshParams paramsWithUser:privData.username forceRecheck:YES existingCertHash2recheck:localHash];
        PEXCertRefreshTask * refreshTask = [[PEXCertRefreshTask alloc] initWithPrivData:privData params:refreshParam];
        [refreshTask doRequest];
        PEXCertRefreshTaskState * tState = refreshTask.state;

        // Precise response checking.
        if (tState == nil
                || tState.soapTaskFinishState != PEX_TASK_FINISHED_OK
                || tState.certResponse == nil
                || tState.certResponse.return_ == nil
                || [tState.certResponse.return_ count] == 0){
            DDLogVerbose(@"SOAP task failed somehow, cannot continue with processing");
            _deferredEvent = event;
            return;
        }

        @try {
            // Check for provided answer.
            hr_certificateWrapper * wr = (hr_certificateWrapper *) tState.certResponse.return_[0];

            // Reset deferred event so we don't check still the same thing.
            _deferredEvent = nil;

            // If stored certificate with given hash is not valid, logout.
            if (wr.providedCertStatus != hr_certificateStatus_ok){
                DDLogInfo(@"Provided certificate status is not OK!");
                [self triggerCertificateDifferent:privData.username dbCrt:nil];
            }

        } @catch(NSException * e){
            DDLogError(@"Exception in processing cert refresh answer, exception=%@", e);
            return;
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in certificate check. exception=%@", e);
    }
}

/**
* Certificate check event trigger - by certCheck push notification indicating there might be a new certificate for this account
* registered invalidating the one currently used.
* Extracts information from notification and starts cert check in master serial queue.
*/
- (void)onCheckTrigger:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_CHECK_SINGLE_LOGIN] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushNewCertEvent * evt = notification.userInfo[PEX_EXTRA_CHECK_SINGLE_LOGIN];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Certificate check, mine (local) vs. database (new, updated).
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"checkCert" async:YES block:^{
        [weakSelf checkCertEvent:evt];
    }];
}

/**
* Receive connectivity changes so we can react on this - process deferred cert check request which failed due to connection error.
*/
- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil || conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    // IP changed?
    BOOL recovered = conChange.connection == PEX_CONN_GOES_UP;
    if (!recovered){
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"connChange" async:YES block:^{
        PEXSingleLoginWatcher * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (recovered && mgr.deferredEvent != nil) {
            DDLogVerbose(@"Connectivity recovered, try deferred record.");
            [mgr checkCertEvent:_deferredEvent];
        }
    }];
}

@end