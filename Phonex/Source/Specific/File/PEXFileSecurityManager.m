//
// Created by Dusan Klinec on 12.04.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXFileSecurityManager.h"
#import "PEXService.h"
#import "PEXApplicationStateChange.h"
#import "PEXSecurityCenter.h"

// Action
NSString * PEX_FILE_PROTECTION_SETTING_CHANGED = @"net.phonex.phonex.security.action.file_protection_changed";

// Preference
NSString * PEX_FILE_PROTECTION_SETTING_VER = @"security.file_protection_change_ver";
NSString * PEX_FILE_PROTECTION_SETTING_STARTED_VER = @"security.file_protection_change_started_ver";
NSString * PEX_FILE_PROTECTION_SETTING_COMPLETED_VER = @"security.file_protection_change_completed_ver";

@interface PEXFileSecurityManager () {}
/**
* Operation queue for certificate refresh task.
* Serial queue for execution in background.
*/
@property(nonatomic) NSOperationQueue * opqueue;
@property(nonatomic) BOOL registered;
@end


@implementation PEXFileSecurityManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.opqueue = [[NSOperationQueue alloc] init];
        self.opqueue.maxConcurrentOperationCount = 1;
        self.opqueue.name = @"fileSecOpQueue";
        self.registered = NO;
    }

    return self;
}

+ (PEXFileSecurityManager *)instance {
    static PEXFileSecurityManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];
        [center addObserver:self selector:@selector(onProtectionSettingChange:) name:PEX_FILE_PROTECTION_SETTING_CHANGED object:nil];

        self.registered = YES;
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

- (void)dealloc {
    if (self.registered) {
        [self doUnregister];
    }
}

// Entry point
- (void)checkProtectionChangeAsync {
    WEAKSELF;
    NSBlockOperation * const operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation * const weakOperation = operation;

    // Main operation logic.
    [operation addExecutionBlock:^(void) {
        PEXFileSecurityManager * sSelf = weakSelf;

        // Is check necessary?
        const NSInteger curVer = [sSelf getCurrentSettingsVer];
        const NSInteger completedVer = [sSelf getSettingsChangeCompletedVer];
        if (curVer == completedVer){
            return;
        }

        PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];

        // 1. Apply settings for identity files (keys)
        // 2. Apply settings for database files
        // Implementation: Consider the whole private directory as a mix of identity + database files.
        // What is not database (easier to specify) it is identity file.
        NSString * privateDir = [PEXSecurityCenter getDefaultPrivateDirectory: YES];

        // Set directory backup flag.
        const BOOL flagIdentity = [prefs getDefaultBackupFlagForIdentity];
        const BOOL flagDatabase = [prefs getDefaultBackupFlagForDatabase];
        const BOOL flagDocs = [prefs getDefaultBackupFlagForFiles];
        const BOOL privateDirBackupFlag = flagIdentity || flagDatabase;
        [PEXSecurityCenter trySetBackupFlagFile:privateDir backupFlag:privateDirBackupFlag];

        // Recursively for all directory contents.
        [PEXSecurityCenter setBackupFlagOnAll:privateDir flagBlock:^BOOL(NSString *path) {
            if ([privateDir isEqualToString:path]){
                return privateDirBackupFlag;
            }

            pex_security_file_class protectionClass = [PEXSecurityCenter getFileProtectionClass:path];
            return (protectionClass == PEX_SECURITY_FILE_CLASS_DB) ? flagDatabase : flagIdentity;
        }];

        // 3. Apply settings for file transfer and other files.
        NSString * docs = [PEXSecurityCenter getDefaultDocsDirectory:nil createIfNonexistent:YES];
        [PEXSecurityCenter setBackupFlagOnAll:docs flagBlock:^BOOL(NSString *path) {
            return flagDocs;
        }];

        // 4. All caches are local.
        NSString * caches = [PEXSecurityCenter getDefaultCachesDirectory:nil createIfNonexistent:YES];
        [PEXSecurityCenter setBackupFlagOnAll:caches flagBlock:^BOOL(NSString *path) {
            return NO;
        }];

        // Everything is done -> mark as completed.
        DDLogVerbose(@"File security check completed for version %ld", (long) curVer);
        [sSelf setSettingsChangeCompletedVer:curVer];
    }];

    // Kick it off.
    [self.opqueue addOperation:operation];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        [self checkProtectionChangeAsync];
    }
}

- (void)onProtectionSettingChange:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil){
        return;
    }
    [self checkProtectionChangeAsync];
}

-(NSInteger) getCurrentSettingsVer {
    return [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_FILE_PROTECTION_SETTING_VER defaultValue:0];
}

-(NSInteger) getSettingsChangeStartedVer {
    return [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_FILE_PROTECTION_SETTING_STARTED_VER defaultValue:-1];
}

-(NSInteger) getSettingsChangeCompletedVer {
    return [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_FILE_PROTECTION_SETTING_COMPLETED_VER defaultValue:-1];
}

-(void) setSettingsChangeStartedVer: (NSInteger) ver {
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_FILE_PROTECTION_SETTING_STARTED_VER value:ver];
}

-(void) setSettingsChangeCompletedVer: (NSInteger) ver {
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_FILE_PROTECTION_SETTING_COMPLETED_VER value:ver];
}

-(void) incSettingsVer {
    @synchronized (self) {
        [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_FILE_PROTECTION_SETTING_VER value:[self getCurrentSettingsVer]+1];
    }
}

- (void)updatePrivData:(PEXUserPrivate *)privData{

}

@end