//
//  PEXGuiContactsSelectController.m
//  Phonex
//
//  Created by Matej Oravec on 18/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPresenceCenter.h"
#import "PEXPreferenceChangedListener.h"
#import "PEXGuiContactsSelectController.h"
#import "PEXGuiContactsController_Protected.h"

#import "PEXGuiSelectableContactsItemView.h"
#import "PEXGuiContactsSelectCell.h"
#import "PEXReport.h"

@interface PEXGuiContactsSelectController ()

@property (nonatomic) PEXContactSelectManager * manager;

@end

@implementation PEXGuiContactsSelectController

- (id) initWithManager: (PEXContactSelectManager * const) manager
{
    self = [super init];

    self.manager = manager;

    return self;
}

// i.e. MOVE - must be already in the list
- (void)setContactsRightPosition:(const PEXDbContact * const) contact
{
    NSUInteger i;

    for (i = 0; i < self.contactsWithInfo.count ; ++i)
    {
        const PEXDbContact * const c = [self.contactsWithInfo getKeys][i];

        if ([c isEqualToContact:contact])
            continue;

        if ([c.displayName compare:contact.displayName options:NSCaseInsensitiveSearch] ==
                NSOrderedDescending)
        {
            [self.contactsWithInfo moveForKey:contact to:i];
            break;
        }
    }
}

- (void) postload
{
    [super postload];

    [self.manager addListener:self];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.manager deleteListener:self];
    self.manager = nil;

    [super dismissViewControllerAnimated:flag completion:completion];
}

// LISTENER STUFF

- (void) contactAdded: (const PEXDbContact * const) contact
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
    });
}

- (void) contactRemoved: (const PEXDbContact * const) contact
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
    });
}

- (void) clearSelection
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
    });
}

- (void) fillIn: (NSArray * const) contacts
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
    });
}

- (void) registerCell
{
    [self.collectionView registerClass:[PEXGuiContactsSelectCell class]
            forCellWithReuseIdentifier:CONTACT_VIEW_IDENTIFIER];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * result = nil;

    if ((indexPath.section == 0) &&
            (indexPath.item < self.contactsWithInfo.count))
    {
        const PEXDbContact * const contact = [self.contactsWithInfo keyAt:indexPath.item];

        if (contact)
        {
            PEXGuiContactsSelectCell * const cell =
                    [collectionView dequeueReusableCellWithReuseIdentifier:CONTACT_VIEW_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;


                PEXGuiSelectableContactsItemView * const contactView = (PEXGuiSelectableContactsItemView *) [cell getSubview];
                __weak __typeof(contactView) weakContactView = contactView;
                WEAKSELF;

                [contactView applyContact:contact];
                [contactView setShowUsername:_showSipForContact];

                [contactView clearActions];
                [contactView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_SELECT];
                    if (weakContactView.isSelected)
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [weakSelf.manager removeContact:contact];
                        });
                    else
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [weakSelf.manager addContact:contact];
                        });
                }];

                [contactView setIsSelected:
                        ([[self.manager getSelected] containsObject:contact])];

                result = cell;
            }
        }
    }

    return result;
}

- (void)initGuiComponents {
    [super initGuiComponents];
    self.screenName = @"ContactsSelect";
}

@end
