//
// Created by Matej Oravec on 12/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXChatAccountingManager.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXDbAppContentProvider.h"
#import "PEXTimeUtils.h"
#import "PEXGuiTimeUtils.h"
#import "PEXPermissionsUtils.h"
#import "PEXLicenceManager.h"
#import "PEXDbAccountingPermission.h"
#import "PEXService.h"

@interface PEXChatAccountingManager ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * listeners;

@end

@implementation PEXChatAccountingManager {

}

- (void) permissionsChanged: (NSArray * const) permissions
{
    [self loadStateAndnotifyListenersWithPermissions:permissions];
}

- (void) addListenerAndSet: (id<PEXMessageAccountingListener>) listener
{
    [self.lock lock];

    [self.listeners addObject:listener];

    int64_t limit;
    const int64_t messageCount =
            [PEXChatAccountingManager getSpentMessagesLimitOut:&limit
                           fromPermissions:nil];

    [listener messagesStatusChanged:messageCount withLimit:limit];

    [self.lock unlock];
}

- (void) removeListener: (id<PEXMessageAccountingListener>) listener
{
    [self.lock lock];

    [self.listeners removeObject:listener];

    [self.lock unlock];
}

+ (int) getMessageCountLimitPeriodInDays
{
    return 1;
}

- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];
    self.listeners = [[NSMutableArray alloc] init];

    return self;
}

- (void)loadStateAndnotifyListenersWithPermissions: (NSArray * const) permissions
{
    [self.lock lock];

    if (!self.listeners)
    {
        [self.lock unlock];
        return;
    }


    NSArray * const listenersCopy = [self.listeners copy];

    int64_t limit;

    // LiceneManager informs always with permissions set (not nil); so this is not called without permissions
    // -> no deadlock
    const int64_t messageCount =
            [PEXChatAccountingManager getSpentMessagesLimitOut:&limit
                           fromPermissions:permissions];

    [self.lock unlock];

    for (id<PEXMessageAccountingListener> listener in listenersCopy)
        [listener messagesStatusChanged:messageCount withLimit:limit];
}

+ (int64_t) getAvailableMessages: (NSArray *) permissions
{
    int64_t limit = 0;
    const int64_t spent = [self getSpentMessagesLimitOut:&limit fromPermissions:permissions];

    return (limit == -1) ? limit : limit - spent;
}

+ (int64_t)getSpentMessagesLimitOut:(int64_t *const)limitOut
                    fromPermissions: (NSArray *) permissions
{
    if (!permissions)
    {
        // LiceneManager informs always with permissions set (not nil); so this is not called
        // -> no deadlock
        permissions =
                [[[PEXService instance] licenceManager] getPermissions:nil
                                                              forPrefix:PEX_PERMISSION_MESSAGES_PREFIX
                                                           validForDate:nil];
    }

    int64_t spent = 0;
    int64_t limit = 0;

    if (permissions && permissions.count)
    {
        for (const PEXDbAccountingPermission * const permission in permissions)
        {
            if (![PEXPermissionsUtils isPermissionForMessages:permission.name])
                continue;

            const int64_t value = [permission.value longLongValue];

            if (value == -1) {
                limit = value;
                break;
            }
            else if (value != 0)
            {
                if ([PEXPermissionsUtils isPermissionNameDaily:permission.name])
                {
                    const int64_t spentWithin24 =
                        [[[PEXService instance] licenceManager]
                                getOutgoingMessageCountForLastDays:[PEXChatAccountingManager getMessageCountLimitPeriodInDays]];

                    spent += spentWithin24;

                }
                else
                {
                    spent += [permission.spent longLongValue];
                }

                limit += [permission.value longLongValue];
            }
        }
    }

    if (limitOut)
        *limitOut = limit;

    return spent;
}

@end