//
//  PEXGuiCallLogsController.m
//  Phonex
//
//  Created by Matej Oravec on 08/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCallsController.h"
#import "PEXGuiControllerContentObserver_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXRefDictionary.h"
#import "PEXDbCallLog.h"
#import "PEXDbAppContentProvider.h"
#import "PEXGuiCallLogItemView.h"
#import "PEXCallsManager.h"
#import "PEXGuiCallLog.h"
#import "PEXGuiItemComposedView.h"
#import "PEXCallLogManager.h"
#import "PEXGuiCrossView.h"
#import "PEXDbContact.h"
#import "PEXGuiFactory.h"

#import "PEXGuiCallManager.h"
#import "PEXGuiActionOnContactExecutor.h"
#import "PEXGuiImageView.h"
#import "PEXGuiPoint.h"
#import "PEXCallsManager.h"
#import "PEXGuiCallLogCell.h"
#import "PEXReport.h"


static NSString * const CALL_LOG_CELL_IDENTIFIER = @"callLogCellIdentifier";

@interface PEXGuiCallsController ()

@property (nonatomic) UICollectionView * collectionView;

@property (nonatomic) PEXGuiMenuItemView * B_clearCallLogs;
@property (nonatomic) PEXGuiController * showedController;
@property (nonatomic) PEXGuiPoint * line;

@end

@implementation PEXGuiCallsController

- (const UIView *) getContentView
{
    return self.mainView;
}

- (int) getItemsCount
{
    return [self.manager getCount];
}

- (void) secondaryButtonClicked
{
    [self hideShowedController:nil];
}

- (void) primaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_DELETE_CALLOG_ENTRY];
    [self hideShowedController:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PEXDbAppContentProvider instance]
                    delete: [PEXDbCallLog getURI]
                 selection: nil //[NSString stringWithFormat:@"%@ > 0", PEX_DBCLOG_FIELD_ID]
             selectionArgs: nil];
        });
    }];
}

- (void) hideShowedController: (void (^) (void)) completion
{
    [self.showedController dismissViewControllerAnimated:true completion:completion];
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = nil; // manual reporting.

    self.B_clearCallLogs =
    [[PEXGuiMenuItemView alloc]
     initWithImage:  [[PEXGuiImageView alloc] initWithImage:PEXImg(@"trash")]
     labelText:PEXStrU(@"L_clear_call_logs")];
    [self.mainView addSubview:self.B_clearCallLogs];

    self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self.mainView addSubview:self.line];

    self.collectionView= [[UICollectionView alloc] initWithFrame:self.view.frame
                                            collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    [self.mainView addSubview:self.collectionView];

}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_clearCallLogs];
    [PEXGVU moveToTop:self.B_clearCallLogs];

    [PEXGVU move:self.line below:self.B_clearCallLogs];
    [PEXGVU scaleHorizontally:self.line];

    [PEXGVU scaleHorizontally:self.collectionView];
    [PEXGVU scaleVertically:self.collectionView
                    between:[PEXGVU getLowerPoint:self.line]
                            and:self.mainView.frame.size.height];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.itemSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiCallLogItemView staticHeight]);

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
    [self.collectionView registerClass:[PEXGuiCallLogCell class]
            forCellWithReuseIdentifier:CALL_LOG_CELL_IDENTIFIER];

    [self.B_clearCallLogs addAction:self action:@selector(showClearAllCallLogs)];
}

- (void) showClearAllCallLogs
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CLEAR_ALL_CALLLOGS];
    self.showedController = [PEXGuiFactory showBinaryDialog:self
                                                   withText:PEXStr(@"txt_clear_all_call_logs")
                                                   listener:self
                                              primaryAction:PEXStrU(@"B_delete")
                                            secondaryAction:nil];
}

// SHIT FAST IMPLEMENTATION START
// LIST tools

- (void) clearContent
{
    [super clearContent];

    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self largeUpdate];
    });
}

- (void) loadContent
{
    [self.manager setController:self];

    [self checkEmpty];
}

/*
- (void) setEnabled:(const bool) enabled forCallLog:(const PEXGuiCallLog * const) guiCallLog
{
    PEXGuiItemComposedView * const composed =
    [self.callLogsWithViews objectForKey:guiCallLog];
    ((PEXGuiCallLogItemView *)[composed getView]).enabled = enabled;
    [composed getDeleteView].enabled = enabled;
}
*/

- (void) updateCallLogsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void) removeCallLogsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void) addCallLogsForIndexPaths: (NSArray * const) indexPaths
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    } completion:nil];
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
        const PEXGuiCallLog * const guiCallLog = [self.manager getItemAt:indexPath.item];

        if (guiCallLog)
        {
            PEXGuiCallLogCell * const cell =
                    [collectionView dequeueReusableCellWithReuseIdentifier:CALL_LOG_CELL_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

                PEXGuiItemComposedView * const composed = [cell getSubview];
                PEXGuiCallLogItemView * const callLogView = (PEXGuiCallLogItemView *) [composed getView];

                [callLogView applyGuiCallLog:guiCallLog];

                if (guiCallLog.highlighted)
                    [callLogView highlighted];
                else
                    [callLogView normal];

                // we dont want to remove pan recognizer
                if (callLogView.gestureRecognizers.count > 1) {
                    [callLogView removeGestureRecognizer: callLogView.gestureRecognizers.lastObject];
                }

                [callLogView addActionBlock:^{
                    [self.manager actionOnCallLog:guiCallLog];
                }];

                [composed.getDeleteView clearActions];
                [composed.getDeleteView addActionBlock:^{
                    [self.manager callRemoveCallLog:guiCallLog];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (section == 0) ?
            [self getItemsCount] :
            0;
}

@end
