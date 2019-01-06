//
//  PEXGuiControllerContentObserver.m
//  Phonex
//
//  Created by Matej Oravec on 10/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"
#import "PEXGuiControllerContentObserver_Protected.h"
#import "PEXDbAppContentProvider.h"
#import "PEXGuiFullSizeBusyView.h"
#import "PEXGuiStatementView.h"

@implementation PEXGuiControllerContentObserver

- (void) preload
{
    [[PEXDbAppContentProvider instance] registerObserverInsert:self];
    [[PEXDbAppContentProvider instance] registerObserverDelete:self];
    [[PEXDbAppContentProvider instance] registerObserverUpdate:self];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[PEXDbAppContentProvider instance] unregisterObserverInsert:self];
    [[PEXDbAppContentProvider instance] unregisterObserverDelete:self];
    [[PEXDbAppContentProvider instance] unregisterObserverUpdate:self];

    [super viewWillDisappear:animated];
}

- (bool) deliverSelfNotifications{return true;}
- (void) dispatchChange: (const bool) selfChange
                    uri: (const PEXUri * const) uri{}

- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri{}
- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri{}
- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri{}

@end
