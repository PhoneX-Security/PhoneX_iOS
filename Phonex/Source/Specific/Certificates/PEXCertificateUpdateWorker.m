//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertificateUpdateWorker.h"
#import "PEXCanceller.h"
#import "PEXCertCheckListEntry.h"
#import "PEXCertRefreshParams.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbContact.h"
#import "PEXUserPrivate.h"
#import "PEXCertificateUpdateManagerProtocol.h"
#import "PEXCertRefreshTask.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXUtils.h"
#import "PEXCertUpdateProgress.h"
#import "hr.h"
#import "PEXCertRefreshTaskState.h"
#import "PEXCertUtils.h"
#import "PEXPhonexSettings.h"
#import "PEXStringUtils.h"
#import "PEXService.h"

#define PEX_CERT_CHECK_FAIL_COUNT_LIMIT 64

@interface PEXCertificateUpdateWorker () {}
@property(nonatomic) NSMutableDictionary * usrMap; // Map<String, CertCheckListEntry>
@property(nonatomic) NSMutableDictionary * certsMap; // Map<String, UserCertificate>
@property(nonatomic) NSMutableDictionary * dbusersMap; // Map<String, SipClist>
@property(nonatomic) NSMutableDictionary * certificateHashes; // Map<String, String>
@property(nonatomic) NSMutableSet * checkSkip; // Set<String>

@property(nonatomic) BOOL showNotifications;
@property(nonatomic) BOOL volatile manualCancel;
@property(nonatomic) BOOL requestFailed;

@end

@implementation PEXCertificateUpdateWorker { }

- (instancetype)init {
    self = [super init];
    if (self) {
        _showNotifications = NO;
        _manualCancel = NO;
        _requestFailed = NO;
    }

    return self;
}


-(BOOL) wasCancelled {
    return self.manualCancel || (self.canceller != nil && [self.canceller isCancelled]);
}

/**
* Generates list of users that should be skipped (to avoid DoS, too often checks)
* from the internal state.
*/
-(void) generateSkipList{
    //
    // Check certificate for a given users.
    // Build ignore list of the users to skip certificate check.
    //
    NSDictionary * usrMapCopy = [self.usrMap copy];
    for(NSString * sip in usrMapCopy){
        PEXCertCheckListEntry * ve = usrMapCopy[sip];

        // Cancelled?
        if ([ve wasCancelled]){
            DDLogVerbose(@"User cancelled: %@", sip);
            [self.checkSkip addObject:sip];
            continue;
        }

        if (self.certsMap[sip] == nil) continue;
        if (self.dbusersMap[sip] == nil) continue;

        // Load certificate and verify its correctness.
        PEXDbUserCertificate * crt = self.certsMap[sip];
        if ([@(CERTIFICATE_STATUS_OK) isEqualToNumber:crt.certificateStatus]){
            // If certificate is marked as OK but it not, do check it!
            if (![crt isValidCertObj]) continue;

            // Cert is valid, store cert hash and validate stored certificate with its hash.
            if (ve.params == nil || ve.params.useCertHash) {
                self.certificateHashes[sip] = crt.certificateHash;
            }
        }

        // Cert hash is computed even for the force checked entries so we don't need to process raw certificate
        // data as they come. If the cert is invalid, server will detect it from the certhash.
        if (!ve.policyCheck) continue;
        if (ve.params != nil && ve.params.forceRecheck) continue;

        // Mark this update as caused by push notification. (For alter updating last update time w.r.t. push).
        ve.byPushNotification = ve.params != nil && ve.params.pushNotification;

        // If is from push, check anti-DoS policy.
        PEXDbContact * cl = self.dbusersMap[sip];
        if (ve.params!=nil && ve.params.pushNotification && cl.presenceLastCertUpdate != nil){
            NSDate * lPresUpd = cl.presenceLastCertUpdate;
            NSNumber * numUpd = cl.presenceNumCertUpdate;

            // Too early certificate update ?
            NSDate * boundary = [NSDate dateWithTimeInterval:-CERTIFICATE_PUSH_TIMEOUT sinceDate:[NSDate date]];
            if ([boundary compare:lPresUpd] == NSOrderedAscending){
                DDLogDebug(@"Too early certificate push update for user [%@], last: %@", sip, lPresUpd);

                [self.checkSkip addObject:sip];
                continue;
            }

            // Too many times certificate update was performed during this day?
            if (numUpd!=nil && [PEXUtils isToday:lPresUpd] && [@(CERTIFICATE_PUSH_MAX_UPDATES) compare:numUpd] == NSOrderedAscending){
                DDLogDebug(@"Too often certificate push update for user [%@], last: %@ num: %@", sip, lPresUpd, numUpd);

                [self.checkSkip addObject:sip];
                continue;
            }

            // Do certificate update only if current cert differs.
            // If cert is OK and push matches, nothing to do.
            if (![@(CERTIFICATE_STATUS_OK) isEqualToNumber:crt.certificateStatus]) continue;
            NSString * certHash = ve.params.existingCertHash2recheck;

            // CertHash is not empty && matches -> skip
            if (![PEXUtils isEmpty:certHash]){
                if ([crt.certificateHash hasPrefix:certHash]){
                    [self.checkSkip addObject:sip];
                    continue;
                } else {
                    DDLogDebug(@"Cert has does not match for user [%@]", sip);
                    continue;
                }
            }
        } // End of if pushNotification valid

        // Check last query policy - if current check is too early from previous one, skip it.
        BOOL recheck = [PEXCertUtils recheckCertificateForUser:crt];
        if (recheck==false){
            DDLogDebug(@"No need to re-check for user %@", sip);

            [self.checkSkip addObject:sip];
            continue;
        }

        // If current policy disables becameOnlineCheck, skip it.
        if (![PEXPhonexSettings checkCertificateOnBecomeOnlineEvent] && ve.params != nil && ve.params.becameOnlineCheck){
            DDLogDebug(@"Became online check disabled. acc=%@", sip);

            [self.checkSkip addObject:sip];
            continue;
        }
    } // End of foreach(), skipCheck init.
}

/**
* Builds get certificate request from internal state.
* @return
*/
-(hr_getCertificateRequest *) buildRequest{ //GetCertificateRequest
    hr_getCertificateRequest * certReq = [[hr_getCertificateRequest alloc] init];

    for(NSString * sip in self.usrMap){
        PEXCertCheckListEntry * ev = self.usrMap[sip];
        if ([self.checkSkip containsObject:sip] || [ev wasCancelled]){
            // Certificate wont be updated.
            [self.mgr updateState:sip state:PEX_CERT_UPDATE_STATE_DONE];
            continue;
        }

        hr_certificateRequestElement * cre = [[hr_certificateRequestElement alloc] init];
        cre.user = [sip copy];

        // Do we have certificate hash to verify against?
        NSString * certHash = self.certificateHashes[sip];
        if (![PEXUtils isEmpty:certHash]){
            cre.certificateHash = [certHash copy];
            DDLogVerbose(@"SIP: %@; found among stored hashes", sip);
        }

        [self.mgr updateState:sip state:PEX_CERT_UPDATE_STATE_SERVER_CALL];
        [certReq addElement:cre];
    }

    return certReq;
}

/**
* We are given two check entries, new and previous. From these 2 a final one is created and added to the queue.
* Resulting entry tries to maximize probability of detecting old certificate on the remote side.
*/
-(PEXCertCheckListEntry *) mergeEntries: (PEXCertCheckListEntry *) new previous: (PEXCertCheckListEntry *) previous{
    if (previous == nil){
        return new;
    }

    // Cancel only if both are.
    new.cancelledFlag &= previous.cancelledFlag;
    // One urgent is enough.
    new.urgent |= previous.urgent;
    // If one is set to skip policy check, ignore it.
    new.policyCheck &= previous.policyCheck;
    // If there is some push information in new one, will be added.
    new.byPushNotification |= previous.byPushNotification;
    // Minimize fail count of the requests - makes sense, do not reset to zero, preserve lowest/newest entry.
    new.failCount = MIN(new.failCount, previous.failCount);

    // Parameters update.
    new.params.loadCertificateToResult |= previous.params.loadCertificateToResult;
    new.params.allowDhKeyRefreshOnCertChange |= previous.params.allowDhKeyRefreshOnCertChange;
    new.params.loadNewCertificateAfterInsert |= previous.params.loadNewCertificateAfterInsert;
    new.params.forceRecheck |= previous.params.forceRecheck;
    new.params.pushNotification |= previous.params.pushNotification;
    new.params.becameOnlineCheck |= previous.params.becameOnlineCheck;

    // Get some cert recheck.
    if ([PEXStringUtils isEmpty: new.params.existingCertHash2recheck]){
        new.params.existingCertHash2recheck = previous.params.existingCertHash2recheck;
    }

    // If date is nil, take one from push notification, or take the newer.
    if (new.params.notBefore == nil){
        new.params.notBefore = previous.params.notBefore;
    } else if (previous.params.notBefore != nil && [new.params.notBefore compare:previous.params.notBefore] == NSOrderedAscending){
        new.params.notBefore = previous.params.notBefore;
    }

    return new;
}

/**
* Returns cert check entries back to queue so the cert request is not lost due to a recoverable error (e.g., connection drop).
* usrMap is used as data source since it contains already processed (merged) entries. Some work was done so recycle it.
*/
-(void) returnToQueueOnFail {
    if (_usrMap == nil || [_usrMap count] == 0 || _mgr == nil){
        return;
    }

    PEXService * svc = [PEXService instance];
    BOOL connWorks = [svc isConnectivityAndServiceWorking];

    NSArray * values = [_usrMap allValues];
    NSMutableArray * valuesToAdd = [[NSMutableArray alloc] init];
    NSMutableArray * usersInQueue = [[NSMutableArray alloc] init];
    NSMutableArray * usersExpired = [[NSMutableArray alloc] init];

    for (PEXCertCheckListEntry * e in values){
        // Check failcount, do not add to infinity.
        // Failcount is increased only if connectivity is working (error happened not due to faulty entry).
        e.failCount += connWorks ? 1 : 0;
        if (e.failCount > PEX_CERT_CHECK_FAIL_COUNT_LIMIT){
            [usersExpired addObject:e.usr];

            DDLogDebug(@"Entry dropped from return, reached max fail count, %@", e);
            continue;
        } else {
            [usersInQueue addObject:e.usr];
        }

        [valuesToAdd addObject:e];
    }

    // Batch state update - better for broadcasting.
    if ([usersInQueue count] > 0) {
        [self.mgr updateStateBatch:usersInQueue state:PEX_CERT_UPDATE_STATE_IN_QUEUE];
    }

    // Batch state update - better for broadcasting.
    if ([usersExpired count] > 0) {
        [self.mgr updateStateBatch:usersExpired state:PEX_CERT_UPDATE_STATE_DONE];
    }

    // Return certificate refresh entries back to the queue.
    [_mgr addToCertCheckList:[NSArray arrayWithArray:valuesToAdd] async:YES];
    DDLogVerbose(@"Cert check entries returned to queue due to error: %lu", (unsigned long)[valuesToAdd count]);
}

/**
* Process internal queue.
*/
-(void) processRequestQueue {
    // Reset current state.
    const NSUInteger toProcess = [self.queue count];

    NSMutableArray * users = [NSMutableArray arrayWithCapacity:toProcess];
    self.usrMap = [NSMutableDictionary dictionaryWithCapacity:toProcess];
    self.certsMap = [NSMutableDictionary dictionaryWithCapacity:toProcess];
    self.dbusersMap = [NSMutableDictionary dictionaryWithCapacity:toProcess];
    self.certificateHashes = [NSMutableDictionary dictionaryWithCapacity:toProcess];
    self.checkSkip = [NSMutableSet setWithCapacity:toProcess];

    // Take toProcess number of users from waiting list to the separate list.
    NSMutableSet * usrSet = [[NSMutableSet alloc] init];
    for(PEXCertCheckListEntry * e in self.queue){
        // User merging - there may be multiple previous users here.
        self.usrMap[e.usr] = [self mergeEntries:e previous:self.usrMap[e.usr]];
        [usrSet addObject:e.usr];
    }

    [users addObjectsFromArray:[usrSet allObjects]];

    // Batch state update - better for broadcasting.
    [self.mgr updateStateBatch:users state:PEX_CERT_UPDATE_STATE_STARTED];

    // Load stored certificates for given users.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    NSDictionary * certDict = [PEXDbUserCertificate loadCertificatesForUsers:users cr:cr projection:[PEXDbUserCertificate getFullProjection]];
    for(NSString * curUser in certDict){
        self.certsMap[curUser] = certDict[curUser];
    }

    // Load contact list entries for given users.
    NSArray * contactArray = [PEXDbContact newProfilesFromDbSip:cr sip:users projection:[PEXDbContact getFullProjection]];
    for(PEXDbContact * c in contactArray){
        if (c == nil){
            continue;
        }

        self.dbusersMap[c.sip] = c;
    }

    // Generate list of SIPs to skip in this, w.r.t. DoS policy.
    [self generateSkipList];

    //
    // Real certificate check for given entries.
    //
    // Get all certificates for users.
    // If certificate is already stored in database, validate it with hash only
    // to save bandwidth.
    hr_getCertificateRequest * certReq = [self buildRequest];
    [self.mgr bcastState];

    // Do not invoke SOAP call if there is nothing to check.
    if (certReq == nil || certReq.element == nil || [certReq.element count] == 0){
        return;
    }

    // Manual cancellation -> set users as done & exit.
    if ([self wasCancelled]){
        [self.mgr updateStateBatch:users state:PEX_CERT_UPDATE_STATE_DONE];
        DDLogVerbose(@"Cert update worker cancelled");
        return;
    }

    // SOAP GetCertificateRequest.
    DDLogVerbose(@"CertSync: going to call server, size=%lu", (unsigned long) [certReq.element count]);
    [self.mgr updateStateBatch:users state:PEX_CERT_UPDATE_STATE_SERVER_CALL];
    [self.mgr bcastState];

    // Certificate refresh task init.
    PEXCertRefreshTask * crtTask = [PEXCertRefreshTask taskWithPrivData:self.privData];
    crtTask.canceller = self.canceller;
    crtTask.domain = self.domain;

    // Perform SOAP request, handle error conditions.
    [crtTask soapRequest:certReq];
    if (crtTask.state == nil || crtTask.state.soapTaskFinishState == PEX_TASK_FINISHED_ERROR){
        DDLogError(@"CertRefreshSOAP finished with error: %@", crtTask.state.soapTaskError);

        // Cert refresh failed from some reason (e.g., connectivity), return back to cert check queue, increase fail count.
        // If failcount too big, do not add anymore.
        _requestFailed = YES;
        [self returnToQueueOnFail];

        return;
    } else if (crtTask.state.soapTaskFinishState == PEX_TASK_FINISHED_CANCELLED){
        DDLogInfo(@"CertRefreshSOAP was cancelled");
        return;
    }

    hr_getCertificateResponse * respc = crtTask.state.certResponse;
    if (respc == nil || respc.return_ == nil || [respc.return_ count] == 0){
        DDLogInfo(@"SOAP response is null or invalid.");
        return;
    }

    // Real certificate update. If yes, trigger DH Key update later.
    BOOL newCert = NO;

    // Processing SOAP response one-by-one.
    // Iterate over returned array of certificate wrappers.
    NSMutableArray * updatedUsers = [[NSMutableArray alloc] initWithCapacity:[respc.return_ count]];
    for (id wrId in respc.return_) {
        if (wrId == nil || ![wrId isKindOfClass:[hr_certificateWrapper class]]) {
            DDLogError(@"Invalid element in certificate response, certificateWrapper expected; got=%@", wrId);
            continue;
        }
        hr_certificateWrapper * wr = (hr_certificateWrapper *) wrId;

        NSString * user = wr.user;
        PEXCertCheckListEntry * ve = self.usrMap[user];
        PEXDbContact * cl = self.dbusersMap[user];
        [self.mgr updateState:user state:PEX_CERT_UPDATE_STATE_POST_SERVER_CALL];

        // If updated by push notification, update database anti-DoS statistics.
        if (ve!=nil && ve.byPushNotification){
            [PEXCertUtils updateLastCertRefresh:cl cr:cr];
            DDLogVerbose(@"Certificate for user: %@; updated push statistics.", user);
        }

        [self.mgr updateState:user state:PEX_CERT_UPDATE_STATE_SAVING];

        // Test if we provided some certificate. If yes, look on certificate status.
        // If status = OK then update database (last query), otherwise delete record
        // because the new one with provided answer will be inserted afterwards.
        if (self.certificateHashes[user] != nil){
            hr_certificateStatus providedStatus = wr.providedCertStatus;
            DDLogVerbose(@"Provided status for user: %@; status: %d", user, providedStatus);

            // invalid? Delete certificate then
            if (providedStatus == CERTIFICATE_STATUS_OK){
                [PEXDbUserCertificate updateCertificateStatus:@(CERTIFICATE_STATUS_OK) owner:user cr:cr];
                DDLogDebug(@"Certificate for user: %@; updated in database (query time also)", user);

                // We don't have to continue, certificate is valid -> move to next user.
                [self.mgr updateState:user state:PEX_CERT_UPDATE_STATE_DONE];
                [self.mgr bcastState];
                continue;
            } else {
                // something is wrong with stored certificate,
                // deleting from certificate database.
                int deleteResult = [PEXDbUserCertificate deleteCertificateForUser:user cr:cr error:nil];
                DDLogInfo(@"Certificate for user [%@] removed; int: %d", user, deleteResult);

                newCert=true;
                [updatedUsers addObject:user];
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
                [self.mgr updateState:user state:PEX_CERT_UPDATE_STATE_DONE];
                [self.mgr bcastState];
                continue;
            } else { // In memory update.
                newCert=true;
                [updatedUsers addObject:user];
            }

            // Store result of this query to DB. Can also have error code - usable not to query for
            // certificate too often.
            [PEXDbUserCertificate insertUnique:user cr:cr cv:crt2db.getDbContentValues];
        } @catch (NSException * e) {
            DDLogError(@"Exception in certificate update: %@", e);
        }

        [self.mgr updateState:user state:PEX_CERT_UPDATE_STATE_DONE];
        [self.mgr bcastState];
    } // End of foreach(SoapGetCertResponse)

    // If new certificate was provided, notify others.
    if (newCert){
        [self.mgr certificatesUpdated:updatedUsers];
    }

    DDLogVerbose(@"Cert update task finished");
}

@end