//
//  PEXGuiMessagesController.m
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiChatsController.h"
#import "PEXGuiControllerContentObserver_Protected.h"

#import "PEXDbAppContentProvider.h"

#import "PEXGuiLinearContainerView.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiChat.h"
#import "PEXGuiChat.h"
#import "PEXUser.h"
#import "PEXGuiChatItemView.h"
#import "PEXGuiChatController.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiItemComposedView.h"
#import "PEXDbContact.h"

#import "PEXDbContact.h"

#import "PEXRefDictionary.h"

#import "PEXGuiNotificationCenter.h"

#import "PEXMessageManager.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiImageView.h"

#import "PEXGuiMessageComposerController.h"
#import "PEXGuiBroadcastNavigationController.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXGuiPoint.h"
#import "PEXChatsManager.h"
#import "PEXArrayUtils.h"
#import "PEXGuiChatCell.h"
#import "PEXReport.h"

static NSString * const CHAT_CELL_IDENTIFIER = @"chatItemCellIdentifier";

@interface PEXGuiChatsController ()

@property (nonatomic) UICollectionView * collectionView;

@property (nonatomic) PEXGuiMenuItemView * B_composeBroadcastMessage;
@property (nonatomic) PEXGuiPoint * line;

@end

@implementation PEXGuiChatsController

- (const UIView *) getContentView
{
    return self.collectionView;
}

- (int) getItemsCount
{
    return [self.manager getCount];
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = nil; // manual reporting.

    self.B_composeBroadcastMessage =
    [[PEXGuiMenuItemView alloc]
     initWithImage:  [[PEXGuiImageView alloc] initWithImage:PEXImg(@"broadcast")]
     labelText:PEXStrU(@"L_compose_broadcast_message")];
    [self.mainView addSubview:self.B_composeBroadcastMessage];

    self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self.mainView addSubview:self.line];

    self.collectionView= [[UICollectionView alloc] initWithFrame:self.view.frame
                                            collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    [self.mainView addSubview:self.collectionView];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_composeBroadcastMessage];
    [PEXGVU moveToTop:self.B_composeBroadcastMessage];

    [PEXGVU move:self.line below:self.B_composeBroadcastMessage];
    [PEXGVU scaleHorizontally:self.line];

    [PEXGVU scaleHorizontally:self.collectionView];
    [PEXGVU scaleVertically:self.collectionView
                    between:[PEXGVU getLowerPoint:self.line]
                        and:self.mainView.frame.size.height];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.itemSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiChatItemView staticHeight]);

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void) initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.delaysContentTouches = false;
    [self.collectionView registerClass:[PEXGuiChatCell class]
            forCellWithReuseIdentifier:CHAT_CELL_IDENTIFIER];

    [self.B_composeBroadcastMessage addAction:self action:@selector(composeBroadcastMessage)];
}

- (void) composeBroadcastMessage
{
    PEXGrandSelectionManager * grandManager = [[PEXGrandSelectionManager alloc] init];

    PEXGuiMessageComposerController * const composer =
    [[PEXGuiMessageComposerController alloc] init];

    PEXGuiBroadcastNavigationController * const navi =
    [[PEXGuiBroadcastNavigationController alloc] initWithViewController:composer composerController:composer grandManager:grandManager];

    [PEXReport logUsrButton:PEX_EVENT_BTN_COMPOSE_BROADCAST_MESSAGE];
    [navi prepareOnScreen:self];
    [navi show:self];
}

- (void) clearContent
{[super clearContent];

    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self largeUpdate];
    });
}

- (void) loadContent
{
    [self.manager setController:self];

    [self checkEmpty];
}

// PROTOCOL method in future
// SHIT FAST IMPLEMENTATION START

/*
- (void) setEnabled:(const bool) enabled forChat:(const PEXGuiChat * const) chat
{
    PEXGuiItemComposedView * const composed =
    [self.chatsWithViews objectForKey:chat];
    ((PEXGuiChatItemView *)[composed getView]).enabled = enabled;
    [composed getDeleteView].enabled = enabled;
}
*/

- (void)updateItemsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)removeItemsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)addItemsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    } completion:nil];
}

- (void)moveItemFrom:(NSIndexPath *const)from to: (NSIndexPath * const) to
{
    [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
}

- (void) largeUpdate
{
    [self.collectionView reloadData];
}

#pragma collectioView

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * result = nil;

    if ((indexPath.section == 0) && (indexPath.item < [self getItemsCount]))
    {
        const PEXGuiChat * const item = [self.manager getItemAt:indexPath.item];

        if (item)
        {
            PEXGuiChatCell * const cell =
                    [collectionView dequeueReusableCellWithReuseIdentifier:CHAT_CELL_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

                PEXGuiItemComposedView * const composed = [cell getSubview];
                PEXGuiChatItemView * const view = (PEXGuiChatItemView *) [composed getView];

                [view applyChat:item];

                if (item.highlighted)
                    [view highlighted];
                else
                    [view normal];

                // we dont want to remove pan recognizer
                if (view.gestureRecognizers.count > 1) {
                    [view removeGestureRecognizer: view.gestureRecognizers.lastObject];
                }

                [view addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_CHATS_ACTION];
                    [self.manager actionOnItem:item];
                }];

                [composed.getDeleteView clearActions];
                [composed.getDeleteView addActionBlock:^{
                    [PEXReport logUsrButton:PEX_EVENT_BTN_CHATS_REMOVE];
                    [self.manager callRemoveItem:item];
                }];

                [composed reset];

                result = cell;
            }
        }
    }

    return result;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {

    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (section == 0) ?
            [self getItemsCount] :
            0;
}

@end
