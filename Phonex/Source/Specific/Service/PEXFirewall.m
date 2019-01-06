//
// Created by Dusan Klinec on 11.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXFirewall.h"
#import "PEXDbContentProvider.h"
#import "PEXContentObserver.h"
#import "PEXDbContact.h"
#import "PEXService.h"
#import "PEXSipUri.h"
#import "PEXUtils.h"

/**
* Content observer for user.
*/
@interface PEXFirewallUserObserver : NSObject <PEXContentObserver> {}
@property(nonatomic, weak) PEXFirewall * manager;
@property(nonatomic) PEXUri * destUri;
- (instancetype)initWithManager:(PEXFirewall *)manager;
+ (instancetype)observerWithManager:(PEXFirewall *)manager;
@end

@interface PEXFirewall () {}
@property (nonatomic) PEXFirewallUserObserver * usrObserver;
@property (nonatomic) NSCache * usrCache;

/**
* Identity of a message sender.
*/
@property(nonatomic) BOOL registered;
@end

@implementation PEXFirewall {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.usrCache = [[NSCache alloc] init];
        self.usrCache.countLimit = 128;
        self.registered = NO;
        self.usrObserver = nil;
    }

    return self;
}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }
        // Register user database observer.
        if (self.usrObserver == nil) {
            self.usrObserver = [PEXFirewallUserObserver observerWithManager:self];
            PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];
            [cr registerObserver:self.usrObserver];
        }

        self.registered = YES;
    }
}

- (void)doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        // UNRegister user database observer.
        if (self.usrObserver != nil) {
            PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];
            [cr unregisterObserver:self.usrObserver];
            self.usrObserver = nil;
        }

        [self clearCache];
        self.registered = NO;
    }
}

-(void) clearCache {
    [self.usrCache removeAllObjects];
}

-(BOOL) isCommunicationAllowedFromRemote:(NSString *)fromRemote toLocal:(NSString *)toLocal {
    // At the moment just look to the contact list. If there is a entry for such user, allow it. Deny otherwise.
    // Use caching to speed up lookup. Flush cache on observer change.
    NSString * normFrom = [PEXSipUri getCanonicalSipContact:fromRemote includeScheme:NO];
    NSString * hashKey = [NSString stringWithFormat:@"rem%@:loc%@", normFrom, @""];

    // Lookup cache, if registered.
    if (self.registered){
        NSNumber * cached = [self.usrCache objectForKey:hashKey];
        if (cached != nil){
            return [cached boolValue];
        }
    }

    // Do real database lookup.
    // For now it is enough to have this contact among contacts.
    NSNumber * toCache = @(NO);
    PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * c = [cr query:[PEXDbContact getURI] projection:[PEXDbContact getLightProjection]
                      selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_SIP]
                  selectionArgs:@[normFrom]
                      sortOrder:nil];

    if (c != nil){
        toCache = @([c getCount] > 0);
        [PEXUtils closeSilentlyCursor:c];
    }

    // Store to cache.
    if (self.registered){
        [self.usrCache setObject:toCache forKey:hashKey];
    }

    return [toCache boolValue];
}

- (BOOL)isCallAllowedFromRemote:(NSString *)fromRemote toLocal:(NSString *)toLocal {
    return [self isCommunicationAllowedFromRemote:fromRemote toLocal:toLocal];
}

- (BOOL)isMessageAllowedFromRemote:(NSString *)fromRemote toLocal:(NSString *)toLocal {
    return [self isCommunicationAllowedFromRemote:fromRemote toLocal:toLocal];
}

@end

@implementation PEXFirewallUserObserver
- (instancetype)initWithManager:(PEXFirewall *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        self.destUri = [PEXDbContact getURI];
    }

    return self;
}

+ (instancetype)observerWithManager:(PEXFirewall *)manager {
    return [[self alloc] initWithManager:manager];
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    PEXFirewall * sMgr = self.manager;
    if (![self.destUri matchesBase:uri] || sMgr == nil) {
        return;
    }

    [PEXService executeWithName:nil async:YES block:^{
        [sMgr clearCache];
    }];
}
@end