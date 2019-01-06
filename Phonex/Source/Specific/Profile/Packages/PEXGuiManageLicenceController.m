//
// Created by Matej Oravec on 09/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiManageLicenceController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiButtonMain.h"
#import "PEXDbContact.h"
#import "PEXGuiChatController.h"
#import "PEXGuiLoginController.h"
#import "PEXReport.h"
#import "PEXPackage.h"
#import "PEXPaymentRestoreRecord.h"
#import "PEXPackageItem.h"
#import "PEXPackageGenerator.h"
#import "PEXGuiLicenceStateView.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXGuiTextController.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiPoint.h"
#import "PEXGuiContentLoaderController_Protected.h"
#import "PEXGuiPackageView.h"
#import "PEXGuiPackageCell.h"
#import "PEXGuiPackageDetailController.h"
#import "PEXPackagesLoader.h"
#import "PEXGuiFactory.h"
#import "PEXPackageDeserializer.h"
#import "PEXGuiFullSizeBusyView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXPermissionsUtils.h"
#import "PEXPackageHumanDescription.h"
#import "PEXGuiButtonDIalogSecondary.h"
#import "PEXGuiBoughtPackagesController.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXPaymentManager.h"
#import "PEXGuiRestoreProductsExecutor.h"
#import "PEXService.h"
#import "PEXGuiTextView_Protected.h"
#import "UITextView+PEXPaddings.h"


static NSString * const PACKAGE_ITEM_CELL_IDENTIFIER = @"PACKAGE_ITEM_CELL_IDENTIFIER";

@interface PEXGuiManageLicenceController ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSArray * packages;
@property (nonatomic) NSArray * ownedPackages;

//

@property (nonatomic) PEXGuiClickableScrollView * V_scroller;

@property (nonatomic) UILabel *L_owned;
@property (nonatomic) PEXGuiReadOnlyTextView *L_owned_desc;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_currentState;
@property (nonatomic) PEXGuiButtonMain *B_details;


@property (nonatomic) PEXGuiPoint * line;

@property (nonatomic) UILabel *L_available;
@property (nonatomic) UICollectionView * collectionView;

///
@property (nonatomic) NSString * message;

@property (nonatomic) PEXPackagesLoader * itemsLoader;
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) PEXGuiPackageView * packageViewResizer;
@property (nonatomic) PEXGuiActivityIndicatorView * V_indicatorView;
@property (nonatomic) PEXGuiClassicLabel * L_loadingError;

@property (nonatomic) PEXGuiButtonMain * B_restore;
@property (nonatomic) PEXGuiBinaryDialogExecutor * restorePromptExecutor;
@property (nonatomic) PEXGuiRestoreProductsExecutor * restoreProductsExecutor;


@end

@implementation PEXGuiManageLicenceController {

}

+ (void) showOnParent: (UIViewController * const)parent
{
    PEXGuiManageLicenceController * const controller = [[PEXGuiManageLicenceController alloc] init];
    [controller showInNavigation:parent title:PEXStrU(@"L_manage_licence")];
}

- (void) itemsLoadSucceeded: (NSDictionary * const) products
{
    self.packages = [[products allValues] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSInteger s1 = [(PEXPackage*)a sortOrder];
        NSInteger s2 = [(PEXPackage*)b sortOrder];
        if (s1==s2){
            return NSOrderedSame;
        }
        return s1 < s2 ? NSOrderedAscending : NSOrderedDescending;
    }];

    [self itemsLoadingEnded];
}

- (void) itemsLoadingFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{

        [PEXGuiFactory showErrorTextBox:self
                               withText:PEXStr(@"txt_loading_packages_failed")];
    });

    [self itemsLoadingEnded];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.L_loadingError setHidden:false];
    });
}

- (void) itemsLoadingEnded
{
    self.itemsLoader = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showIndicator:false];
        [self.collectionView reloadData];
        [self collectionSizeChanged];
    });
}

- (void) showIndicator: (const bool) show
{
    [self.V_indicatorView setHidden:!show];

    if (show)
        [self.V_indicatorView startAnimating];
    else
        [self.V_indicatorView stopAnimating];

    [self.L_loadingError setHidden:true];
}

- (void)loadAvailablePackagesAsync
{
    self.itemsLoader = [[PEXPackagesLoader alloc] init];

    [self showIndicator:true];

    WEAKSELF;
    PEXProductsLoadFailed failureBlock = ^{
        [weakSelf itemsLoadingFailed];
    };

    PEXProductsLoadFinished successBlock = ^(NSDictionary *products) {
        [weakSelf itemsLoadSucceeded:products];
    };

    const bool success = [self.itemsLoader loadItemsCompletion:successBlock errorHandler:failureBlock];
    if (!success) {
        [self itemsLoadingFailed];
    }
}

- (void)initState
{
    [super initState];

    self.queue = dispatch_queue_create("iap items loading queue", nil);

    [self refreshServerPolicyAsync];
    [self loadCurrentPermissionsAsync];
    [self loadAvailablePackagesAsync];
}

- (void)refreshServerPolicyAsync
{
    dispatch_async(self.queue, ^{
        [[[PEXService instance] licenceManager] checkPermissionsAsync];
    });
}

- (void)loadCurrentPermissionsAsync
{
    dispatch_async(self.queue, ^{
        DDLogVerbose(@"Setting licence change listener.");
        [[[PEXService instance] licenceManager] addListenerAndSet:self];
    });
}

- (void)dealloc {
    [[[PEXService instance] licenceManager] removeListener:self];
}

- (void)dismissWithCompletion:(void (^)(void))completion animation:(void (^)(void))animation {

    [[[PEXService instance] licenceManager] removeListener:self];

    [super dismissWithCompletion:completion animation:animation];
}

- (void)permissionsChanged:(NSArray *const)permissions
{
    NSDictionary * const mergedPackages = [PEXPermissionsUtils mergePermissionsForSummary:permissions zeroIfNone:true];
    DDLogVerbose(@"Permissions has changed, merged permissions: %@", mergedPackages);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyPackages:[mergedPackages allValues]];
        [self layoutAll];
    });
}

- (void)onProductPurchaseFinished:(PEXPaymentTransactionRecord *)tsxRec success: (BOOL) success {
    DDLogVerbose(@"Purchase finished, success: %d", success);
    if (success) {
        WEAKSELF;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshServerPolicyAsync];
            [weakSelf loadAvailablePackagesAsync];
        });
    }
}

- (void) applyPackages: (NSArray * const) packages
{
    PEXGuiDetailsTextBuilder * const builder = [[PEXGuiDetailsTextBuilder alloc] init];
    NSArray * packagesToUse = packages;

    if (packagesToUse && packagesToUse.count)
    {
        // Sort according to sort order.
        packagesToUse = [packagesToUse sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSInteger s1 = [(PEXPackageItem*)a guiSortOrder];
            NSInteger s2 = [(PEXPackageItem*)b guiSortOrder];
            if (s1==s2){
                return NSOrderedSame;
            }
            return s1 < s2 ? NSOrderedAscending : NSOrderedDescending;
        }];

        [PEXPackageHumanDescription buildPackageDescription:packagesToUse builder:builder];
    }
    else
    {
        [builder appendFirstLabel:PEXStr(@"L_no_packages_owned")];
    }

    NSAttributedString * const attr = builder.result;

    [self.TV_currentState setAttributedText:attr];
}

- (id) initWithMessage: (NSString * const) message
{
    self = [super init];

    self.message = message;

    return self;
}

- (id) init
{
    self =  [self initWithMessage:PEXStr(@"txt_premium_general_info")];

    return self;
}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"GetPremium";


    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];

//    self.L_owned = [[PEXGuiClassicLabel alloc]
//            initWithFontSize:PEXVal(@"dim_size_medium")
//                   fontColor:PEXCol(@"light_gray_low")];
//    [self.V_scroller addSubview:self.L_owned];

    self.L_owned_desc = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.L_owned_desc];

    self.TV_currentState = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.TV_currentState];

    self.B_details = [[PEXGuiButtonMain alloc] init];
    [self.V_scroller addSubview:self.B_details];

    self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self.V_scroller addSubview:self.line];

    self.L_available = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self.V_scroller addSubview:self.L_available];

    self.collectionView= [[UICollectionView alloc] initWithFrame:self.view.frame
                                            collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    [self.V_scroller addSubview:self.collectionView];
    self.collectionView.backgroundColor = PEXCol(@"red_normal");

    self.packageViewResizer = [[PEXGuiPackageView alloc] init];

    self.V_indicatorView = [[PEXGuiActivityIndicatorView alloc] init];
    [self.V_scroller addSubview: self.V_indicatorView];

    self.L_loadingError = [[PEXGuiClassicLabel alloc] init];
    [self.V_scroller addSubview:self.L_loadingError];

    self.B_restore = [[PEXGuiButtonDIalogSecondary alloc] init];
    [self.V_scroller addSubview:self.B_restore];
}

- (void)initContent
{
    [super initContent];

//    self.L_owned.text = PEXStrU(@"L_owned_products");

    PEXGuiDetailsTextBuilder * const builder3 = [[PEXGuiDetailsTextBuilder alloc] init];
    [builder3 appendLabel:PEXStr(@"L_owned_products") first:YES fontSize:@(PEXVal(@"dim_size_medium")) fontColor:NULL];
    [builder3 appendValue:PEXStr(@"L_owned_products_desc")];
    [self.L_owned_desc setAttributedText:[builder3 result]];

    self.L_available.text = PEXStrU(@"L_available_products");
    self.L_loadingError.text = PEXStr(@"L_loading_error");

    [self.B_details setTitle:PEXStrU(@"L_bought_packages") forState:UIControlStateNormal];
    [self.B_restore setTitle:PEXStrU(@"L_restore") forState:UIControlStateNormal];
}

- (void)initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [self registerCell];

    self.collectionView.delaysContentTouches = false;
    [self.L_owned_desc setScrollEnabled:false];
    [self.TV_currentState setScrollEnabled:false];

    [self.B_restore addTarget:self action:@selector(restoreProducts) forControlEvents:UIControlEventTouchUpInside];
    [self.B_details addTarget:self action:@selector(showDetails) forControlEvents:UIControlEventTouchUpInside];
}

- (void) restoreProducts
{
    WEAKSELF;
    self.restorePromptExecutor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
    self.restorePromptExecutor.primaryButtonText = PEXStrU(@"B_continue");
    self.restorePromptExecutor.secondaryButtonText = PEXStrU(@"B_cancel");
    self.restorePromptExecutor.text = PEXStr(@"txt_payment_restore_prompt");
    self.restorePromptExecutor.primaryAction = ^{
        [weakSelf doRestoreProducts];
    };

    [self.restorePromptExecutor show];
}

- (void) doRestoreProducts {
    //[PEXReport logUsrButton:PEX_EVENT_BTN_ADD_CONTACT_ALIAS_CLICKED];
    DDLogVerbose(@"Restore products clicked");

    WEAKSELF;
    PEXPaymentManager * pmgr = [PEXPaymentManager instance];

    // If user is not able to make payments, show him warning and go on.
    if (![RMStore canMakePayments]){
        DDLogVerbose(@"User is not able to make payments");
        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showInfoTextBox:weakSelf
                                  withText:PEXStr(@"txt_restore_no_payment")
                                completion:^{[weakSelf.fullscreener dismissViewControllerAnimated:NO completion:^{}];}];
        });
        return;
    }

    PEXPaymentRestoreSuccessBlock successBlock = ^(PEXPaymentRestoreRecord *restoreRec) {
        DDLogVerbose(@"Restore finished with success");
        [weakSelf.restoreProductsExecutor onRestoreProductsFinished:restoreRec withSuccess:YES];
    };

    PEXPaymentRestoreFailureBlock failureBlock = ^(PEXPaymentRestoreRecord *restoreRec) {
        DDLogError(@"Restore failed, error: %@", restoreRec.error);
        [weakSelf.restoreProductsExecutor onRestoreProductsFinished:restoreRec withSuccess:NO];
    };

    // Progress monitor, indeterminate.
    self.restoreProductsExecutor = [[PEXGuiRestoreProductsExecutor alloc] init];
    self.restoreProductsExecutor.parentController = self;
    [self.restoreProductsExecutor show];

    // Start restoration.
    [pmgr restorePayment:successBlock failureBlock:failureBlock];
}

- (void) onRestoreProductsFinished: (PEXPaymentRestoreRecord *) restoreRec withSuccess: (BOOL) success {
    BOOL wasSuccess = success;
    NSString * text = success ? PEXStr(@"txt_restore_ok") : PEXStr(@"txt_restore_failed");

    if (restoreRec.tooEarly){
        text = PEXStr(@"txt_restore_too_early");
        wasSuccess = NO;
    } else if (!restoreRec.restoreReceiptOK){
        text = PEXStr(@"txt_restore_receipt_failed"); // bad password, connectivity?
        wasSuccess = NO;
    } else if (!restoreRec.restoreTransactionOK){
        text = PEXStr(@"txt_restore_transactions_failed");
        wasSuccess = NO;
    }

    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (wasSuccess){
            [PEXGuiFactory showInfoTextBox:weakSelf
                                   withText:text];
        } else {
            [PEXGuiFactory showErrorTextBox:weakSelf
                                   withText:text];
        }
    });
}

- (void) showDetails
{
    PEXGuiBoughtPackagesController * const controller = [[PEXGuiBoughtPackagesController alloc] init];
    [controller showInNavigation:self.fullscreener title:PEXStrU(@"L_bought_packages")];
}

- (void) registerCell
{
    [self.collectionView registerClass:[PEXGuiPackageCell class]
            forCellWithReuseIdentifier:PACKAGE_ITEM_CELL_IDENTIFIER];
}

- (void) layoutAll
{
    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat padding = PEXVal(@"dim_size_medium");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU moveToTop:self.L_owned_desc  withMargin: margin];
    [PEXGVU scaleHorizontally:self.L_owned_desc];
    [self.L_owned_desc setPaddingTop:0.0f left:padding bottom:0.0f rigth:padding];
    [self.L_owned_desc sizeToFit];

    [PEXGVU scaleHorizontally:self.TV_currentState];
    [self.TV_currentState sizeToFit];
    [PEXGVU move:self.TV_currentState below: self.L_owned_desc];

    [PEXGVU scaleHorizontally:self.B_details withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_details below:self.TV_currentState];

    [PEXGVU scaleHorizontally:self.B_restore withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_restore below:self.B_details withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.line];
    [PEXGVU move: self.line below: self.B_restore withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU move:self.L_available below:self.line withMargin:margin];
    [PEXGVU moveToLeft:self.L_available withMargin:margin];

    [PEXGVU move:self.collectionView below:self.L_available withMargin:margin];
    [PEXGVU scaleHorizontally:self.collectionView];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.itemSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiPackageView staticHeight]);

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];

    [PEXGVU setWidth: self.packageViewResizer to: self.collectionView.frame.size.width];

    [PEXGVU move: self.V_indicatorView below: self.L_available withMargin: margin];
    [PEXGVU centerHorizontally: self.V_indicatorView];

    [PEXGVU move: self.L_loadingError below: self.L_available withMargin: margin];
    [PEXGVU centerHorizontally: self.L_loadingError];

    if (![self.L_loadingError isHidden])
    {
        self.V_scroller.contentSize = CGSizeMake(self.V_scroller.contentSize.width,
                self.L_loadingError.frame.origin.y + self.L_loadingError.frame.size.height);
    }
    else
    {
        self.V_scroller.contentSize = CGSizeMake(self.V_scroller.contentSize.width,
                self.collectionView.frame.origin.y + self.collectionView.frame.size.height);
    }
}

- (void)initLayout
{
    [super initLayout];

    [self layoutAll];
}

- (void) collectionSizeChanged
{
    [PEXGVU setHeight:self.collectionView
                   to:[self.collectionView.collectionViewLayout collectionViewContentSize].height];
    [self layoutAll];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * result = nil;

    if ((indexPath.section == 0) &&
            (indexPath.item < self.packages.count))
    {
        const PEXPackage * const package =
                (PEXPackage *) self.packages[(NSUInteger) indexPath.item];

        if (package )
        {
            PEXGuiPackageCell * const cell = (PEXGuiPackageCell *)
                    [collectionView dequeueReusableCellWithReuseIdentifier:PACKAGE_ITEM_CELL_IDENTIFIER
                                                              forIndexPath:indexPath];

            if (cell)
            {
                // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
                cell.layer.shouldRasterize = YES;
                cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

                PEXGuiPackageView * const packageView = (PEXGuiPackageView *) [cell getSubview];

                [packageView applyPackage:package];

                for (UIGestureRecognizer * recognizer in packageView.gestureRecognizers) {
                    [packageView removeGestureRecognizer: recognizer];
                }

                [packageView addActionBlock:^{
                    PEXGuiPackageDetailController * ctrl = [[PEXGuiPackageDetailController alloc] initWithPackage:package];
                    ctrl.purchaseListener = self;
                    [ctrl showInNavigation:self title:PEXStrU(@"L_detail")];

                }];

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
    return self.packages ? ((section == 0) ?
            self.packages.count :
            0) : 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize result = CGSizeZero;

    const PEXPackage * const package = self.packages[indexPath.item];

    if (package)
    {
        [self.packageViewResizer applyPackage:package];

        [self.packageViewResizer layoutSubviews];
        result = self.packageViewResizer.frame.size;
    }

    return result;
}

@end