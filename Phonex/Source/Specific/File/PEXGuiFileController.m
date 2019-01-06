//
//  PEXGuiFileController.m
//  Phonex
//
//  Created by Matej Oravec on 21/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileController.h"
#import "PEXGuiFileController_Protected.h"

#import <ImageIO/ImageIO.h>

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiFileView.h"

#import "PEXGuiImageView.h"

#import "PEXGuiFullArrowUp.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiFileViewCell.h"
#import "PEXReport.h"

static const int PEX_MAXIMUM_FILES_TO_LOAD = 100;
static const int PEX_MAXIMUM_LOADING_THREADS = 1;

static NSString * const s_itemIdentifier = @"photoCell";

@interface PEXGuiFileController () {
}

@property (nonatomic) PEXRefDictionary * cellsAndOperations;
@property (nonatomic) NSLock * lock;
@property (nonatomic) NSLock * cellLock;

@property (nonatomic) PEXGuiFileControllerVisitor * visitor;
@property (nonatomic) PEXGuiMenuItemView * B_goUp;

@property (nonatomic) UICollectionView * collectionView;
@property (nonatomic) NSMutableArray *itemHelpers;
@property (nonatomic) NSCache* fileDataCache;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL loadingData;

@end

@implementation PEXGuiFileController

- (void)tweakView:(PEXGuiFileView *const)data
{
    // DO NOTHING
}

- (id) initWithVisitor: (PEXGuiFileControllerVisitor * const) visitor;
{
    self = [super init];

    self.itemHelpers = [[NSMutableArray alloc] init];

    self.lock = [[NSLock alloc] init];
    self.cellLock = [[NSLock alloc] init];
    self.cellsAndOperations = [[PEXRefDictionary alloc] init];
    self.fileDataCache = [[NSCache alloc] init];
    self.fileDataCache.countLimit = PEX_MAXIMUM_FILES_TO_LOAD;
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = PEX_MAXIMUM_LOADING_THREADS;
    self.loadingData = NO;

    self.visitor = visitor;
    visitor.controller = self;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"File";

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];

    [self.mainView addSubview:self.collectionView];

    self.B_goUp = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiFullArrowUp alloc] initWithColor:PEXCol(@"light_gray_low")]
                                                    labelText:PEXStrU(@"L_go_up")];
    [self.mainView addSubview:self.B_goUp];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_goUp];



    [PEXGVU scaleVertically:self.collectionView between:self.B_goUp.frame.origin.y + self.B_goUp.frame.size.height
                        and:self.mainView.frame.size.height];
    [PEXGVU scaleHorizontally:self.collectionView];


    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.itemSize = CGSizeMake(self.collectionView.frame.size.width, [PEXGuiFileView staticHeight]);
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void) initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    //self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[PEXGuiFileViewCell class]
            forCellWithReuseIdentifier:s_itemIdentifier];
    self.collectionView.delaysContentTouches = false;

    PEXGuiFileController * const weakSelf = self;
    [self.B_goUp addActionBlock:^{
        // TODO move to navigator?
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_UP];
        [weakSelf dismissViewControllerAnimated:false completion:nil];
    }];
}

- (void) postload
{
    [super postload];

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.visitor postLoad];
    });

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self checkEmpty];
    });
}

///////////////

- (void) clearContent
{
    [super clearContent];
    DDLogVerbose(@"FileControllerClearContent");
    [self.itemHelpers removeAllObjects];
    [self datasetChanged];
}

- (void) datasetChanged {
    [self.operationQueue cancelAllOperations];
    DDLogVerbose(@"Dataset changed");
    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self.fileDataCache removeAllObjects];
        [self.collectionView reloadData];
    });
}

- (void)dataLoadStarted{
    self.loadingData = YES;
}

- (void)dataLoadFinished{
    self.loadingData = NO;
    [self datasetChanged];
}

- (void)selectionChanged
{
    [self.collectionView reloadData];
}

- (const UIView *) getContentView
{
    return self.collectionView;
}

- (int) getItemsCount
{
    return self.itemHelpers.count;
}

#pragma UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self getItemsCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PEXGuiFileViewCell * const cell = [collectionView dequeueReusableCellWithReuseIdentifier:s_itemIdentifier
                                                                           forIndexPath:indexPath];

    // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

    [cell.getFileView applyAsset:nil];

    PEXFileData * const data = [self.fileDataCache objectForKey:indexPath];
    if (data)
    {
        [self setData:data forCell:cell];
    }
    else if (!self.loadingData)
    {
        // If data loading is in the progress, do not start background task, will be soon obsolete.
        // Generation will be triggered on data loading finishes.
        NSIndexPath * const indexPathBackground = [indexPath copy];
        if (indexPathBackground.row < 0){
            DDLogError(@"Negative row returned");
            return cell;
        }

        NSURL * fileUrl = ((PEXGuiItemHelper *)self.itemHelpers[(NSUInteger)indexPathBackground.row]).url;

        WEAKSELF;
        NSBlockOperation * const operation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation * const weakOperation = operation;
        [operation addExecutionBlock:
        ^(void) {
            if (weakOperation.isCancelled) return;

            // Load image on a non-ui-blocking thread
            PEXFileData * const loadedData = [PEXFileData fileDataFromUrl:fileUrl];

            if (weakOperation.isCancelled) return;

            [weakSelf.fileDataCache setObject:loadedData forKey:indexPathBackground];
            dispatch_sync(dispatch_get_main_queue(), ^(void) {

                if (weakOperation.isCancelled) return;

                [weakSelf setData:loadedData
                          forCell:(PEXGuiFileViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPathBackground]];
            });
        }];

        const NSUInteger index = [[self.cellsAndOperations getKeys] indexOfObject:cell];

        if (index != NSNotFound)
        {
            NSOperation * const oldOperation = [self.cellsAndOperations getObjects][index];
            [oldOperation cancel];
        }

        [self.cellsAndOperations setObject:operation forKey:cell];
        [self.operationQueue addOperation:operation];
    }

    return cell;
}

- (void) setData: (PEXFileData * const) data forCell: (PEXGuiFileViewCell * const) cell
{
    [self.cellLock lock];
    PEXGuiFileView * const fileView = [cell getFileView];
    [fileView applyAsset:data];
    [self.visitor specifyFileView:fileView withData:data];
    [self tweakView:fileView];
    [self.cellLock unlock];
}
- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // cancel list loading
    _cancel = true;

    //cancel independent filedata loaders
    [self.operationQueue cancelAllOperations];

    [self.visitor onDismiss];
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)addFileHelper: (const PEXGuiItemHelper * const) fileHelper;
{
    static NSComparator comparator = ^(const PEXGuiItemHelper * const data1, const PEXGuiItemHelper * const data2)
    {
        return [PEXDateUtils date:data1.date isOlderThan:data2.date] ?
                NSOrderedDescending :
                NSOrderedAscending;
    };

    NSUInteger newIndex = [self.itemHelpers indexOfObject:fileHelper
                                            inSortedRange:(NSRange) {0, self.itemHelpers.count}
                                                  options:NSBinarySearchingInsertionIndex
                                          usingComparator:comparator];

    [self.itemHelpers insertObject:fileHelper atIndex:newIndex];

    // Insertion of a new item has to clear cache as it would contain invalid entries, cached for wrong indexpath.
    // This leads to invalid listing with some entries not shown IPH-473
    // IPH-473: if data loading is not in progress, we need to signalize changed dataset to regenerate the view.
    if (!self.loadingData){
        DDLogWarn(@"New item added when not in loading phase, regenerate view");
        [self datasetChanged];
    }
}

@end

@implementation PEXGuiItemHelper

@end