//
//  PEXGuiContactsController.m
//  Phonex
//
//  Created by Matej Oravec on 22/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiPresenceCenter.h"
#import "PEXPreferenceChangedListener.h"
#import "PEXGuiContactsController.h"
#import "PEXGuiContactsController_Protected.h"
#import "PEXGuiContactsItemCell.h"


NSString * const CONTACT_VIEW_IDENTIFIER = @"contactViewIdentifier";

@interface PEXGuiContactsController ()
{
}

@end

@implementation PEXGuiContactsController

- (void) presencePreset: (const PEX_GUI_PRESENCE) presetPresence
{
    // do nothing
}
- (void) presenceSet: (const PEX_GUI_PRESENCE) setPresence
{
    [self.contentLock lock];

    const bool update = _showOffline;

    if (update)
    {
        _showOffline = false;
        [self updateContacts];
    }

    [self.contentLock unlock];
}

- (void) presenceProcessing
{
    [self.contentLock lock];

    if (!_showOffline)
    {
        _showOffline = true;
        [self setAllOffline];
        dispatch_sync(dispatch_get_main_queue(), ^(void)
        {
            [self.collectionView reloadData];
        });
    }

    [self.contentLock unlock];
}

- (void) postload
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });

    [super postload];
}

- (const UIView *) getContentView
{
    return self.collectionView;
}

- (int) getItemsCount
{
    return self.contactsWithInfo.count;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.collectionView= [[UICollectionView alloc] initWithFrame:self.view.frame
                                        collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    [self.mainView addSubview:self.collectionView];
}

- (void) initLayout
{
    [super initLayout];

    // COLLECTION VIEW
    [PEXGVU scaleFull:self.collectionView];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.itemSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiContactsItemView staticHeight]);

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void) viewDidAppear:(BOOL)animated
{
    // not in loadCOntent because of locks on presenceProcessing
    // sets showprocessing
    [[PEXGuiPresenceCenter instance] addListenerAsync:self];

    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[PEXGuiPresenceCenter instance] removeListener:self];

    [super viewWillDisappear:animated];
}

- (void)initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [self registerCell];

    self.collectionView.delaysContentTouches = false;
}

- (void) loadContent{

    self.contactsWithInfo = [[PEXRefDictionary alloc] init];

    _showSipForContact =
            [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY
                                                   defaultValue:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_DEFAULT];

    [[PEXAppPreferences instance] addListener:self];
    [self loadContacts];

    [self checkEmpty];
}

- (void)preferenceChangedForKey:(NSString *const)key
{
    [self.contentLock lock];
    if (([key isEqualToString:[PEXUserAppPreferences userKeyFor:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY]])
        && (_showSipForContact != [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY
                                                                         defaultValue:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_DEFAULT]))
    {
        _showSipForContact = !_showSipForContact;
        [self reloadContentAsync];
    }
    [self.contentLock unlock];
}

- (void) clearContent
{
    [super clearContent];

    [self.contactsWithInfo removeAllObjects];

    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
        [self checkEmpty];
    });
}

// must be called in mutex
- (void) loadContacts
{
    PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance] query:[PEXDbContact getURI] projection:[PEXDbContact getLightProjection] selection:nil selectionArgs:nil sortOrder:nil];

    while (cursor && [cursor moveToNext])
    {
        PEXDbContact * const contact = [PEXDbContact contactFromCursor:cursor];

        if (contact.hideContact.integerValue == 1)
            continue;

        [self addContact:contact];
    }
}

// CONTENT OBSERVER STUFF
- (void) dispatchChange: (const bool) selfChange
                    uri: (const PEXUri *) uri
{
    // not implemented
}

// must call mutex
- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    PEXDbCursor * const cursor = [self loadContactWithId: ((PEXDbUri*)uri).itemId];

    [self.contentLock lock];

    NSMutableArray * const indiciesAdded = [[NSMutableArray alloc] init];

    while (cursor && [cursor moveToNext])
    {
        PEXDbContact * const contact = [PEXDbContact contactFromCursor:cursor];
        if (![self.contactsWithInfo hasKey:contact])
        {
            if (contact.hideContact.integerValue == 1)
                continue;

            const NSIndexPath * const indexPath = [self addContact:contact];
            [indiciesAdded addObject:indexPath];
        }
    }

    if (indiciesAdded.count > 0)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self.collectionView reloadData];
            [self checkEmpty];
        });
    }

    [self.contentLock unlock];

}

// must be called in mutex
- (NSIndexPath *) addContact: (PEXDbContact * const) contact
{
    [self.contactsWithInfo setObject:[[NSObject alloc] init] forKey:contact];
    [self setContactsRightPosition:contact];
    return [NSIndexPath indexPathForItem:self.contactsWithInfo.count - 1 inSection:0];
}

// i.e. MOVE - must be already in the list
- (void)setContactsRightPosition:(const PEXDbContact * const) contact
{
    // NOOP
}

- (void)registerCell
{
    // NOOP
}


// must call mutex
- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    PEXDbCursor * const cursor = [self loadAllContacts];

    NSMutableArray * const remnantIds = [[NSMutableArray alloc] initWithCapacity:[cursor getCount]];
    const int idPosition = [cursor getColumnIndex:DBCL(FIELD_ID)];

    while (cursor && [cursor moveToNext])
    {
        [remnantIds addObject:[cursor getInt64:idPosition]];
    }

    [self.contentLock lock];

    NSMutableArray * const removedIndicies = [[NSMutableArray alloc] init];

    for (int i = 0; i < self.contactsWithInfo.count; ++i)
    {
        const PEXDbContact * const contact = [self.contactsWithInfo keyAt:i];
        if (![remnantIds containsObject:contact.id])
        {
            [self.contactsWithInfo removePairAt:i];
            [removedIndicies addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            --i;
        }
    }

    if (removedIndicies.count > 0)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self.collectionView deleteItemsAtIndexPaths:removedIndicies];
        });
    }

    [self checkEmpty];
    [self.contentLock unlock];
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    [self.contentLock lock];

    [self updateContacts];

    [self.contentLock unlock];
}

// call in lock
- (void) updateContacts
{
    PEXDbCursor * const cursor = [self loadAllContacts];

    NSMutableArray * const indexPathsToUpdate = [[NSMutableArray alloc] init];
    NSMutableArray * const removedIndicies = [[NSMutableArray alloc] init];
    bool hiddenToShownOrOtherwise = false;

    while (cursor && [cursor moveToNext])
    {
        PEXDbContact * const dbContact = [PEXDbContact contactFromCursor:cursor];

        const NSUInteger index = [self getContactIndexById:dbContact.id];

        if (index != NSNotFound)
        {
            if (dbContact.hideContact.integerValue == 1)
            {
                hiddenToShownOrOtherwise = true;
                [self.contactsWithInfo removePairAt:index];
            }
            else
            {
                // UPDATE contact
                if (_showOffline)
                    dbContact.presenceStatusType = [NSNumber numberWithInt:PEXPbPresencePushPEXPbStatusOffline];

                PEXDbContact * const keyContact = [self.contactsWithInfo keyAt:index];

                if ([PEXGuiContactsItemView contact:keyContact needsUpdate:dbContact])
                {
                    [PEXGuiContactsItemView copyContactFrom:dbContact to:keyContact];
                    [self setContactsRightPosition:keyContact];
                    [indexPathsToUpdate addObject:[NSIndexPath indexPathForItem:index inSection:0]];
                }
            }
        }
        else
        {
            // add if was set to visible
            if (dbContact.hideContact.integerValue == 0)
            {
                // show previously hidden contact
                [self addContact:dbContact];
                hiddenToShownOrOtherwise = true;
            }
        }
    }

    if ((indexPathsToUpdate.count > 0) || hiddenToShownOrOtherwise)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self.collectionView reloadData];
            [self checkEmpty];
        });
    }

    if (removedIndicies.count > 0)
    {
        for (NSIndexPath * const path in removedIndicies)
            [self.contactsWithInfo removePairAt:path.item];

        dispatch_sync(dispatch_get_main_queue(), ^(void) {

            [self.collectionView deleteItemsAtIndexPaths:removedIndicies];
            [self checkEmpty];
        });
    }
}

- (void) setAllOffline
{
    NSMutableArray * const contactsToReallocate = [[NSMutableArray alloc] init];
    for (PEXDbContact * const contact in [self.contactsWithInfo getKeys])
    {
        if (contact.presenceStatusType.integerValue != PEXPbPresencePushPEXPbStatusOffline)
        {
            contact.presenceStatusType = @(PEXPbPresencePushPEXPbStatusOffline);
            [contactsToReallocate addObject:contact];
        }
    }

    for (PEXDbContact * const contact in contactsToReallocate)
    {
        [self setContactsRightPosition:contact];
    }
}


- (NSUInteger) getContactIndexById: (const NSNumber * const) idNum
{
    NSUInteger result = NSNotFound;
    for (NSUInteger i = 0; i < self.contactsWithInfo.count; ++i)
    {
        const PEXDbContact * const contact = [self.contactsWithInfo keyAt:i];
        if ([idNum isEqualToNumber:contact.id])
        {
            result = i;
            break;
        }
    }
    return result;
}

// PROTOCOL method in future
// SHIT FAST IMPLEMENTATION START

- (void) setEnabled:(const bool) enabled forContact:(const PEXDbContact * const) contact
{
    /*
    PEXGuiItemComposedView * const composed =
        [self.contactsWithViews objectForKey:contact];
    ((PEXGuiContactsItemView *)[composed getView]).enabled = enabled;
    [composed getDeleteView].enabled = enabled;
    */
}
// SHIT FAST IMPLEMENTATION END

- (PEXDbCursor *) loadAllContacts
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
            projection:[PEXDbContact getLightProjection]
            selection:nil
            selectionArgs:nil
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

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [self.contentLock lock];

    [[PEXAppPreferences instance] removeListener:self];

    [self.contentLock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // NOOP
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {

    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (section == 0) ?
            self.contactsWithInfo.count :
            0;
}


@end
