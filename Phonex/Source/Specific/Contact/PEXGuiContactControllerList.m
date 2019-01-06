//
//  PEXGuiContactControllerList.m
//  Phonex
//
//  Created by Matej Oravec on 18/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPreferenceChangedListener.h"
#import "PEXGuiPresenceCenter.h"
#import "PEXGuiContactControllerList.h"
#import "PEXGuiContactsController_Protected.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXGuiContactsListCell.h"
#import "PEXGuiPoint.h"
#import "PEXGuiAddContactWithUsernameController.h"
#import "PEXDbContactNotification.h"
#import "PEXGuiContactsNotificationsController.h"
#import "PEXReport.h"

@interface PEXGuiContactControllerList ()

@property (nonatomic) PEXGuiMenuItemView * B_addContact;
@property (nonatomic) PEXGuiMenuItemView * B_contactNotification;

@property (nonatomic) PEXGuiPoint * line;

@end

@implementation PEXGuiContactControllerList

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = nil; // manual reporting.

    self.B_addContact =
    [[PEXGuiMenuItemView alloc]
     initWithImage:[[PEXGuiCrossView alloc] initWithColor:PEXCol(@"light_gray_low")]
     labelText:PEXStrU(@"L_add_contact")];
    [self.mainView addSubview:self.B_addContact];

    self.B_contactNotification =
            [[PEXGuiMenuItemView alloc]
                    initWithImage:[[UIImageView alloc] initWithImage: PEXImg(@"contact_request")]
                        labelText:PEXStrU(@"L_contact_notifications")];
    [self.mainView addSubview:self.B_contactNotification];

    self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self.mainView addSubview:self.line];
}

- (void) showContactNotificationsButton
{
    [self showContactNotificationRoutine:true];
    [PEXGVU move:self.line below:self.B_contactNotification];
    [self resizeList];
}

- (void) hideContactNotificationsButton
{
    [self showContactNotificationRoutine:false];
    [PEXGVU move:self.line below:self.B_addContact];
    [self resizeList];
}

- (void) showContactNotificationRoutine: (const bool) show
{
    [self.B_contactNotification setEnabled:show];
    [self.B_contactNotification setHidden:!show];
}

- (void) resizeList
{
    [PEXGVU scaleHorizontally:self.collectionView];
    [PEXGVU scaleVertically:self.collectionView
                    between:[PEXGVU getLowerPoint:self.line]
                        and:self.mainView.frame.size.height];

    [self alignEmptyIndicator];
}

- (void) initState
{
    [super initState];

    [self hideContactNotificationsButton];

    [[[PEXAppState instance] contactNotificationManager] addListenerAndSet:self];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [[[PEXAppState instance] contactNotificationManager] removeListener: self];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_addContact];
    [PEXGVU moveToTop:self.B_addContact];

    [PEXGVU scaleHorizontally:self.B_contactNotification];
    [PEXGVU move:self.B_contactNotification below:self.B_addContact];

    [PEXGVU move: self.line below:self.B_addContact];
    [PEXGVU scaleHorizontally: self.line];

    [self resizeList];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_addContact addAction:self action:@selector(showAddContactDialog)];
    [self.B_contactNotification addAction:self action:@selector(showContactNotifications)];

    [[PEXGNFC instance] registerToContactNotificationsAndSet:self];
}

- (void)showContactNotifications
{
    PEXGuiContactsNotificationsController * controller =
            [[PEXGuiContactsNotificationsController alloc] init];
    [PEXReport logUsrButton:PEX_EVENT_BTN_SHOW_CONTACT_NOTIFICATIONS];
    [PEXGAU showInNavigation: controller in: self title: PEXStrU(@"L_contact_requests")];
}

- (void) showAddContactDialog
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACTS_ADD_CONTACT];
    [PEXGAU showInNavigation: [[PEXGuiAddContactWithUsernameController alloc] init]
    in: self
    title: PEXStrU(@"L_add_new_contact")];

    /*
    PEXGuiAddContactWithUsernameController

    PEXGuiAddContactExecutor *executor = [[PEXGuiAddContactExecutor alloc]
                                          initWithParentController:self];

    [executor showAddContact];
    */
}

// i.e. MOVE - must be already in the list
- (void)setContactsRightPosition:(const PEXDbContact * const) contact
{
    NSUInteger i = 0;

    for (i = 0; i < self.contactsWithInfo.count ; ++i)
    {
        const PEXDbContact * const c = [self.contactsWithInfo keyAt:i];

        if ([c isEqualToContact:contact])
        {
            continue;
        }

        const PEX_GUI_PRESENCE positionedContactGuiPresence =
        [PEXGuiPresenceCenter translatePresenceState:[contact.presenceStatusType integerValue]];
        const PEX_GUI_PRESENCE iteratedContactGuiPresence =
        [PEXGuiPresenceCenter translatePresenceState:[c.presenceStatusType integerValue]];

        if ((iteratedContactGuiPresence > positionedContactGuiPresence) ||
            ((iteratedContactGuiPresence == positionedContactGuiPresence &&
              [c.displayName compare:contact.displayName options:NSCaseInsensitiveSearch] == NSOrderedDescending)))
        {
            [self.contactsWithInfo moveForKey:contact to:i];
            break;
        }
    }
}

- (void) registerCell
{
    [self.collectionView registerClass:[PEXGuiContactsListCell class]
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
            PEXGuiContactsListCell * const cell =
                    [collectionView dequeueReusableCellWithReuseIdentifier:CONTACT_VIEW_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

                PEXGuiItemComposedView * const composed = [cell getSubview];
                PEXGuiContactsItemView * const contactView = (PEXGuiContactsItemView *) [composed getView];

                [contactView applyContact:contact];
                [contactView setShowUsername:_showSipForContact];


                // we dont want to remove pan recognizer
                if (contactView.gestureRecognizers.count > 1) {
                    [contactView removeGestureRecognizer:
                            contactView.gestureRecognizers.lastObject];
                }
                [contactView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_POPUP];
                    [self showContactPopUp:contact];
                }];

                [composed.getDeleteView clearActions];
                [composed.getDeleteView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_DELETE];
                    PEXGuiBinaryDialogExecutor * const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
                    executor.primaryButtonText = PEXStrU(@"B_delete");
                    executor.secondaryButtonText = PEXStrU(@"B_cancel");
                    executor.text = PEXStr(@"txt_delete_contact_question");
                    executor.primaryAction = ^{
                        [self callRemoveContact:contact];
                    };
                    [executor show];

                }];

                [composed reset];

                result = cell;
            }
        }
    }

    return result;
}

- (void) showContactPopUp: (const PEXDbContact * const) contact
{
    PEXGuiActionOnContactExecutor * const executor = [[PEXGuiActionOnContactExecutor alloc] init];
    [executor executeWithContact:contact parentController:self];
}

- (void) callRemoveContact: (const PEXDbContact * const) contact
{
    [self setEnabled:false forContact:contact];
    PEXContactRemoveExecutor * const executor = [[PEXContactRemoveExecutor alloc] initWithController:self contactToRemove:contact];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [executor execute];
    });
}

- (void)countChanged:(NSArray * const) notifications {

    const int count = notifications.count;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (count > 0)
            [self showContactNotificationsButton];
        else
            [self hideContactNotificationsButton];

        [self setContactNotificationLabel:count];
    });
}

- (void) setContactNotificationLabel: (const int) count
{
    [self.B_contactNotification setLabelText:
            [NSString stringWithFormat:@"%@: %d", PEXStr(@"L_contact_requests"), count]];
}

- (void)contactNotificationCountChanged:(const int)count {

    if (count)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.B_contactNotification highlighted];
        });
    else
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.B_contactNotification normal];
        });
}

@end
