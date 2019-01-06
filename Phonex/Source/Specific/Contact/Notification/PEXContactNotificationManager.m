//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXContactNotificationManager.h"
#import "PEXUri.h"
#import "PEXDbContactNotification.h"
#import "PEXDbContentProvider.h"
#import "PEXDbAppContentProvider.h"
#import "PEXPairingUpdateParams.h"
#import "PEXPairingUpdateTask.h"
#import "PEXTask_Protected.h"

@interface PEXContactNotificationManager()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * listeners;

@property (nonatomic) NSMutableArray * cachedNotifications;

@end

@implementation PEXContactNotificationManager {

}

- (id) init
{
    self = [super init];


    self.lock = [[NSLock alloc] init];
    self.listeners = [[NSMutableArray alloc] init];
    self.cachedNotifications = [[NSMutableArray alloc] init];

    return self;
}

- (void)initContent
{
    [self.lock lock];

    [[PEXDbAppContentProvider instance] registerObserverInsert:self];
    [[PEXDbAppContentProvider instance] registerObserverDelete:self];
    [[PEXDbAppContentProvider instance] registerObserverUpdate:self];

    [self loadItems];

    [self.lock unlock];
}

- (void) dealloc
{
    [self.lock lock];

    [[PEXDbAppContentProvider instance] unregisterObserverInsert:self];
    [[PEXDbAppContentProvider instance] unregisterObserverDelete:self];
    [[PEXDbAppContentProvider instance] unregisterObserverUpdate:self];

    [self.lock unlock];
}

- (void) loadItems
{
    PEXDbCursor * const cursor = [self loadAllNotificationsFromNewest];

    bool notify = false;
    while (cursor && [cursor moveToNext])
    {
        PEXDbContactNotification * const notification = [PEXDbContactNotification contactNotificationFromCursor:cursor];

        if (notification)
        {
            [self.cachedNotifications addObject:notification];

            if (![notification.seen boolValue])
                notify = true;
        }
    }

    [self notifyListenersInternal];

    if (notify)
    {
        if (![[PEXGNFC instance] notifyContactNorificationAsyncBy:self.cachedNotifications.count])
            [PEXContactNotificationManager seeAllNotificationsAsync];
    }
}

- (bool)deliverSelfNotifications {
    return false;
}

- (PEXDbCursor *)loadAllNotificationsFromNewest
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContactNotification getURI]
       projection:[PEXDbContactNotification getFullProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:[PEXDbContactNotification getDefaultSortOrder]];
}

- (PEXDbCursor *)loadAllNotifications
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContactNotification getURI]
       projection:[PEXDbContactNotification getFullProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:nil];
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    // NO-OP
}

- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContactNotification getURI]])
        return;

    PEXDbCursor * const cursor = [self loadAllNotificationsFromNewest];

    [self.lock lock];

    bool notify = false;
    int insertionOffset = 0;

    while (cursor && [cursor moveToNext])
    {
        PEXDbContactNotification * const notification = [PEXDbContactNotification contactNotificationFromCursor:cursor];

        if (notification)
        {
            // end iteration if we reach already cached ones
            if ([self.cachedNotifications containsObject:notification])
                break;

            if (self.cachedNotifications.count == 0)
                [self.cachedNotifications addObject:notification];
            else
                [self.cachedNotifications insertObject:notification
                                               atIndex:insertionOffset];

            if (![notification.seen boolValue])
                notify = true;

            ++insertionOffset;
        }
    }

    [self notifyListenersInternal];

    if (notify)
        [[PEXGNFC instance] notifyContactNorificationAsyncBy:self.cachedNotifications.count];

    [self.lock unlock];
}

- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContactNotification getURI]])
        return;

    PEXDbCursor * const cursor = [self loadAllNotifications];

    NSMutableArray * const remnantIds = [[NSMutableArray alloc] initWithCapacity:[cursor getCount]];
    const int idPosition = [cursor getColumnIndex:PEX_DBCONTACTNOTIFICATION_FIELD_ID];

    while (cursor && [cursor moveToNext])
    {
        [remnantIds addObject:[cursor getInt64:idPosition]];
    }

    [self.lock lock];

    bool continueNotification = false;
    for (int i = 0; i < self.cachedNotifications.count; ++i)
    {
        const PEXDbContactNotification * const notification = self.cachedNotifications[i];
        if (![remnantIds containsObject:notification.id])
        {
            [self.cachedNotifications removeObjectAtIndex:i];
            --i;
        }
        else if (![notification.seen boolValue])
        {
            continueNotification = true;
        }
    }

    [self notifyListenersInternal];

    if (continueNotification)
        [[PEXGNFC instance] setContactNorificationAsyncFor:self.cachedNotifications.count];
    else
        [[PEXGNFC instance] unsetContactNorificationAsync];


    [self.lock unlock];
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContactNotification getURI]])
        return;

    PEXDbCursor * const cursor = [self loadAllNotifications];

    [self.lock lock];

    bool continueNotification = false;
    while (cursor && [cursor moveToNext])
    {
        const PEXDbContactNotification * const notification =
                [PEXDbContactNotification contactNotificationFromCursor:cursor];

        if (notification)
        {
            const NSUInteger indexInCache = [self.cachedNotifications indexOfObject:notification];

            if (indexInCache != NSNotFound)
            {
                PEXDbContactNotification * const cachedNotification = self.cachedNotifications[indexInCache];
                [self updateIfNeeded:cachedNotification with:notification];

                if (!cachedNotification.seen)
                    continueNotification = true;
            }
        }
    }

    if (continueNotification)
        [[PEXGNFC instance] setContactNorificationAsyncFor:self.cachedNotifications.count];
    else
        [[PEXGNFC instance] unsetContactNorificationAsync];


    [self.lock unlock];
}

- (void) updateIfNeeded: (PEXDbContactNotification * const) first
                   with: (const PEXDbContactNotification * const) second
{
    first.seen = second.seen;
}

- (void)addListenerAndSet:(id <PEXContactNotificationListener>)listener {

    [self.lock lock];

    [self.listeners addObject:listener];
    NSArray * const cachedNotificationsCopy = [self.cachedNotifications copy];
    [listener countChanged:cachedNotificationsCopy];

    [self.lock unlock];
}

- (void)removeListener:(id <PEXContactNotificationListener>)listener {

    [self.lock lock];

    [self.listeners removeObject:listener];

    [self.lock unlock];
}

- (void) notifyListenersInternal
{
    NSArray * const listenersCopy = [self.listeners copy];
    NSArray * const notificationsCopy = [self.cachedNotifications copy];

    const int count = self.listeners.count;

    for (id<PEXContactNotificationListener> listener in listenersCopy)
        [listener countChanged:notificationsCopy];
}

+ (void)seeAllNotificationsAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        PEXDbContentValues *values = [[PEXDbContentValues alloc] init];
        [values put:PEX_DBCONTACTNOTIFICATION_FIELD_SEEN boolean:true];

        [[PEXDbAppContentProvider instance]
                update:[PEXDbContactNotification getURI]
         ContentValues:values
             selection:nil
         selectionArgs:nil];
    });
}

+ (void) removeNotification: (const PEXDbContactNotification * const) notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PEXDbAppContentProvider instance]
                delete:[PEXDbContactNotification getURI]
             selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCONTACTNOTIFICATION_FIELD_ID]
         selectionArgs:@[notification.id]];

        // Call server deletion.
        PEXPairingUpdateParams * params = [PEXPairingUpdateParams paramsWithSingleId:notification.serverId resolution:hr_pairingRequestResolutionEnum_denied];
        PEXPairingUpdateTask * task = [[PEXPairingUpdateTask alloc] init];
        task.params = params;
        task.privData = [[PEXAppState instance] getPrivateData];
        [task prepareForPerform];
        [task perform];
        [task start];
    });
}

@end