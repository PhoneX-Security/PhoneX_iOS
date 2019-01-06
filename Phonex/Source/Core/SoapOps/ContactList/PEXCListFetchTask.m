//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCListFetchTask.h"
#import "PEXCertGenParams.h"
#import "PEXUserPrivate.h"
#import "hr.h"
#import "PEXCListFetchParams.h"
#import "PhoenixPortServiceSvc.h"
#import "PEXSecurityCenter.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXSOAPManager.h"
#import "PEXSOAPTask.h"
#import "PEXDbContentValues.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDatabase.h"
#import "PEXUser.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"
#import "PEXDbContact.h"
#import "PEXUtils.h"
#import "PEXTaskFinishedEvent.h"
#import "PEXTask_Protected.h"
#import "PEXStringUtils.h"
#import "PEXPbPush.pb.h"
#import "PEXPresenceCenter.h"

// TODO: differentiate with user name.
NSString * PEX_CLIST_FETCH_LAST_FINISH_TSTAMP = @"net.phonex.clistfetch.lasttime";

@interface PEXClistFetchTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic, readwrite) NSDate * lastFetchTime;
@property(atomic) NSError * lastError;
@property(atomic) hr_contactlistGetResponse *clistFetchResponse;
@property(nonatomic) hr_getCertificateResponse *certResponse;

@property(nonatomic) NSMutableDictionary * contacts;
@property(nonatomic) NSMutableDictionary * certificateHashes;
@property(nonatomic) NSMutableDictionary * certificates;

@end

@implementation PEXClistFetchTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.lastError = nil;
        self.clistFetchResponse = nil;
    }

    return self;
}

@end

// Private part of the PEXClistFetchTask
@interface PEXCListFetchTask ()  { }
@property(atomic) PEXClistFetchTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXClistFetchSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXClistFetchTaskState * state;
@property (nonatomic, weak) PEXCListFetchParams * params;
@property (nonatomic, weak) PEXCListFetchTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXCListFetchTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXClistFetchSubtask {}
- (id) initWithDel:(PEXCListFetchTask *)delegate andName: (NSString *) taskName {
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
@interface PEXClistFetchSOAPTask : PEXClistFetchSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXClistFetchProcessTask : PEXClistFetchSubtask { }
@end

@interface PEXClistFetchCertRefreshTask : PEXClistFetchSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXClistFetchProcessCertsTask : PEXClistFetchSubtask { }
@end

@interface PEXClistFetchStoreTask : PEXClistFetchSubtask { }
@end

//
// Implementation part
//
@implementation PEXClistFetchSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clisfetch.soap"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Construct request.
    hr_contactlistGetRequest *request = [[hr_contactlistGetRequest alloc] init];
    request.targetUser = self.params.sip;
    DDLogVerbose(@"Request constructed %@, for user=%@", request, self.privData.username);

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.state.lastFetchTime = [NSDate date];
    self.soapTask.desiredBody = [hr_contactlistGetResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) {
        return [weakSelf shouldCancel];
    };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_contactlistGet alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask contactlistGetRequest:request];

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
    hr_contactlistGetResponse *body = (hr_contactlistGetResponse *) self.soapTask.responseBody;
    self.state.clistFetchResponse = body;
}
@end

@implementation PEXClistFetchProcessTask
- (void)subMain {
    self.state.contacts = [NSMutableDictionary dictionary];
    self.state.certificateHashes = [NSMutableDictionary dictionary];
    self.state.certificates = [NSMutableDictionary dictionary];

    // Load all cert hashes from cert table, corresponding to users in CL.
    // Goal: check validity of user certificates against server list.
    int i = 0;
    NSMutableString * sbSipSelect = [[NSMutableString alloc] init];
    for(hr_contactListElement * elem in self.state.clistFetchResponse.contactlistEntry){
        if (elem==nil) continue;
        DDLogVerbose(@"Contactlist element: %@", elem);
        self.state.contacts[elem.usersip] = elem;

        // create where query now
        if ((i++)!=0) {
            [sbSipSelect appendString:@","];
        }

        [sbSipSelect appendString: [PEXDatabase sqlEscapeString:elem.usersip]];
        i+=1;
    }

    // If contact list is empty, do not load certificates since there is nothing to load.
    if (i==0){
        return;
    }

    // lookup certificate database and find certificate hashes if exists
    @try {
        NSString * selection = [NSString stringWithFormat:@"WHERE %@ IN (%@) AND %@=%ld",
        PEX_UCRT_FIELD_OWNER, sbSipSelect, PEX_UCRT_FIELD_CERTIFICATE_STATUS, (long) CERTIFICATE_STATUS_OK];
        DDLogVerbose(@"Selection condition: [%@]", selection);

        NSArray * selectionArgs = [[NSArray alloc] init];
        PEXDbCursor * c = [self.params.cr query:[PEXDbUserCertificate getURI]
                                     projection:[PEXDbUserCertificate getNormalProjection]
                                      selection:selection
                                  selectionArgs:selectionArgs
                                      sortOrder:@""];

        if (c!=nil && c.getCount > 0){
            while([c moveToNext]) {
                PEXDbUserCertificate * sipCert = [PEXDbUserCertificate certificateWithCursor:c];
                if (sipCert == nil
                        || [PEXStringUtils isEmpty:sipCert.certificateHash]
                        || sipCert.certificateStatus == nil
                        || ![sipCert.certificateStatus isEqualToNumber:@(CERTIFICATE_STATUS_OK)])
                {
                    DDLogDebug(@"Certificate empty for user=%@, certInfo=%@", sipCert == nil ? @"" : sipCert.owner, sipCert);
                    continue;
                }

                self.state.certificateHashes[sipCert.owner] = sipCert.certificateHash;
                DDLogVerbose(@"Loaded certificate for: %@; Hash: %@", sipCert.owner, sipCert.certificateHash);
            }
        }
    } @catch(NSException * e){
        DDLogError(@"Exception during loading stored certificates, exception: %@", e);
        //toThrow = e;
        [self subCancel];
        @throw e;
    }
}
@end

@implementation PEXClistFetchCertRefreshTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.clisfetch.soap.cert"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    if (self.state.contacts==nil || self.state.contacts.count==0){
        DDLogVerbose(@"Empty contactlist, no certificate fetch");
        return;
    }

    // GetCertificateRequest is called here. List of users is added for which we are
    // interested in certificates.
    //
    // Get all certificates for users.
    // If certificate is already stored in database, validate it with hash only
    hr_getCertificateRequest * certRequest = [[hr_getCertificateRequest alloc] init];
    for (id sip in self.state.contacts) {
        hr_certificateRequestElement * cre = [[hr_certificateRequestElement alloc] init];
        cre.user = [sip copy];

        id certHashId = self.state.certificateHashes[sip];
        if (certHashId!=nil){
            DDLogVerbose(@"SIP: %@ found among stored hashes", sip);
            cre.certificateHash = (NSString*) certHashId;
        }

        [certRequest.element addObject:cre];
    }

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

@implementation PEXClistFetchProcessCertsTask
- (void)subMain {
    hr_getCertificateResponse *resp = self.state.certResponse;
    NSMutableDictionary * certificateHashes = self.state.certificateHashes;
    NSMutableDictionary * certificates = self.state.certificates;
    NSMutableDictionary * contacts = self.state.contacts;
    if (resp==nil
            || resp.return_==nil
            || [resp.return_ count]==0){
        // Nothing to do, empty response.
        DDLogVerbose(@"Empty certificate response, nothing to do");
        return;
    }

    // Iterate over returned array of certificate wrappers.
    for (id wrId in resp.return_) {
        if (wrId == nil || ![wrId isKindOfClass:[hr_certificateWrapper class]]) {
            DDLogError(@"Invalid element in certificate response, certificateWrapper expected; got=%@", wrId);
            continue;
        }

        hr_certificateWrapper * wr = (hr_certificateWrapper *) wrId;
        NSString * user = wr.user;

        // test if we provided some certificate. If yes, look on certificate status.
        // If status = OK then update database (last query), otherwise delete record
        // because the new one with provided answer will be inserted afterwards.
        NSString * providedHash = certificateHashes[user];
        if (providedHash!=nil){
            hr_certificateStatus providedStatus = wr.providedCertStatus;
            DDLogVerbose(@"Provided status for user: %@; status: %d", user, providedStatus);

            // Check if we have valid certificate of the user.
            if (providedStatus == hr_certificateStatus_ok){

                // Certificate is valid. Update last certificate check time in database so
                // we avoid redundant certificate checks.
                PEXDbContentValues * dataToInsert = [[PEXDbContentValues alloc] init];
                [dataToInsert put:PEX_UCRT_FIELD_DATE_LAST_QUERY double: [[NSDate dateWithTimeIntervalSinceNow:0.0] timeIntervalSince1970]];
                [dataToInsert put:PEX_UCRT_FIELD_CERTIFICATE_STATUS integer: (int)CERTIFICATE_STATUS_OK];
                NSString * where = [NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER];
                [self.params.cr update:[PEXDbUserCertificate getURI]
                         ContentValues:dataToInsert
                             selection:where
                         selectionArgs:@[user]];

                DDLogVerbose(@"Certificate for user: %@; updated in database (query time also)", user);
                // We don't have to continue, certificate is valid -> move to next user.
                continue;
            } else {
                // something is wrong with stored certificate,
                // deleting from certificate database.
                @try {
                    int deleteResult =  [self.params.cr delete:[PEXDbUserCertificate getURI]
                                                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER]
                                                 selectionArgs:@[user]];
                    DDLogInfo(@"Certificate for user [%@] removed; int: %d", user, deleteResult);
                } @catch(NSException * e){
                    DDLogError(@"Exception during removing invalid certificate for: %@, exception=%@", user, e);
                }
            }
        }

        // If we are here then
        //	a) user had no certificate stored
        //	b) or user had certificate stored, but was invalid
        // thus process this result - new certificate should be provided or error code if
        // something is wrong with certificate on server side (missing, invalid, revoked).
        NSData * cert = wr.certificate;
        @try {
            // Store certificate to database in each case (invalid vs. ok), both is
            // useful to know. We than have fresh data stored in database (no need to re-query
            // in case of error).
            PEXDbUserCertificate * crt2db = [[PEXDbUserCertificate alloc] init];
            crt2db.dateCreated = [NSDate date];
            crt2db.dateLastQuery = [NSDate date];
            crt2db.certificateStatus = @(wr.status);
            crt2db.owner = user;

            // Returned certificate is valid, process & store it.
            if (wr.status == CERTIFICATE_STATUS_OK && cert != nil && cert.length > 0) {
                PEXX509 * crt = [PEXCryptoUtils importCertificateFromDERWrap:cert];
                if (!crt.isAllocated){
                    DDLogWarn(@"Problem with a certificate parsing for user %@", user);
                    continue;
                }

                // check CN match
                NSString *cnFromCert = [PEXCryptoUtils getCNameCrt:crt.getRaw totalCount:nil];
                if (![user isEqualToString:cnFromCert]){
                    DDLogError(@"Security alert! Server returned certificate with different CN!");
                    continue;
                } else {
                    DDLogVerbose(@"Certificate CN matches for %@", cnFromCert);
                }

                // Verify new certificate with trust verifier
                BOOL crtOk = [PEXSecurityCenter tryOsslCertValidate:crt settings:[PEXCertVerifyOptions optionsWithAllowOldCaExpired:YES]];
                if (!crtOk){
                    DDLogInfo(@"Certificate was not verified");
                    continue;
                }

                // Sec: Re-export cert to DER to get rid of potential rubbish.
                NSData * certDER = [PEXCryptoUtils exportCertificateToDERWrap:crt];
                if (certDER==nil){
                    DDLogError(@"Cannot export X509 certificate to DER");
                    continue;
                }

                // Store certificate to database.
                // We now need to compute certificate digest.
                NSString * certificateHash = [PEXMessageDigest getCertificateDigestDER:certDER];
                DDLogVerbose(@"Certificate digest computed: %@", certificateHash);

                crt2db.certificate = certDER;
                crt2db.certificateHash = certificateHash;

                certificates[wr.user] = crt;
                certificateHashes[wr.user] = certificateHash;
            }

            // Store result of this query to DB. Can also have error code - usable not to query for
            // certificate too often.
            [PEXDbUserCertificate insertUnique:user cr:self.params.cr cv:crt2db.getDbContentValues];
        } @catch (NSException * e) {
            DDLogWarn(@"Exception thrown: %@", e);
        }
    }
}
@end

@implementation PEXClistFetchStoreTask
- (void)subMain {
    if (!self.params.updateClistTable){
        DDLogVerbose(@"Contactlist table update skipped");
        return;
    }

    NSMutableDictionary * certificateHashes = self.state.certificateHashes;
    NSMutableDictionary * contacts = self.state.contacts;

    // Main sets for user update, which one to add, delete and update.
    NSMutableSet * sip2del = [[NSMutableSet alloc] init];
    NSMutableSet * sip2upd = [[NSMutableSet alloc] init];

    // Get list of current users stored in DB so we can update it.
    NSArray * storedContacts = [PEXDbContact getListForAccount:self.params.cr accountId:self.params.dbId];
    NSMutableDictionary * contactMap = [[NSMutableDictionary alloc] init];
    for(PEXDbContact * u in storedContacts){
        contactMap[u.sip] = u;

        if (contacts[u.sip] == nil){
            // Stored locally, not present in server records, remove.
            [sip2del addObject:u.sip];
        } else {
            // Stored locally, present in server records, update.
            [sip2upd addObject:u.sip];
        }
    }

    // Delete phase - delete marked users.
    // TODO: We should also delete user artifacts, messages, logs, file records, ...
    [PEXDbContact removeContactsForAccount:self.params.cr accountId:self.params.dbId names:sip2del.allObjects];

    // List of content values to be inserted in a batch.
    NSMutableArray * users2insert = [[NSMutableArray alloc] initWithCapacity:contacts.count];

    // Now iterate over mockContacts and store it to database
    for(NSString * sip in contacts){
        @try {
            BOOL doUpdate = [sip2upd containsObject:sip];
            PEXDbContact * u = nil;
            if (doUpdate){
                u = [PEXDbContact newProfileFromDbSip:self.params.cr sip:sip projection:[PEXDbContact getLightProjection]];
                u.presenceStatusType = nil;
                u.presenceStatusText = nil;
            } else {
                u = [[PEXDbContact alloc] init];
                u.sip = sip;
                u.dateCreated = [NSDate date];
                u.account = @(self.params.dbId);
            }

            BOOL isHidden = NO;
            u.dateLastModified = [NSDate date];

            hr_contactListElement * elem = contacts[sip];
            // Extract display name, use display name provided by server, if any.
            NSString * serverDisplayName = elem.displayName;
            if ([PEXUtils isEmpty:serverDisplayName]){
                NSArray * splits = [sip componentsSeparatedByString:@"@"];
                if (splits != nil){
                    u.displayName = splits[0];
                } else {
                    u.displayName = sip;
                }
            } else {
                u.displayName = [PEXDbContact stripHidePrefix:serverDisplayName wasPresent:&isHidden];
            }

            // Whitelist status.
            u.inWhitelist = elem.whitelistStatus == hr_userWhitelistStatus_in ? true : false;
            u.hideContact = @(isHidden);

            // Reset presence of the contact, invalidating old info. Usefull during login.
            if (self.params.resetPresence){
                u.presenceOnline = NO;
                u.presenceStatusType = @(PEXPbPresencePushPEXPbStatusOffline);
            }

            // Certificate hash.
            id curCertHash = certificateHashes[sip];
            if (curCertHash!=nil){
                u.certificateHash = (NSString *) curCertHash;
            } else {
                u.certificateHash = @"";
            }

            if (doUpdate && u.id != nil) {
                BOOL success = [self.params.cr update:[PEXDbContact getURI]
                                        ContentValues:[u getDbContentValues]
                                            selection:[PEXDbContact getWhereForId]
                                        selectionArgs:@[[u.id stringValue]]];
                DDLogVerbose(@"Contact [%@] updated; display name: %@, success=%d", sip, u.displayName, success);
            } else {
                [users2insert addObject:[u getDbContentValues]];
                DDLogVerbose(@"Contact [%@] add 2 store; display name: %@", sip, u.displayName);
            }
        } @catch(NSException * ex){
            DDLogError(@"Exception during contact list management for: %@, exception=%@", self.params.sip, ex);
        }
    }

    // Add users to the database.
    if ([users2insert count] > 0) {
        [self.params.cr bulk:[PEXDbContact getURI] insert:users2insert];
        [PEXPresenceCenter broadcastUserAddedChange];
    }

    // Everything is finished by now - store time of last clist sync.
    [[PEXUserAppPreferences instance] setDoublePrefForKey:PEX_CLIST_FETCH_LAST_FINISH_TSTAMP value:[self.state.lastFetchTime timeIntervalSince1970]];
}

@end

@implementation PEXCListFetchTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"ContactlistFetch";

        // Initialize empty state
        [self setState: [[PEXClistFetchTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return PCLT_MAX;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXClistFetchSOAPTask          alloc] initWithDel:self andName:@"FetchCl"]     id:PCLT_FETCH_CL];
    [self setSubTask:[[PEXClistFetchProcessTask       alloc] initWithDel:self andName:@"ProcessCl"]   id:PCLT_PROCESS_CL];
    [self setSubTask:[[PEXClistFetchCertRefreshTask   alloc] initWithDel:self andName:@"CertRefresh"] id:PCLT_CERT_REFRESH];
    [self setSubTask:[[PEXClistFetchProcessCertsTask  alloc] initWithDel:self andName:@"CertProcess"] id:PCLT_CERT_PROCESS];
    [self setSubTask:[[PEXClistFetchStoreTask         alloc] initWithDel:self andName:@"StoreCl"]     id:PCLT_STORE];

    // Add dependencies to the tasks.
    [self.tasks[PCLT_PROCESS_CL]    addDependency:self.tasks[PCLT_FETCH_CL]];
    [self.tasks[PCLT_CERT_REFRESH]  addDependency:self.tasks[PCLT_PROCESS_CL]];
    [self.tasks[PCLT_CERT_PROCESS]  addDependency:self.tasks[PCLT_CERT_REFRESH]];
    [self.tasks[PCLT_STORE]         addDependency:self.tasks[PCLT_CERT_PROCESS]];

    // Mark last task so we know what to wait for.
    [self.tasks[PCLT_STORE] setIsLast:YES];
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