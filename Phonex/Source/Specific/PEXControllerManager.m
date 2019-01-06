//
// Created by Matej Oravec on 02/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXControllerManager.h"
#import "PEXControllerManager_Protected.h"
#import "PEXDbAppContentProvider.h"
#import "PEXGuiContentLoaderController.h"


@implementation PEXControllerManager {

}

- (void) setController: (PEXGuiContentLoaderController *)controller
{
    [self.lock lock];

    _controller = controller;

    if (_controller)
    {
        [self fillController];
    }

    [self.lock unlock];
}

- (bool) isEmpty
{
    return ([self getCount] == 0);
}

- (int) getCount
{
    return self.items.count;
}

- (void) fillController
{
    // NOOP
}

- (id) init
{
    self = [super init];

    self.items = [[NSMutableArray alloc] init];
    self.lock = [[NSLock alloc] init];

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
    // NOOP
}

- (void)executeOnControllerSync: (void (^)(void))actionOnController
{
    if (self.controller)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            actionOnController();
        });
    }
}

- (void)dispatchChangeDelete:(const bool)selfChange uri:(const PEXUri *const)uri {
    // NOOP
}

- (void)dispatchChangeInsert:(const bool)selfChange uri:(const PEXUri *const)uri {
    // NOOP
}

- (void)dispatchChangeUpdate:(const bool)selfChange uri:(const PEXUri *const)uri {
    // NOOP
}

#pragma NOTHING TO DO HERE

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    // NOOP
}

- (bool)deliverSelfNotifications {
    return false;
}

- (id) getItemAt: (const NSUInteger) index
{
    return (index < self.items.count) ?
            self.items[index] :
            nil;
}

@end