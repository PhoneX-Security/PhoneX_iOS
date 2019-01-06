//
// Created by Matej Oravec on 02/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCallsManager.h"
#import "PEXControllerManager_Protected.h"

#import "PEXGuiCallsController.h"
#import "PEXGuiCallLog.h"
#import "PEXGuiChatsController.h"
#import "PEXCallLogManager.h"
#import "PEXGuiActionOnContactExecutor.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiCallLogItemView.h"
#import "PEXGuiContentLoaderController_Protected.h"
#import "PEXReport.h"
#import "PEXGuiNotificationCenter.h"

@interface PEXCallsManager()

@end

@implementation PEXCallsManager {

}

- (void) fillController
{
    [self executeOnControllerSync:^{
        [(PEXGuiCallsController *) self.controller largeUpdate];
    }];
}

- (void)loadItems
{
    PEXDbCursor * const callLogCursor = [self loadAllCallLogs];

    [self callLogsAddedForCursor:callLogCursor];
}

// must call mutex
- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbCallLog getURI]])
        [self callLogDeleted];
}

- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbCallLog getURI]])
        [self callLogAdded: ((PEXDbUri*)uri).itemId];
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbContact getURI]])
    {
        [self contactUpdate];
        return;
    }

    if ([uri isEqualToUri:[PEXDbCallLog getURI]])
    {
        [self callLogUpdate];
        return;
    }
}

- (void) callLogAdded: (const NSNumber * const) idValue
{
    PEXDbCursor * const cursor = [self loadAllCallLogsWithId:idValue];

    [self.lock lock];
    [self callLogsAddedForCursor: cursor];
    [self.controller checkEmpty];
    [self.lock unlock];
}

- (void) callLogsAddedForCursor: (PEXDbCursor * const) callLogCursor
{
    NSMutableArray * const indexPathsToAdd = [[NSMutableArray alloc] init];
    const bool wasEmpty = [self isEmpty];

    int index = 0;
    while (callLogCursor && [callLogCursor moveToNext])
    {
        PEXDbCallLog * const callLog = [PEXDbCallLog callLogFromCursor:callLogCursor];

        PEXDbCursor * const contactCursor = [self loadContactWithSip:callLog.remoteContactSip];
        if (contactCursor && [contactCursor moveToNext])
        {
            PEXDbContact * const contact = [PEXDbContact contactFromCursor:contactCursor];
            [self addCallLog:callLog forContact:contact];
            [indexPathsToAdd addObject:[NSIndexPath indexPathForItem:index++ inSection:0]];
        }
    }

    if (self.controller && indexPathsToAdd.count > 0)
    {
        [self updateController:^{
                    [(PEXGuiCallsController *) self.controller addCallLogsForIndexPaths:indexPathsToAdd];
                }
                 shouldBeLarge:wasEmpty];
    }
}

- (void) callLogDeleted
{
    PEXDbCursor * const cursor = [self loadAllCallLogs];

    NSMutableArray * const remnantIds = [[NSMutableArray alloc] initWithCapacity:[cursor getCount]];
    const int idPosition = [cursor getColumnIndex:PEX_DBCLOG_FIELD_ID];

    while (cursor && [cursor moveToNext])
    {
        [remnantIds addObject:[cursor getInt64:idPosition]];
    }

    [self.lock lock];

    const NSArray * const callLogKeys = self.items;
    NSMutableArray * const indexPathsToRemove = [[NSMutableArray alloc] init];

    int indexPath = 0;
    for (int i = 0; i < callLogKeys.count; ++i, ++indexPath)
    {
        const PEXGuiCallLog * const guiCallLog = callLogKeys[i];
        if (![remnantIds containsObject:guiCallLog.callLog.id])
        {
            [self removeCallLog:guiCallLog];
            [indexPathsToRemove addObject:[NSIndexPath indexPathForItem:indexPath inSection:0]];
            --i;
        }
    }

    const bool isEmpty = [self isEmpty];

    if (indexPathsToRemove.count > 0)
    {
        [self updateController:^{
                    [(PEXGuiCallsController *) self.controller removeCallLogsForIndexPaths:indexPathsToRemove];
                }
        shouldBeLarge:isEmpty];
    }

    [self.controller checkEmpty];
    [self.lock unlock];
}

- (void) updateController: (void (^)(void))update shouldBeLarge: (const bool) shouldBeLarge
{
    if (shouldBeLarge)
    {
        [self executeOnControllerSync:^{
            [(PEXGuiCallsController *) self.controller largeUpdate];
        }];
    }
    else
    {
        [self executeOnControllerSync:^{
            update();
        }];
    }
}

- (void) contactUpdate
{
    PEXDbCursor * const cursor = [self loadAllContacts];

    [self.lock lock];

    NSMutableArray * indexPathsToUpdate = [[NSMutableArray alloc] init];

    while (cursor && [cursor moveToNext])
    {
        const PEXDbContact * const dbContact = [PEXDbContact contactFromCursor:cursor];
        for (int i = 0; i < self.items.count; ++i)
        {
            PEXGuiCallLog * const guiCallLog = self.items[i];
            const PEXDbContact * const cachedContact = guiCallLog.contact;

            if ([cachedContact isEqualToContact:dbContact] &&
                    [PEXGuiCallLogItemView contact:cachedContact needsUpdate:dbContact])
            {
                guiCallLog.contact = dbContact;
                [indexPathsToUpdate addObject: [NSIndexPath indexPathForItem:i inSection:0]];
            }
        }
    }

    if (indexPathsToUpdate.count > 0)
    {
        [self executeOnControllerSync:^{
            [(PEXGuiCallsController *) self.controller updateCallLogsForIndexPaths:indexPathsToUpdate];
        }];
    }

    [self.lock unlock];
}

- (void) callLogUpdate
{
    PEXDbCursor * const callLogCursor = [self loadAllCallLogs];

    [self.lock lock];

    NSMutableArray * indexPathsToUpdate = [[NSMutableArray alloc] init];

    while (callLogCursor && [callLogCursor moveToNext])
    {
        const PEXDbCallLog * const callLog = [PEXDbCallLog callLogFromCursor:callLogCursor];
        NSUInteger index = 0;
        PEXGuiCallLog * guiCallLog = [self getPotentialCallLogById:callLog.id outIndex:&index];

        if (([guiCallLog.callLog isEqualToCallLog:callLog]) &&
                [PEXGuiCallLogItemView callLog:guiCallLog.callLog needsUpdate:callLog])
        {
            [self updateGuiCallLog:guiCallLog withCallLog:callLog];
            [indexPathsToUpdate addObject: [NSIndexPath indexPathForItem:index inSection:0]];
        }
    }

    if (indexPathsToUpdate.count > 0)
    {
        [self executeOnControllerSync:^{
            [(PEXGuiCallsController *) self.controller updateCallLogsForIndexPaths:indexPathsToUpdate];
        }];
    }

    [self.lock unlock];
}

# pragma list stuff

- (PEXGuiCallLog *) addCallLog: (PEXDbCallLog * const) callLog
                    forContact:(const PEXDbContact * const) contact
{
    PEXGuiCallLog * const guiCallLog = [[PEXGuiCallLog alloc] init];
    guiCallLog.contact = contact;
    guiCallLog.callLog = callLog;

    [self.items insertObject:guiCallLog atIndex:0];

    guiCallLog.highlighted =
            ([PEXGNFC callLogNotifies:guiCallLog.callLog]) &&
            ([[PEXGNFC instance] increaseCallLogNorificationAsync]);

    return guiCallLog;
}

- (void) removeCallLog: (const PEXGuiCallLog * const) guiCallLog
{
    if ([PEXGNFC callLogNotifies:guiCallLog.callLog])
        [[PEXGNFC instance] decreaseCallLogNorificationAsync];

    const NSUInteger indexOfCallLog = [self.items indexOfObject:guiCallLog];
    [self.items removeObjectAtIndex:indexOfCallLog];
}

- (void) updateGuiCallLog: (PEXGuiCallLog * const) guiCallLog
        withCallLog: (PEXDbCallLog * const)callLog
{
    if ([callLog isIncoming])
        [self shouldNotifyCallLog:guiCallLog withCallLog:callLog];

    [guiCallLog setCallLog:callLog];
}

- (void)shouldNotifyCallLog:(PEXGuiCallLog *const)guiCallLog
                withCallLog: (PEXDbCallLog * const) callLog
{
    const bool oldNotifies = [PEXGNFC callLogNotifies:guiCallLog.callLog];
    const bool newNotifies = [PEXGNFC callLogNotifies:callLog];

    if (oldNotifies && !newNotifies)
    {
        [[PEXGNFC instance] decreaseCallLogNorificationAsync];
        guiCallLog.highlighted = false;
    }
    else if (!oldNotifies && newNotifies)
    {
        if ([[PEXGNFC instance] increaseCallLogNorificationAsync])
            guiCallLog.highlighted = true;
        /*
        else
        {
            // WE ARE IN THE CALL LOG CONTROLLER
            // THERE WILL BE DB NOTIFICATION OF SEEING THE CALLS
            [PEXCallLogManager seeWithId:callLog.id];
        }
        */
    }
}

#pragma list helpers

- (PEXGuiCallLog *) getPotentialCallLogByLog: (const PEXDbCallLog * const) callLog
                                    outIndex: (NSUInteger *) outIndex
{
    return [self getPotentialCallLogById:callLog.id outIndex:outIndex];
}

- (PEXGuiCallLog *) getPotentialCallLogById: (NSNumber * const) id
                                   outIndex: (NSUInteger *) outIndex
{
    PEXGuiCallLog * result = nil;
    const NSArray * const keys = self.items;
    for (NSUInteger i = 0; i < keys.count; ++i)
    {
        PEXGuiCallLog * const guiCallLog = keys[i];
        if ([id isEqualToNumber: guiCallLog.callLog.id])
        {
            result = guiCallLog;
            if (outIndex != nil)
            {
                *outIndex = i;
            }
            break;
        }
    }
    return result;
}

#pragma database stuff

- (PEXDbCursor *) loadAllCallLogs
{
    return [[PEXDbAppContentProvider instance] query:[PEXDbCallLog getURI]
                                          projection:[PEXDbCallLog getLightProjection]
                                           selection:nil
                                       selectionArgs:nil
                                           sortOrder:nil];
}

- (PEXDbCursor *) loadAllCallLogsWithId: (const NSNumber * const) id
{
    return [[PEXDbAppContentProvider instance] query:[PEXDbCallLog getURI]
                                          projection:[PEXDbCallLog getLightProjection]
                                           selection:[PEXDbCallLog getWhereForId]
                                       selectionArgs:[PEXDbCallLog getWhereForIdArgs:id]
                                           sortOrder:nil];
}

- (PEXDbCursor *) loadAllCallLogsForContact: (const PEXDbContact * const) contact
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbCallLog getURI]
       projection:[PEXDbCallLog getLightProjection]
        selection:[PEXDbCallLog getWhereForContact]
    selectionArgs:[PEXDbCallLog getWhereForContactArgs:contact]
        sortOrder:nil];
}

- (PEXDbCursor *) loadContactWithSip: (NSString * const) sip
{
    return [[PEXDbAppContentProvider instance]query:[PEXDbContact getURI]
                                         projection:[PEXDbContact getLightProjection]
                                          selection:[NSString stringWithFormat:@"WHERE %@=?", DBCL(FIELD_SIP)]
                                      selectionArgs:@[sip]
                                          sortOrder:nil];
}

- (PEXDbCursor *) loadContactWithId: (const NSNumber * const) idValue
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
       projection:[PEXDbContact getLightProjection]
        selection:[PEXDbContact getWhereForId]
    selectionArgs:[PEXDbContact getWhereForIdArgs:idValue]
        sortOrder:nil];
}

- (PEXDbCursor *) loadAllContacts
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
       projection:[PEXDbContact getLightProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:nil];
}

#pragma nothing to do here

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    //NOOP
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)callRemoveCallLog:(const PEXGuiCallLog *const)guiCallLog
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CALLLOG_REMOVE];
    NSNumber * const logId = guiCallLog.callLog.id;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^(void)
            {
                [[PEXDbAppContentProvider instance]
                        delete: [PEXDbCallLog getURI]
                     selection: [PEXDbCallLog getWhereForId]
                 selectionArgs: [PEXDbCallLog getWhereForIdArgs:logId]];
            });
}

- (void)actionOnCallLog:(const PEXGuiCallLog *const)guiCallLog
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CALLLOG_ACTION];
    NSString * const sip = guiCallLog.callLog.remoteContactSip;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PEXDbCursor * const contactCursor = [self loadContactWithSip:sip];
        if (contactCursor && [contactCursor moveToNext])
        {
            [self executeOnControllerSync:^{
                [[[PEXGuiActionOnContactExecutor alloc] init]
                        executeWithContact:[PEXDbContact contactFromCursor:contactCursor]
                          parentController:self.controller];
            }];
        }
    });
}


@end