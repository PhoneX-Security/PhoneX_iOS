//
//  PEXGuiContactsController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 18/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsController.h"
#import "PEXGuiControllerContentObserver_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXRefDictionary.h"
#import "PEXDbContact.h"
#import "PEXDbCursor.h"
#import "PEXGuiContactsItemView.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiActionsOnContactController.h"
#import "PEXGuiActionOnContactExecutor.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXUser.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXContactRemoveExecutor.h"
#import "PEXGuiCrossView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiPresence.h"
#import "PEXGuiPresenceCenter.h"

extern NSString * const CONTACT_VIEW_IDENTIFIER;

@interface PEXGuiContactsController ()
{
    @protected
    volatile bool _showOffline;
}

@property (nonatomic) UICollectionView * collectionView;
@property (nonatomic) PEXRefDictionary * contactsWithInfo;

- (NSIndexPath *) addContact: (PEXDbContact * const) contact;
- (void)setContactsRightPosition:(const PEXDbContact * const) contact;

- (void) registerCell;

@end
