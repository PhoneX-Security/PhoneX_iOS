//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXXMPPPushProcessor.h"
#import "PEXXmppManager.h"
#import "PEXService.h"
#import "PEXPushNewCertEvent.h"
#import "PEXSingleLoginWatcher.h"
#import "PEXPushClistSyncEvent.h"
#import "PEXPushManager.h"
#import "PEXPushDhUseEvent.h"
#import "PEXPushContactCertUpdatedEvent.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXLicenceManager.h"
#import "PEXPushPairingRequestEvent.h"
#import "PEXPushLogoutEvent.h"

@interface PEXXMPPPushProcessor() {
    int64_t _lastPushTstamp;
    int64_t _lastClistTstamp;
    int64_t _lastDhUseTstamp;
    int64_t _lastContactCertUpdateTstamp;
    int64_t _lastUserLicenceUpdateTstamp;
    int64_t _lastPairingRequestTstamp;
    int64_t _lastLogoutEventTstamp;

    int64_t _lastNewCertNotBefore;
    NSString * _lastNewCertPrefHash;
}
@end

static bool checkAndSetTimeStamp(NSNumber * const timeStamp, int64_t * const lastTimeStamp);

@implementation PEXXMPPPushProcessor {

}

- (instancetype)initWithMgr:(PEXXmppManager *)mgr dispatchQueue:(dispatch_queue_t)dispatchQueue {
    self = [super init];
    if (self) {
        self.mgr = mgr;
        self.dispatchQueue = dispatchQueue;
        self.workQueue = dispatch_queue_create("net.phonex.xmpp.pushProcessor.queue", NULL);
        _lastPushTstamp = 0;
        _lastClistTstamp = 0;
        _lastDhUseTstamp = 0;
        _lastContactCertUpdateTstamp = 0;
        _lastUserLicenceUpdateTstamp = 0;
        _lastPairingRequestTstamp = 0;
        _lastNewCertNotBefore = 0;
        _lastLogoutEventTstamp = 0;
        _lastNewCertPrefHash = nil;
    }

    return self;
}

+ (instancetype)processorWithMgr:(PEXXmppManager *)mgr dispatchQueue:(dispatch_queue_t)dispatchQueue {
    return [[self alloc] initWithMgr:mgr dispatchQueue:dispatchQueue];
}

- (void)handlePush:(NSString *)json {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_workQueue block:^{
        [weakSelf handlePushInt:json];
    }];
}

-(void) handlePushInt: (NSString *) json {
    NSError * jsonError = nil;
    @try {
        // Parse JSON data.
        NSDictionary * main = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonError];
        if (jsonError != nil) {
            DDLogError(@"Error parsing JSON data: %@", jsonError);
            return;
        }

        // Action check.
        NSString * action = main[@"action"];
        if (action == nil || ![@"push" isEqualToString:action]) {
            DDLogWarn(@"Unknown query action: %@", action);
            return;
        }

        // Time stamp check.
        NSNumber * tstamp = main[@"tstamp"];
        if (tstamp != nil && [tstamp longLongValue] < _lastPushTstamp){
            DDLogVerbose(@"Already processed newer push message, dropping this");
            return;
        }

        if (tstamp != nil){
            _lastPushTstamp = [tstamp longLongValue];
        }

        NSString * user = main[@"user"];
        NSArray * msgs = main[@"msgs"];
        if (msgs == nil || [msgs count] == 0 || user == nil){
            return;
        }

        // Process push messages individually
        for(NSDictionary * msg in msgs){
            NSString * push = msg[@"push"];
            NSNumber * pushTstamp = msg[@"tstamp"];
            NSDictionary * data = msg[@"data"];

            if ([@"clistSync" isEqualToString:push]){
                [self handleClistSync:user tstamp:pushTstamp];

            } else if ([@"newCert" isEqualToString:push]) {
                [self handleNewCert:user tstamp:pushTstamp data:data];

            } else if ([@"dhUse" isEqualToString:push]){
                [self handleDhUse:user tstamp:pushTstamp];

            } else if ([@"authCheck" isEqualToString:push]) {
                // TODO: implement auth check (password was changed) check.

            } else if ([@"cCrtUpd" isEqualToString:push]) {
                [self handleContactCertUpdate:user tstamp:pushTstamp data:data];

            } else if ([@"pair" isEqualToString:push]) {
                [self handlePairingRequestEvent:user tstamp:pushTstamp data:data];

            } else if ([@"logout" isEqualToString:push]) {
                [self handleLogoutEvent:user tstamp:pushTstamp data:data];

            } else if ([@"licCheck" isEqualToString:push]) {
                [self handleLicCheckEvent:user tstamp:pushTstamp data:data];

            } else if ([@"mCall" isEqualToString:push]) {
                // TODO: implement missed call check.

            } else if ([@"newFile" isEqualToString:push]) {
                // TODO: implement new file check.

            } else if ([@"vCheck" isEqualToString:push]) {
                // TODO: implement version check.

            } else {
                DDLogWarn(@"Unknown push message: %@", push);
            }
        }

    } @catch(NSException * ex){
        DDLogError(@"JSON push processing failed, exception=%@", ex);
    }
}

-(void) handleClistSync: (NSString *) user tstamp: (NSNumber *) tstamp {
    if (tstamp != nil){
        long long int ts = [tstamp longLongValue];
        if (ts < _lastClistTstamp){
            return;
        }

        _lastClistTstamp = ts;
    }

    PEXPushClistSyncEvent * evt = [PEXPushClistSyncEvent eventWithUser:user tstamp:tstamp];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_CLIST_CHECK object:nil
                                                      userInfo:@{PEX_EXTRA_CLIST_CHECK : evt}];
}

-(void) handleDhUse: (NSString *) user tstamp: (NSNumber *) tstamp {

    if (!checkAndSetTimeStamp(tstamp, &_lastDhUseTstamp))
        return;

    PEXPushDhUseEvent * evt = [PEXPushDhUseEvent eventWithUser:user tstamp:tstamp];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_DHKEYS_CHECK object:nil
                                                      userInfo:@{PEX_EXTRA_DHKEYS_CHECK : evt}];
}

-(void) handleNewCert: (NSString *) user tstamp: (NSNumber *) tstamp data: (NSDictionary *) data {
    NSNumber * notBeforeObj = data[@"certNotBefore"];
    NSString * certHashPrefix = data[@"certHashPref"];
    if (notBeforeObj == nil || certHashPrefix == nil){
        DDLogInfo(@"Ignoring newCert push message, no meta info contained");
        return;
    }

    int64_t notBefore = [notBeforeObj longLongValue];
    if (notBefore < _lastNewCertNotBefore){
        return;
    }

    if ([certHashPrefix isEqualToString:_lastNewCertPrefHash]){
        return;
    }

    _lastNewCertNotBefore = notBefore;
    _lastNewCertPrefHash = certHashPrefix;
    PEXPushNewCertEvent * evt = [PEXPushNewCertEvent eventWithUser:user tstamp:tstamp notBefore:notBefore certHashPrefix:certHashPrefix];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_CHECK_SINGLE_LOGIN object:nil
                                                      userInfo:@{PEX_EXTRA_CHECK_SINGLE_LOGIN : evt}];
}

-(void) handleContactCertUpdate: (NSString *) user tstamp: (NSNumber *) tstamp data: (NSDictionary *) data {

    if (!checkAndSetTimeStamp(tstamp, &_lastContactCertUpdateTstamp)) {
        return;
    }

    PEXPushContactCertUpdatedEvent * evt = [PEXPushContactCertUpdatedEvent eventWithUser:user tstamp:tstamp];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_PUSH_CONTACT_CERT_UPDATE object:nil
                                                      userInfo:@{PEX_EXTRA_PUSH_CONTACT_CERT_UPDATE : evt}];
}

-(void) handlePairingRequestEvent: (NSString *) user tstamp: (NSNumber *) tstamp data: (NSDictionary *) data {

    if (!checkAndSetTimeStamp(tstamp, &_lastPairingRequestTstamp)) {
        return;
    }

    PEXPushPairingRequestEvent * evt = [PEXPushPairingRequestEvent eventWithTstamp:tstamp user:user];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_PUSH_PAIRING_REQUEST object:nil
                                                      userInfo:@{PEX_EXTRA_PUSH_PAIRING_REQUEST : evt}];
}

-(void) handleLogoutEvent: (NSString *) user tstamp: (NSNumber *) tstamp data: (NSDictionary *) data {

    if (!checkAndSetTimeStamp(tstamp, &_lastLogoutEventTstamp)) {
        return;
    }

    PEXPushLogoutEvent * evt = [PEXPushLogoutEvent eventWithTstamp:tstamp user:user];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_PUSH_LOGOUT object:nil
                                                      userInfo:@{PEX_EXTRA_PUSH_LOGOUT : evt}];
}

-(void) handleLicCheckEvent: (NSString *) user tstamp: (NSNumber *) tstamp data: (NSDictionary *) data {

    if (!checkAndSetTimeStamp(tstamp, &_lastUserLicenceUpdateTstamp)) {
        return;
    }

    [[[PEXService instance] licenceManager] triggerCheckPermissions];
}

static bool checkAndSetTimeStamp(NSNumber * const timeStamp, int64_t * const lastTimeStamp)
{
    bool result = false;

    if (timeStamp != nil){
        const long long int ts = [timeStamp longLongValue];
        if (ts > *lastTimeStamp)
        {
            *lastTimeStamp = ts;
            result = true;
        }
    }

    return result;
}

@end