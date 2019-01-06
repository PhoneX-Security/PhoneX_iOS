//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsNotificationsController.h"

#import "PEXGuiContentLoaderController_Protected.h"
#import "PEXDbContactNotification.h"
#import "PEXGuiContactNotificationView.h"
#import "PEXGuiContactNotificationCell.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXDbAppContentProvider.h"
#import "PEXGuiAddContactWithUsernameController.h"
#import "PEXReport.h"

static NSString * const CONTACT_NOTIFICATION_VIEW_IDENTIFIER = @"contact_notification_view";

@interface PEXGuiContactsNotificationsController ()

@property (nonatomic) UICollectionView * collectionView;
@property (nonatomic) NSMutableArray * contactNotifications;

@end

@implementation PEXGuiContactsNotificationsController {

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
    return self.contactNotifications.count;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ContactNotification";

    self.collectionView= [[UICollectionView alloc] initWithFrame:self.view.frame
                                            collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];

    [self.mainView addSubview:self.collectionView];
}

- (void)initState {

    [super initState];

    [[PEXGNFC instance] contactNotificationsWereShown];
}

- (void) initLayout
{
    [super initLayout];

    // COLLECTION VIEW
    [PEXGVU scaleFull:self.collectionView];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.itemSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiContactNotificationView staticHeight]);

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void)initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [self.collectionView registerClass:[PEXGuiContactNotificationCell class]
            forCellWithReuseIdentifier:CONTACT_NOTIFICATION_VIEW_IDENTIFIER];

    self.collectionView.delaysContentTouches = false;
}

- (void) loadContent{

    self.contactNotifications = [[NSMutableArray alloc] init];

    PEXContactNotificationManager * const manager = [[PEXAppState instance] contactNotificationManager];
    [manager addListenerAndSet:self];

    [self checkEmpty];
}

- (void) clearContent
{
    [super clearContent];

    [self.contactNotifications removeAllObjects];

    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
        [self checkEmpty];
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [[[PEXAppState instance] contactNotificationManager] removeListener:self];
    [[PEXGNFC instance] contactNotificationsWereHidden];

    [super dismissViewControllerAnimated:flag completion:completion];
}


- (void)countChanged:(NSArray *const)notifications {

    dispatch_sync(dispatch_get_main_queue(), ^{

        self.contactNotifications = [notifications mutableCopy];
        [self.collectionView reloadData];

        [self checkEmpty];
    });
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * result = nil;

    if ((indexPath.section == 0) &&
            (indexPath.item < self.contactNotifications.count))
    {
        const PEXDbContactNotification * const notification =
                [self.contactNotifications objectAtIndex:indexPath.item];

        if (notification)
        {
            PEXGuiContactNotificationCell * const cell =
                    [collectionView dequeueReusableCellWithReuseIdentifier:CONTACT_NOTIFICATION_VIEW_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

                PEXGuiItemComposedView * const composed = [cell getSubview];
                PEXGuiContactNotificationView * const notificationView =
                    (PEXGuiContactNotificationView *) [composed getView];

                [notificationView applyNotification:notification];

                // we dont want to remove pan recognizer
                if (notificationView.gestureRecognizers.count > 1) {
                    [notificationView removeGestureRecognizer:
                            notificationView.gestureRecognizers.lastObject];
                }

                [notificationView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_PAIRING_ACCEPT];
                    [self showAccepContact:notification];
                }];

                [composed.getDeleteView clearActions];
                [composed.getDeleteView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_PAIRING_DELETE];
                    PEXGuiBinaryDialogExecutor * const executor =
                            [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];

                    executor.primaryButtonText = PEXStrU(@"B_delete");
                    executor.secondaryButtonText = PEXStrU(@"B_cancel");
                    executor.text = [NSString stringWithFormat:@"%@\n\n%@",
                                    notification.username, PEXStr(@"txt_delete_contact_notification_question")];

                    executor.primaryAction = ^{
                        [self callRemoveNotification:notification];
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

- (void)showAccepContact:(PEXDbContactNotification * const)notification
{
    [[PEXGNFC instance] contactNotificationsWereHidden];

    PEXGuiAddContactWithUsernameController * const controller =
            [[PEXGuiAddContactWithUsernameController alloc] init];

    controller.preparedUsername = notification.username;
    controller.completionEx = ^{[[PEXGNFC instance] contactNotificationsWereShown];};

    [PEXGAU showInNavigation: controller
                          in: self
                       title: PEXStrU(@"L_add_new_contact")];
}

- (void) callRemoveNotification: (const PEXDbContactNotification * const) notification
{
    [PEXContactNotificationManager removeNotification:notification];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {

    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (section == 0) ?
            self.contactNotifications.count :
            0;
}

@end