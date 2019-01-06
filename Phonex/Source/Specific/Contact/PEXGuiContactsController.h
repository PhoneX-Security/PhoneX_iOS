//
//  PEXGuiContactsController.h
//  Phonex
//
//  Created by Matej Oravec on 22/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"

@protocol PEXGuiPresenceListener;
@protocol PEXPreferenceChangedListener;

@class PEXDbContact;
@class PEXContactRemoveExecutor;

@interface PEXGuiContactsController : PEXGuiControllerContentObserver
        <PEXGuiPresenceListener,
        PEXPreferenceChangedListener,
        UICollectionViewDelegate,
        UICollectionViewDataSource>
{
@protected bool _showSipForContact;
}

// TODO make it as protocol
- (void) setEnabled:(const bool) enabled forContact:(const PEXDbContact * const) contact;

@end
