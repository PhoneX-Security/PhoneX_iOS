//
//  PEXGuiChatController.m
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiChatController.h"
#import "PEXGuiControllerContentObserver_Protected.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiLinearContainerView.h"
#import "PEXGuiChat.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXUser.h"
#import "PEXGuiMessageTextOnlyView.h"
#import "PEXGuiMessageBreakerView.h"
#import "PEXGuiMessageTextComposerView.h"
#import "PEXGuiClickableScrollView.h"
#import "PEXGuiLinearScalingView.h"
#import "PEXGuiButtonMain.h"
#import "PEXMessageStatus.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiItemComposedView.h"
#import "PEXStringUtils.h"
#import "PEXDbContact.h"
#import "PEXRefDictionary.h"
#import "PEXDbAppContentProvider.h"
#import "PEXMessageManager.h"
#import "PEXGuiChatNavigationController.h"

#import "PEXUserPrivate.h"
#import "PEXGuiCallManager.h"

#import "PEXGuiCentricButtonView.h"
#import "PEXGuiImageView.h"

#import "PEXGuiArrowDown.h"

#import "PEXGuiMessageDetailController.h"
#import "PEXGuiFactory.h"

#import "PEXGuiImageView.h"
#import "PEXGuiCentricButtonMain.h"

#import "PEXGuiMessageFileView.h"
#import "PEXFtTransferManager.h"
#import "PEXGuiContextMenuViewController.h"
#import "PEXGuiDialogBinaryListener.h"

#import "PEXMessageUtils.h"
#import "PEXGrandSelectionManager.h"
#import "PEXGuiMessageComposerController.h"
#import "PEXGuiBroadcastNavigationController.h"
#import "PEXGuiContextItemHolder.h"
#import "PEXGuiFileCategoriesController.h"
#import "PEXGuiFileSelectNavigationController.h"
#import "PEXDbReceivedFile.h"
#import "PEXGuiFileUtils.h"
#import "PEXGuiShieldManager.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXGuiClassicLabel.h"
#import "PEXDhKeyHelper.h"
#import "PEXGuiMessageCell.h"
#import "PEXGuiMessageTextOnlyCell.h"
#import "PEXGuiMessageFileCell.h"
#import "PEXGuiMessageSeenView.h"
#import "Flurry.h"
#import "PEXGuiBackgroundView.h"
#import "PEXLicenceInfo.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXLinearDictionary.h"
#import "PEXReport.h"
#import "PEXService.h"
#import "PEXInTextData.h"
#import "PEXInTextDataLink.h"
#import "PEXInTextDataPhoneNumber.h"
#import "PEXConcurrentRingQueue.h"
#import "PEXUtils.h"
#import "PEXMessageModel.h"
#import "PEXStopwatch.h"
#import "PEXGuiChatLinkActivity.h"

static const int COMPOSER_MAX_ADDITIONAL_ROWS = 4;

static NSString * const MESSAGE_TEXTONLY_IDENTIFIER = @"textCell";
static NSString * const MESSAGE_TEXTONLY_IDENTIFIER_OUTGOING = @"textCellO";
static NSString * const MESSAGE_FILE_IDENTIFIER = @"fileCell";
static NSString * const MESSAGE_FILE_IDENTIFIER_OUTGOING = @"fileCellO";
static NSString * const DATE_BREAKER_IDENTIFIER = @"dateDelim";

/**
 * Number of file thumbnails to cache.
 */
static const int PEX_MAXIMUM_FILES_TO_LOAD = 35;

/**
 * Number of working threads for thumbnail generation and data detection.
 */
static const int PEX_MAXIMUM_LOADING_THREADS = 4;

/**
 * Number of newest message to precompute with data detection.
 */
static const int PEX_CHAT_PRECOMPUTE_DATA_ITEMS = 250;

@interface PEXGuiChatController () <PEXMessageClickDelegate, UIActionSheetDelegate> {
    volatile bool _scrollToNewest;

    CGFloat _minComposerHeight;
    CGFloat _maxComposerHeight;
    CGFloat _incrementComposerSize;

    volatile int64_t _sentCache;
    volatile int64_t _limitCache;

    /**
     * Simple indicator saying if the content was already loaded and showed to the user.
     * Used to optimize refreshing of the view after new thumbnail is generated.
     * If the first view rendering is in progress it makes no sense to re-draw it
     * after thumbnail is loaded as it would increase waiting time for first display
     * of the UI to the user.
     */
    volatile BOOL _contentLoaded;
}

@property (nonatomic) NSNotification * keyboardNotification;

@property (nonatomic) const PEXDbContact *contact;

@property (nonatomic) PEXGuiMessageTextComposerView * composerView;

@property (nonatomic) PEXGuiCentricButtonView * B_keyboard;

@property (nonatomic) UIView * B_scrollDown;
@property (nonatomic) PEXGuiClickableHighlightedView * B_scrollDownClickWrapper;

@property (nonatomic) PEXGuiCentricButtonView * B_send;

@property (nonatomic) UIView * actionsViewBg;

@property (nonatomic) UIViewController * previewHolderController;
@property (nonatomic) PEXGuiPreviewExecutor * previewExecutor;

@property (nonatomic) UICollectionView * collectionView;
@property (nonatomic) PEXLinearDictionary<NSDate *, PEXMessageModel *> * const datesAndMessages;

@property (nonatomic) PEXGuiMessageTextOnlyView * textOnlyResizer;
@property (nonatomic) PEXGuiMessageFileView * fileResizer;

@property (nonatomic) PEXRefDictionary *cellsAndOperations;
@property (nonatomic) NSCache* thumbsCache;
@property (nonatomic) NSRecursiveLock* thumbsCacheLock;
@property (nonatomic) NSOperationQueue *operationQueue;

@property (nonatomic) PEXGuiBackgroundView * V_messageCounterBg;
@property (nonatomic) PEXGuiClickableView * B_messageCounterButton;
@property (nonatomic) PEXGuiClassicLabel * L_messageCounterInfo;
@property (nonatomic) PEXGuiClassicLabel * L_messageCounterCounter;

/**
 * Deferred index paths to refresh after thumbnail was loaded.
 * Entries are stored here when UI was not rendered yet but new thumbnail
 * was generated. After UI was rendered, all indices in this set are refreshed.
 */
@property (nonatomic) NSMutableSet<NSIndexPath*> * indexPathsToRefresh;
@property (nonatomic) NSRecursiveLock * pathsToRefreshLock;

/**
 * Pool of NSDataDetector instances used to detect URL|PhoneNumber from messages.
 * Profiling discovered construction and destruction of NSDataDetector for each
 * message is a significant overhead dramatically reducing speed of the loading
 * (400 ms NSDataDetector, 183ms layouting).
 */
@property (nonatomic) PEXConcurrentRingQueue * dataDetectorPool;

/**
 * Dictionary holding references to data detection operations carried
 * out on the cells. Analogous to cellsAndOperations.
 */
@property (nonatomic) PEXRefDictionary * cellsAndDataOperations;
@property (nonatomic) NSRecursiveLock * cellsAndDataOperationsLock;

/**
 * Helper for opening links in activity.
 */
@property (nonatomic) PEXGuiChatLinkActivity * activityHelper;

/**
 * Fields related to action sheet (pop-up) for link clicks
 */
@property (nonatomic) UIActionSheet * phoneNumberActionSheet;
@property (nonatomic) UIActionSheet * linkActionSheet;
@property (nonatomic) NSString * currentPhoneNumber;
@property (nonatomic) NSURL * currentMessageURL;
@property (nonatomic, weak) PEXGuiMessageView * currentMessageView;
@end


@implementation PEXGuiChatController


+ (void) showChatInNavigation:(PEXGuiController * const) parent
                  withContact:(const PEXDbContact * const)contact
{

    PEXGuiChatController * const chatController = [[PEXGuiChatController alloc]
                                                   initWithContact:contact];
    [chatController showInNavigation:parent title:contact.displayName];
}

- (PEXGuiController *) showInNavigation: (UIViewController * const) parent title: (NSString * const) title
{
    PEXGuiChatNavigationController * a = [[PEXGuiChatNavigationController alloc]
                                      initWithViewController:self
                                      contact:self.contact
                             chatController:self];

    [a prepareOnScreen:parent];
    [a show:parent];
    return a;
}

- (const UIView *) getContentView
{
    return self.collectionView;
}

- (int) getItemsCount
{
    int result = 0;
    NSArray<PEXMessageModel*> * const messages = [self.datesAndMessages getObjects];

    for (NSArray * const section in messages)
        result += section.count;

    return result;
}

- (id) initWithContact: (const PEXDbContact * const)contact
{
    self = [super init];

    self.contact = contact;

    self.cellsAndOperations = [[PEXRefDictionary alloc] init];
    self.thumbsCache = [[NSCache alloc] init];
    self.thumbsCache.countLimit = PEX_MAXIMUM_FILES_TO_LOAD;
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = PEX_MAXIMUM_LOADING_THREADS;

    self.indexPathsToRefresh = [[NSMutableSet alloc] init];
    self.pathsToRefreshLock = [[NSRecursiveLock alloc] init];
    self.thumbsCacheLock = [[NSRecursiveLock alloc] init];
    self.dataDetectorPool = [[PEXConcurrentRingQueue alloc] initWithQueueName:@"data_detector_pool" capacity:PEX_MAXIMUM_LOADING_THREADS+2];
    self.cellsAndDataOperations = [[PEXRefDictionary alloc] init];
    self.cellsAndDataOperationsLock = [[NSRecursiveLock alloc] init];
    self.activityHelper = [[PEXGuiChatLinkActivity alloc] init];

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    [self.mainView addSubview:self.collectionView];

    self.composerView = [[PEXGuiMessageTextComposerView alloc] init];
    [self.mainView addSubview:self.composerView];

    self.actionsViewBg = [[UIView alloc] init];
    [self.mainView addSubview:self.actionsViewBg];

    self.B_send = [[PEXGuiCentricButtonMain alloc]
                   initWithImage:[[PEXGuiImageView alloc] initWithImage: PEXImg(@"send_strong")]];
    [self.actionsViewBg addSubview:self.B_send];

    self.B_keyboard = [[PEXGuiCentricButtonView alloc]
                       initWithImage: [[PEXGuiImageView alloc] initWithImage:PEXImg(@"keyboard_strong")]];
    [self.actionsViewBg addSubview:self.B_keyboard];

    self.B_scrollDownClickWrapper = [[PEXGuiClickableHighlightedView alloc] init];
    [self.actionsViewBg addSubview:self.B_scrollDownClickWrapper];

    self.B_scrollDown = [[PEXGuiArrowDown alloc] initWithColor:PEXCol(@"light_gray_low")];
    [self.B_scrollDownClickWrapper addSubview:self.B_scrollDown];

    // counter
    self.V_messageCounterBg = [[PEXGuiBackgroundView alloc] initWithColor:PEXCol(@"red_normal")];
    [self.mainView addSubview:self.V_messageCounterBg];

    self.L_messageCounterInfo = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                                   fontColor:PEXCol(@"white_normal")];
    [self.V_messageCounterBg addSubview:self.L_messageCounterInfo];

    self.L_messageCounterCounter = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                                   fontColor:PEXCol(@"white_normal")];
    [self.V_messageCounterBg addSubview:self.L_messageCounterCounter];

    self.B_messageCounterButton = [[PEXGuiClickableView alloc] init];
    [self.V_messageCounterBg addSubview:self.B_messageCounterButton];

    // helper message resizers
    self.textOnlyResizer = [[PEXGuiMessageTextOnlyView alloc] init];
    [self.textOnlyResizer initGuiStuff];
    self.fileResizer = [[PEXGuiMessageFileView alloc] init];
    [self.fileResizer initGuiStuff];
}

- (void) initContent
{
    [super initContent];

    self.composerView.placeholder = PEXStr(@"txt_message_placeholder");

    // the same as the border of composerVIew
    self.actionsViewBg.backgroundColor = PEXCol(@"light_gray_high");

    self.L_messageCounterInfo.text = PEXStr(@"L_remaining_messages");
    [self setMessageCount:0 withLimit:0];
}

- (void)messagesStatusChanged: (const int64_t) messagesCounts withLimit: (const int64_t) limit
{
    if (limit == -1)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeCollectionViewFull];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeCollectionViewUnderCounter];
        });
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setMessageCount:messagesCounts withLimit: limit];
    });
}

- (void)limitReached {
    // TODO ?
}

- (void) setMessageCount: (const int64_t) count withLimit: (const int64_t) limit
{
    _sentCache = count;
    _limitCache = limit;

    self.L_messageCounterCounter.text =
            [NSString stringWithFormat:@"%lld / %lld", count > limit ? limit : count, limit];

    [PEXGVU centerHorizontally:self.L_messageCounterCounter];
}

- (void) initState
{
    [super initState];

    _sentCache = 0;
    _limitCache = 0;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PEXAppState * const appState = [PEXAppState instance];
        [appState.chatAccountingManager addListenerAndSet:self];
    });
}

- (bool) isChatWithSupportInExpiredMode
{
    return [self.contact.sip isEqualToString:
            [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_SUPPORT_CONTACT_SIP_KEY
                                                     defaultValue:PEX_PREF_SUPPORT_CONTACT_SIP_DEFAULT]];
}

- (void) initBehavior
{
    [super initBehavior];

    self.collectionView.backgroundColor = PEXCol(@"white_normal");
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [self.collectionView registerClass:[PEXGuiMessageTextOnlyCell class]
            forCellWithReuseIdentifier:MESSAGE_TEXTONLY_IDENTIFIER];
    [self.collectionView registerClass:[PEXGuiMessageTextOnlyCell class]
            forCellWithReuseIdentifier:MESSAGE_TEXTONLY_IDENTIFIER_OUTGOING];
    [self.collectionView registerClass:[PEXGuiMessageFileCell class]
            forCellWithReuseIdentifier:MESSAGE_FILE_IDENTIFIER];
    [self.collectionView registerClass:[PEXGuiMessageFileCell class]
            forCellWithReuseIdentifier:MESSAGE_FILE_IDENTIFIER_OUTGOING];
    [self.collectionView registerClass:[PEXGuiMessageBreakerView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DATE_BREAKER_IDENTIFIER];

    self.collectionView.delaysContentTouches = false;

    _scrollToNewest = true;

    [self.composerView setDelegate:self];

    __weak PEXGuiChatController * const weakSelf = self;
    [self.B_keyboard addActionBlock:^{ [weakSelf keyboard]; }];
    [self.B_send addActionBlock:^{ [weakSelf sendMessage]; }];

    [self.B_scrollDownClickWrapper addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_SCROLL_DOWN];
        [weakSelf scrollToNewestAnimated:true];
    }];
    // add call action

    [self.B_messageCounterButton addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_COUNTER];
        [weakSelf showGetPremium];
    }];
}

- (void) keyboard
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_KEYBOARD];
    if (_isEditing)
        [self.composerView resignFirstResponder];
    else
        [self.composerView becomeFirstResponder];
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat height = 3.0f * PEXVal(@"dim_size_medium");

    [PEXGVU scaleHorizontally: self.actionsViewBg];
    [PEXGVU setHeight:self.actionsViewBg to: height];
    [PEXGVU moveToBottom:self.actionsViewBg];

    [PEXGVU setSize:self.B_keyboard x:height y:height];
    [PEXGVU moveToLeft:self.B_keyboard];

    // status
    [PEXGVU setSize:self.B_scrollDownClickWrapper x:height y:height];
    [PEXGVU move:self.B_scrollDownClickWrapper rightOf:self.B_keyboard];
    [PEXGVU center:self.B_scrollDown];

    [PEXGVU setHeight:self.B_send to:height];
    [PEXGVU scaleHorizontally:self.B_send from:self.B_scrollDownClickWrapper leftMargin:0.0f rightMargin:0.0f];

    // 1. time for sizing to fit
    [PEXGVU scaleHorizontally: self.composerView];
    [PEXGVU setWidth:self.composerView to:self.composerView.frame.size.width + 2.0f];
    [PEXGVU moveLeft:self.composerView by:1.0f];

    [self.composerView sizeToFit];

    [PEXGVU move:self.composerView above: self.actionsViewBg];

    // 2. time
    [PEXGVU scaleHorizontally: self.composerView];
    [PEXGVU setWidth:self.composerView to:self.composerView.frame.size.width + 2.0f];
    [PEXGVU moveLeft:self.composerView by:1.0f];


    self.composerView.text = @"";
    const CGFloat composerViewHeight = self.composerView.frame.size.height;
    _minComposerHeight = composerViewHeight;
    _incrementComposerSize = PEXVal(@"dim_size_medium");
    _maxComposerHeight = _minComposerHeight + COMPOSER_MAX_ADDITIONAL_ROWS * _incrementComposerSize;

    // counter
    [PEXGVU scaleHorizontally:self.V_messageCounterBg];
    [PEXGVU setHeight:self.V_messageCounterBg to:PEXVal(@"dim_size_medium") * 3.0f];
    [PEXGVU moveToTop:self.V_messageCounterBg];

    [PEXGVU scaleFull:self.B_messageCounterButton];

    [PEXGVU moveAboveCenter:self.L_messageCounterInfo];
    [PEXGVU centerHorizontally:self.L_messageCounterInfo];
    [PEXGVU moveBelowCenter:self.L_messageCounterCounter];
    [PEXGVU centerHorizontally:self.L_messageCounterCounter];

    [self.V_messageCounterBg bringSubviewToFront:self.B_messageCounterButton];

    // COLLECTION VIEW
    [PEXGVU scaleHorizontally:self.collectionView];
    [self resizeCollectionViewFull];

    UICollectionViewFlowLayout * const flowLayout = [[UICollectionViewFlowLayout alloc]init];

    flowLayout.headerReferenceSize =
            CGSizeMake(self.collectionView.frame.size.width, [PEXGuiMessageBreakerView staticHeight]);

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];

    [PEXGVU setWidth:self.textOnlyResizer to:self.collectionView.frame.size.width];
    [PEXGVU setWidth:self.fileResizer to:self.collectionView.frame.size.width];
}

- (void) resizeCollectionViewUnderCounter
{
    [self.V_messageCounterBg setHidden:false];

    [PEXGVU scaleVertically:self.collectionView
                    between:[PEXGVU getLowerPoint:self.V_messageCounterBg]
                        and:self.composerView.frame.origin.y];
}

- (void) resizeCollectionViewFull
{
    [self.V_messageCounterBg setHidden:true];

    [PEXGVU scaleVertically:self.collectionView above:self.composerView];
}

- (void) loadContent
{
    self.datesAndMessages = [[PEXLinearDictionary alloc] init];

    // Notify message manager to check for queued messages.
    [PEXMessageManager triggerCheck];
    PEXDbCursor * const cursor = [self loadMessagesForContact];

    const int numElements = cursor ? [cursor getCount] : 0;
    NSInteger idxPrecomputeStart = numElements - PEX_CHAT_PRECOMPUTE_DATA_ITEMS; // Can be negative, it is OK.

    NSMutableArray * precomputeArr = [[NSMutableArray alloc]
            initWithCapacity: (NSUInteger)MAX(PEX_CHAT_PRECOMPUTE_DATA_ITEMS, (NSUInteger)numElements)];

    for (NSInteger idx = 0; !_cancel && cursor && [cursor moveToNext]; ++idx) {
        PEXDbMessage * const message = [PEXDbMessage messageFromCursor:cursor];
        PEXMessageModel * const messageModel = [PEXMessageModel modelWithMessage:message];

        // If message is a file, pre-load received files data so scrolling is smooth.
        if ([messageModel isFile]){
            messageModel.receivedFiles = [self loadReceivedFilesForMessage:messageModel inOperation:nil];
        }

        [self addMessage:messageModel precompute:NO];
        if (idx >= idxPrecomputeStart){
            [precomputeArr addObject:messageModel];
        }
    }

    // Precompute data detection for messages, start from the last one.
    NSUInteger precompCnt = [precomputeArr count];
    DDLogVerbose(@"Loaded %d messages, precomputing %d", numElements, (int)precompCnt);
    for(NSInteger idx = precompCnt-1; idx >= 0; --idx){
        [self detectStructuredDataForMessageAsync:precomputeArr[(NSUInteger)idx] inCell:nil doRefresh:NO];
    }
}

- (void) postload
{
    [super postload];

    WEAKSELF;
    [PEXService executeOnMain:NO block:^{
        [weakSelf.collectionView reloadData];
        [weakSelf scrollToNewestAnimated:false];
        DDLogVerbose(@"--dataReloaded");
    }];
}

- (void) postloadIndicatorDismissed{
    [super postloadIndicatorDismissed];
    DDLogVerbose(@"--postloadIndicatorDismissed");

    // Load thumbs deferred after loading finished.
    [self loadDeferredIndexPaths];
}

- (void) clearContent
{
    [super clearContent];

    [self.datesAndMessages removeAllObjects];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.collectionView reloadData];
    });
}

- (void) shouldScrollToNewest
{
    if (_scrollToNewest)
    {
        [self scrollToNewestAnimated:true];
    }
}

- (void)scrollToNewestAnimated: (const bool) animated
{
    NSInteger section = [self numberOfSectionsInCollectionView:self.collectionView] - 1;
    NSInteger item = [self internalCollectionView:self.collectionView numberOfItemsInSection:section] - 1;

    if ((section > -1) && (item > -1)) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];

        [self.collectionView scrollToItemAtIndexPath:lastIndexPath
                                    atScrollPosition:UICollectionViewScrollPositionBottom
                                            animated:animated];
    }
}

- (void) resizeComposer
{
    const CGFloat composerContentHeight = self.composerView.contentSize.height;
    CGFloat finalContentHeight = composerContentHeight;
    if (composerContentHeight > _maxComposerHeight)
        finalContentHeight = _maxComposerHeight;
    else if (composerContentHeight < _minComposerHeight)
        finalContentHeight = _minComposerHeight;
    const CGFloat oldComposerHeight = self.composerView.frame.size.height;

    if ((composerContentHeight != oldComposerHeight))
    {
        const CGFloat diff = finalContentHeight - oldComposerHeight;

        [UIView beginAnimations:@"PEXGuiComposerResizeAnimation" context:nil];
        [UIView setAnimationDuration:0.25];

        [PEXGVU setHeight:self.composerView to:finalContentHeight];
        [PEXGVU moveUp:self.composerView by:diff];

        [self setLinearViewHeight:diff];

        [UIView commitAnimations];
    }
}

- (void) setLinearViewHeight: (const CGFloat) diff
{
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x,
                                                  self.collectionView.contentOffset.y + diff)
                     animated:NO];
    [PEXGVU setHeight:self.collectionView to:self.collectionView.frame.size.height - diff];
}

- (void) sendMessage
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_SEND];
    NSString * const messageText = self.composerView.text;

    if (![PEXMessageUtils isSendeable:messageText])
    {
        [self.composerView warningFlash];
        return;
    }

    if (    (_limitCache != -1) &&
            (_sentCache >= _limitCache) &&
            ![self isChatWithSupportInExpiredMode])
    {
        [self showGetPremium];
        return;
    }

    self.composerView.text = @"";
    self.composerView.contentSize = CGSizeMake(self.composerView.contentSize.width, _minComposerHeight);
    [self resizeComposer];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [PEXMessageUtils callSendMessage:self.contact.sip body:messageText];
    });
}

- (void) showGetPremium
{
    PEXGuiManageLicenceController * const controller = [[PEXGuiManageLicenceController alloc] init];
    [controller showInNavigation:self title:PEXStrU(@"L_manage_licence")];
}

// Controller OVERRIDE KEYBOARD EVENTS

- (CGFloat) getKeyboardOffset
{
    return self.actionsViewBg.frame.size.height;
}

// TODO research the animation behavior so as no to duplicate the animation code
// casue: it did not work properly
- (void) animateSlide: (const CGFloat) y
          accordingTo: (const NSNotification * const) notification
{
    [UIView beginAnimations:PEXStdKeyboardAnimation context:nil];
    [UIView setAnimationDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey]
                                  doubleValue]];
    [UIView setAnimationCurve:(UIViewAnimationCurve) [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [PEXGVU moveVertically:self.actionsViewBg by:y];
    [PEXGVU moveVertically:self.composerView by:y];
    [self setLinearViewHeight:-y];

    [UIView commitAnimations];
}

// UITEXTVIEW DELEGATE STUFF

- (void)textViewDidChange:(UITextView *)textView
{
    [self resizeComposer];
}

// CONTENT OBSERVER STUFF
- (bool) deliverSelfNotifications
{
    return false;
}

- (void) dispatchChange: (const bool) selfChange
                    uri: (const PEXUri * const) uri
{

}

- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbMessage getURI]])
        return;

    [self.contentLock lock];

    PEXDbCursor * const cursor = [self loadMessagesForContact];

    // TODO this is wrong ... should load until reaches a message already cached
    const int alreadyShownMessagesCount = [self getItemsCount];
    [cursor moveToPosition:alreadyShownMessagesCount];

    bool blink = false;

    NSMutableArray * const indiciesAdded = [[NSMutableArray alloc] init];

    const NSInteger numberOfSections = [self numberOfSectionsInCollectionView:self.collectionView];
    bool newSectionWasAddded = false;
    const NSInteger lastSection = (numberOfSections - 1);

    NSIndexPath * indexOfLastMessageBeforeAdding;
    bool shouldUnseen = false;

    if (lastSection > -1)
    {
        NSArray<PEXMessageModel *> * const lastSectionMessages = [self.datesAndMessages objectsAt:(NSUInteger)lastSection];
        if (lastSectionMessages.count > 0)
        {
            PEXMessageModel * msgModel = lastSectionMessages[lastSectionMessages.count - 1];
            indexOfLastMessageBeforeAdding = [NSIndexPath indexPathForItem:lastSectionMessages.count - 1 inSection:lastSection];
            shouldUnseen = [PEXDbMessage messageIsSeenAndOutgoing:msgModel.message];
        }
    }

    while (cursor && [cursor moveToNext])
    {
        if (_cancel) { [self.contentLock unlock]; return;}

        // for ARC not to deallocate until the adding is finished
        PEXDbMessage * const message = [PEXDbMessage messageFromCursor:cursor];
        PEXMessageModel * const messageModel = [PEXMessageModel modelWithMessage:message];
        NSIndexPath * const indexPath = [self addMessage:messageModel precompute:YES];

        if ((indexPath.section >= lastSection)  && (indexPath.item == 0))
            newSectionWasAddded = true;

        [indiciesAdded addObject:indexPath];

        if (message.isOutgoing.integerValue == 0)
            blink = true;
    }

    if (blink) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [UIView animateWithDuration:PEXVal(@"dur_shorter")
                             animations:^{
                                 [self.B_scrollDownClickWrapper setStateHighlight];
                             }
                             completion:^(BOOL finished) {
                                 [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
                                     [self.B_scrollDownClickWrapper setStateNormal];
                                 }];
                             }];
        });
    }

    if (indiciesAdded.count > 0)
    {
        if (newSectionWasAddded)
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [self.collectionView reloadData];
                [self shouldScrollToNewest];
            });
        }
        else
        {
            if (shouldUnseen)
            {
                dispatch_sync(dispatch_get_main_queue(), ^(void)
                {
                    [self wrapCollectionViewUpdate:^{
                        [self.collectionView performBatchUpdates:^{

                            // because of read status info
                            [self.collectionView reloadItemsAtIndexPaths:@[indexOfLastMessageBeforeAdding]];

                            [self.collectionView insertItemsAtIndexPaths:indiciesAdded];

                        } completion:^(BOOL finished) {
                            [self shouldScrollToNewest];
                        }];
                    }];
                });
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    [self wrapCollectionViewUpdate:^{
                        [self.collectionView insertItemsAtIndexPaths:indiciesAdded];
                        [self shouldScrollToNewest];
                    }];
                });
            }
        }
    }

    [self.contentLock unlock];

}

- (void) wrapCollectionViewUpdate: (void (^)(void))executionBlock
{
    //@try
    //{
//    [UIView animateWithDuration:0 animations:^{
//        [_collectionView performBatchUpdates:^{
//            executionBlock();
//        } completion:nil];
//    }];

    executionBlock();

    /*}
    @catch(NSException * exception)
    {
        NSString * const message = @"UICollectionView update exception";
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            DDLogDebug(@"%@:\nexception:\n", message, [exception description]);
            //[Flurry logError:message message:message exception:exception];
            [self.collectionView reloadData];
        });
    }*/
}

- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbMessage getURI]])
    {
        [self messagesDeleted];
        return;
    }

    // contact deleted
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    PEXDbCursor * const cursor =
    [[PEXDbAppContentProvider instance]query:[PEXDbContact getURI]
                                      projection:[PEXDbContact getLightProjection]
                                       selection:[NSString stringWithFormat:@"WHERE %@=?", DBCL(FIELD_SIP)]
                                   selectionArgs:@[self.contact.sip]
                                       sortOrder:nil];

    if (cursor && ([cursor getCount] == 0))
    {
        // THE CONTACT WAS DELETED BUT WE DO NOTHING ABOUT IT ... TODO
    }
}

- (void) messagesDeleted
{
    [self.contentLock lock];

    PEXDbCursor * const cursor = [self loadMessagesForContact];

    NSMutableArray * const remnantIds = [[NSMutableArray alloc] initWithCapacity:[cursor getCount]];
    const int idPosition = [cursor getColumnIndex:PEXDBMessage_FIELD_ID];

    while (cursor && [cursor moveToNext])
    {
        if (_cancel) { [self.contentLock unlock]; return;}

        [remnantIds addObject:[cursor getInt64:idPosition]];
    }

    NSMutableArray * const removedIndicies = [[NSMutableArray alloc] init];

    for (NSUInteger section = 0; section < self.datesAndMessages.count; ++section)
    {
        if (_cancel) { [self.contentLock unlock]; return;}
        NSArray<PEXMessageModel*> * const messages = [self.datesAndMessages objectsAt:section];

        int indexForPath = 0;
        for (NSUInteger index = 0; index < messages.count; ++index, ++indexForPath)
        {
            if (_cancel) { [self.contentLock unlock]; return; }

            const PEXDbMessage * const message = messages[index].message;
            if (![remnantIds containsObject:message.id])
            {
                [self removeMessageInSection:section at:index];
                [removedIndicies addObject:[NSIndexPath indexPathForRow:indexForPath inSection:section]];
                --index;
            }
        }
    }

    if (removedIndicies.count > 0)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self wrapCollectionViewUpdate:^{
                [self.collectionView deleteItemsAtIndexPaths:removedIndicies];
            }];
        });
    }

    [self.contentLock unlock];
}

// must be called in mutex
- (void) removeMessageInSection: (const int) section at: (const int) index
{
    [[self.datesAndMessages objectsAt:section] removeObjectAtIndex:index];
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbContact getURI]])
    {
        // TODO show something like contact is offline or stuff
        return;
    }

    if ([uri isEqualToUri:[PEXDbMessage getURI]])
    {
        [self messageUpdated];
        return;
    }
}

- (void) messageUpdated
{
    [self.contentLock lock];

    PEXDbCursor * const cursor = [self loadMessagesForContact];

    NSMutableArray * const indexPathsToUpdate = [[NSMutableArray alloc] init];

    while (cursor && [cursor moveToNext])
    {
        if (_cancel) { [self.contentLock unlock]; return;}

        // for ARC not to deallocate until the adding is finished
        PEXDbMessage * message = [PEXDbMessage messageFromCursor:cursor];
        PEXMessageModel * messageModel = [PEXMessageModel modelWithMessage:message];

        NSDate * const messageDay = [PEXDateUtils dateWithoutTimeComponent:message.date];
        NSIndexPath * const indexPath = [self.datesAndMessages indexPathforObject:messageModel inSection:messageDay];

        if (indexPath)
        {
            PEXMessageModel *const storedModel = [self.datesAndMessages getObjectAtIndexPath:indexPath];
            BOOL doFileReload = [storedModel isFile] && storedModel.receivedFiles == nil;
            BOOL doUpdateIndexPath = NO;

            if ([PEXGuiMessageView message:storedModel.message needsUpdate:message]) {
                doFileReload = YES;
                doUpdateIndexPath = YES;
                [PEXGuiMessageView updateMessage:storedModel.message with:message];
            }

            if (doFileReload || doUpdateIndexPath){
                storedModel.receivedFiles = [self loadReceivedFilesForMessage:storedModel inOperation:nil];
                [storedModel dirty];

                [self calculateIfShouldScrollToNewest];
                [indexPathsToUpdate addObject:indexPath];
            }

        } else {
            DDLogVerbose(@"Message not found");
        }
    }

    if (indexPathsToUpdate.count > 0)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self wrapCollectionViewUpdate:^{
                [self.collectionView reloadItemsAtIndexPaths:indexPathsToUpdate];
                [self shouldScrollToNewest];
            }];
        });
    }

    [self.contentLock unlock];
}

// LIST UTILS

- (PEXDbCursor *) loadMessagesForContactOld
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getFullProjection]
        selection:[PEXDbMessage getWhereForContact]
    selectionArgs:[PEXDbMessage getWhereForContactArgs:self.contact]
        sortOrder:[PEXDbMessage getSortByDateOldestFirst]];
}

- (PEXDbCursor *) loadMessagesForContact
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getFullProjection]
        selection:[PEXDbMessage getWhereForContact]
    selectionArgs:[PEXDbMessage getWhereForContactArgs:self.contact]
        sortOrder:[PEXDbMessage getSortByIdOldestFirst]];
}

- (PEXDbMessage *) loadMessagesForId: (NSNumber * const) itemId
{
    if (!itemId)
        return nil;

    PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getFullProjection]
        selection:[PEXDbMessage getWhereForIdAndContact]
    selectionArgs:[PEXDbMessage getWhereForId:itemId AndContactArgs:self.contact]
        sortOrder:nil];

    PEXDbMessage * result;

    if (cursor && [cursor moveToNext])
        result = [PEXDbMessage messageFromCursor:cursor];

    return result;
}

- (void) calculateIfShouldScrollToNewest
{
    _scrollToNewest =
            ((self.collectionView.contentOffset.y + self.collectionView.frame.size.height) >
                    self.collectionView.contentSize.height - 20.0f); // 20.0f not so strictly at the end
}

- (NSIndexPath *)addMessage:(PEXMessageModel *const)messageModel precompute: (BOOL) precompute
{
    [self calculateIfShouldScrollToNewest];

    NSDate * const lastDate = [[self.datesAndMessages getSections] lastObject];
    int section = self.datesAndMessages.count - 1;
    int index;

    if (lastDate && [PEXDateUtils compareUneffectiveWithoutTimeComponent:lastDate with:messageModel.date])
    {
        NSMutableArray<PEXMessageModel*> * const messages = [self.datesAndMessages objectsForSectionLast:lastDate];
        [messages addObject:messageModel];
        index = messages.count - 1;
    }
    else
    {
        [self createNewSectionWithMessage:messageModel];
        ++section;
        index = 0;
    }

    if (precompute) {
        [self detectStructuredDataForMessageAsync:messageModel inCell:nil doRefresh:NO];
    }

    return [NSIndexPath indexPathForItem:index inSection:section];
}

- (void) createNewSectionWithMessage: (PEXMessageModel * const) message
{
    NSDate * const sectionDate = [PEXDateUtils dateWithoutTimeComponent:message.date];
    [self.datesAndMessages addObject:message forNewSection:sectionDate];
}

#pragma UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger result = 0;

    result = [self internalCollectionView:collectionView numberOfItemsInSection:section];
    return result;
}

- (NSInteger)internalCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (section < self.datesAndMessages.count) ?
            ([self.datesAndMessages objectsAt:(NSUInteger)section]).count :
            0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {

    NSInteger result = 0;

    result = self.datesAndMessages.count;
    return result;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * result = nil;

    if (indexPath.section < self.datesAndMessages.count &&
        (indexPath.item < [self.datesAndMessages objectsAt:(NSUInteger)indexPath.section].count))
    {
        PEXMessageModel * message = [self messageByPath:indexPath];
        if (message == nil){
            DDLogError(@"Nil message");
            return result;
        }

        NSString * cellIdentifier = nil;
        if([message isFile]){
            cellIdentifier = [message outgoing] ? MESSAGE_FILE_IDENTIFIER_OUTGOING : MESSAGE_FILE_IDENTIFIER;
        } else {
            cellIdentifier = [message outgoing] ? MESSAGE_TEXTONLY_IDENTIFIER_OUTGOING : MESSAGE_TEXTONLY_IDENTIFIER;
        }

        PEXGuiMessageCell *const cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell == nil){
            DDLogError(@"Nil cell");
            return result;
        }

        // http://stackoverflow.com/questions/18460655/uicollectionview-scrolling-choppy-when-loading-cells
        // TODO: performance testing here. Rasterizing is not mayber optimal here...
//        cell.layer.shouldRasterize = YES;
//        cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

        PEXStopwatch * swCellLayout = [[PEXStopwatch alloc] initWithNameAndStart:@"cellForItemAtIndexPath"];
        PEXGuiMessageView *const messageView = [cell getSubview];
        DDLogVerbose(@"< cellForItemAtIndexPath: %@, %.2fx%.2f %@>", message.id,
                message.cellSizeForItem.width,
                message.cellSizeForItem.height,
                message);
        [self fillMessageView:messageView withMessage:message cacheThumbs:true inCell:cell onIndexPath:indexPath];

        // Accept link clicks.
        messageView.linkClickDelegate = self;

        // On click context actions for generic message (all types).
        [self addMessageOnClickAction:messageView forMessage:message];

        // Special filetransfer related acctions appended.
        if ([message isFile]) {
            [self addTransferClickActions:(PEXGuiMessageFileView *)messageView forMessage:message];
        }

        result = cell;
        DDLogVerbose(@"</cellForItemAtIndexPath: %@, %.2fx%.2f %.4fs %@>",
                message.id,
                messageView.frame.size.width,
                messageView.frame.size.height,
                [swCellLayout stop],
                message);
    }

    return result;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize result = CGSizeZero;

    PEXMessageModel * message = [self messageByPath:indexPath];
    if (message == nil){
        DDLogWarn(@"Message nil on path: %@", indexPath);
        return result;
    }

    // Message size can be precomputed.
    if (message.cellSizeOk){
        return message.cellSizeForItem;
    }

    // Message size needs to be computed
    DDLogVerbose(@"--sizeForItemId: %@, %@", message.id, message);
    PEXGuiMessageView *const messageView = [message isFile] ? self.fileResizer : self.textOnlyResizer;
    [self fillMessageView:messageView withMessage:message cacheThumbs:false inCell:nil onIndexPath:indexPath];

    result = messageView.frame.size;
    message.cellSizeForItem = result;
    message.cellSizeOk = YES;

    return result;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *result = nil;

    if (kind == UICollectionElementKindSectionHeader)
    {

        PEXGuiMessageBreakerView *breaker =
                [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                   withReuseIdentifier:DATE_BREAKER_IDENTIFIER
                                                          forIndexPath:indexPath];

        NSArray<NSDate*> * const dates = [self.datesAndMessages getSections];
        if (breaker && (indexPath.section < dates.count))
        {
            NSDate * const date = dates[(NSUInteger)indexPath.section];
            [breaker setText:[PEXDateUtils dateToDateString:date]];
            result = breaker;
        }
    }

    return result;
}

- (void)fillMessageView:(PEXGuiMessageView *const)messageView
            withMessage: (PEXMessageModel *) message
            cacheThumbs: (const bool) cacheThem
                 inCell: (const PEXGuiMessageCell * const) cell
            onIndexPath: (const NSIndexPath * const) indexPath
{
    [self fillMessageView:messageView
              withMessage:message
              cacheThumbs:cacheThem
                   inCell:cell];

    [self checkSeenForMessage:message
                  onIndexPath:indexPath
                      forView:messageView];

    [messageView layoutSubviews];
}

- (void) checkSeenForMessage: (const PEXMessageModel * const) message
                 onIndexPath: (const NSIndexPath * const) indexPath
                     forView: (PEXGuiMessageView * const) messageView
{
    const NSUInteger sectionsLastIndex = [self.datesAndMessages getSections].count - 1;

    if ((indexPath.section == sectionsLastIndex) &&
            (indexPath.item == ([self.datesAndMessages objectsAt:sectionsLastIndex]).count - 1) &&
            [PEXDbMessage messageIsSeenAndOutgoing:message.message])
    {
        [messageView setSeen:message.message.readDate];
    }
    else
    {
        [messageView setSeen:nil];
    }
}

- (void)fillMessageView:(PEXGuiMessageView *const)messageView
            withMessage: (PEXMessageModel *) message
            cacheThumbs: (const bool) cacheThem
                 inCell: (const PEXGuiMessageCell * const) cell
{
    if ([message isFile])
    {
        if ([PEXGuiMessageFileView messageReadyForThumbnails:message.message])
        {
            [self fillFileMessageView:(PEXGuiMessageFileView *)messageView withMessage:message cacheThumbs:cacheThem inCell:cell];
        }
        else
        {
            [messageView setMessage:message];
        }
    }
    else
    {
        // Data detection, if not already started (in progress) or not already finished.
        if (cell != nil
                && !message.dataDetectionFinished
                && !message.dataDetectionStarted)
        {
            DDLogVerbose(@"Starting detection for %@, %@", message.id, message);
            [self detectStructuredDataForMessageAsync:message
                                               inCell:cell
                                            doRefresh:YES];
        }

        [messageView setMessage:message];
    }
}

- (void) fillFileMessageView: (PEXGuiMessageFileView *const)messageView
                 withMessage: (PEXMessageModel *) message
                 cacheThumbs: (const bool) cacheThem
                      inCell: (const PEXGuiMessageCell * const) cell
{
    [self.thumbsCacheLock lock];
    NSArray *cachedNamesAndThumbs = [self.thumbsCache objectForKey:message];
    [self.thumbsCacheLock unlock];

    // Cached version is present - just apply it.
    if (cachedNamesAndThumbs) {
        [messageView setNamesAndThumbs:cachedNamesAndThumbs message:message];
        return;
    }

    // No cached thumbnails found. Have to compute them.
    // If cacheThem = false, we are computing just size of the layout
    if ([message isFile] && message.receivedFiles == nil){
        DDLogVerbose(@"Loading message received files during render, probably inserted/updated message %@", message.id);
        message.receivedFiles = [self loadReceivedFilesForMessage:message inOperation:nil];
    }

    NSArray * const receivedFiles = message.receivedFiles;
    const int receivedFilesCount = receivedFiles.count;

    // Transfer could fail or something went wrong and file were deleted
    if (receivedFilesCount > 0) {
        NSMutableArray * const namesAndThumbs = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < receivedFiles.count; ++i) {
            [namesAndThumbs addObject:((PEXDbReceivedFile *) receivedFiles[i]).fileName];
            [namesAndThumbs addObject:[self fileImage]];
        }

        [messageView setNamesAndThumbs:namesAndThumbs message:message];

        // Start async thumbnail generation.
        // It will refresh cell view if after finished generation cell is still visible.
        if (cacheThem){
            [self cacheAndSetNamesAndThumbsForMessageAsync:message inCell:cell];
        }
    } else {
        [messageView setMessage:message];
    }
}

- (void)stageIndexForRefresh:(NSIndexPath * const) indexPath{
    if (!_contentLoaded){
        DDLogInfo(@"notLoadedYet");
        [self.pathsToRefreshLock lock];
        [self.indexPathsToRefresh addObject:indexPath];
        [self.pathsToRefreshLock unlock];
        return;
    }

    // Refresh view for particular index immediately.
    [self refreshIndexPathsArray:@[indexPath]];
}

- (void) loadDeferredIndexPaths {
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        __strong __typeof(weakSelf) sSelf = weakSelf;
        NSArray<NSIndexPath*> * indexPathsToRefresh;

        // From now on, the changes are reflected directly to the content view.
        _contentLoaded = YES;

        // Get all index paths to refresh from the set and reset all index paths set.
        [sSelf.pathsToRefreshLock lock];
        indexPathsToRefresh = [sSelf.indexPathsToRefresh allObjects];
        [sSelf.indexPathsToRefresh removeAllObjects];
        [sSelf.pathsToRefreshLock unlock];
        if ([indexPathsToRefresh count] == 0){
            return;
        }

        // Refresh view with given set - optimized, batch refresh.
        [self refreshIndexPathsArray:indexPathsToRefresh];
    }];
}

-(void) refreshIndexPathsArray: (NSArray<NSIndexPath*> *) indexPathArray{
    WEAKSELF;
//    [self.contentLock lock];
    DDLogVerbose(@"--refreshIndexPaths: %@", indexPathArray);
    [self wrapCollectionViewUpdate:^{
        [weakSelf calculateIfShouldScrollToNewest];
        [weakSelf.collectionView reloadItemsAtIndexPaths:indexPathArray];
        [weakSelf shouldScrollToNewest];
    }];
//    [self.contentLock unlock];
}

- (void)refreshMessageUIIfNeededAsync: (PEXMessageModel *) message
                          inOperation: (__weak const NSOperation * const) weakOperation
{
    [self.contentLock lock];
    NSIndexPath * const indexPath = [self.datesAndMessages indexPathforObject:message
                                                                    inSection:[PEXDateUtils dateWithoutTimeComponent:message.message.date]];
    [self.contentLock unlock];

    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        PEXGuiChatController * sSelfMain = weakSelf;
        bool reload = false;

        if (indexPath && !weakOperation.isCancelled) {
            if ([[sSelfMain.collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
                reload = true;
            }
        }

        if (reload) {
            [PEXService executeOnMain:YES block:^{
                [weakSelf stageIndexForRefresh:indexPath];
            }];
        }
    }];
}

- (void)cacheAndSetNamesAndThumbsForMessageAsync: (PEXMessageModel *) message
                                          inCell: (const PEXGuiMessageCell * const) cell
{
    NSBlockOperation * const operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation * const weakOperation = operation;

    WEAKSELF;
    [operation addExecutionBlock:^(void) {
        PEXGuiChatController * sSelf = weakSelf;
        NSArray * const receivedFiles = message.receivedFiles;
        if (receivedFiles.count == 0 || weakOperation.isCancelled) {
            return;
        }

        NSArray * const thumbs = [sSelf loadThumbsForMessage:message andFiles:receivedFiles inOperation:weakOperation];
        if (weakOperation.isCancelled) {
            return;
        }

        NSMutableArray * const namesAndThumbs = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < receivedFiles.count; ++i) {
            if (weakOperation.isCancelled) {
                return;
            }

            if (thumbs == nil || thumbs.count <= i){
                continue;
            }

            [namesAndThumbs addObject:((PEXDbReceivedFile *)receivedFiles[i]).fileName];
            [namesAndThumbs addObject:thumbs[i]];
        }

        [sSelf.thumbsCacheLock lock];
        [sSelf.thumbsCache setObject:namesAndThumbs forKey:message];
        [sSelf.thumbsCacheLock unlock];
        DDLogVerbose(@"Thumb generation finished %@", message);

        //[message dirty]; // Not needed for now, layout is precomputed.

        // UI refresh operation.
        // Has to be done on main thread as it loads UI related data
        // to decide if UI refresh is needed.
        [sSelf refreshMessageUIIfNeededAsync:message inOperation:weakOperation];
    }];

    const NSUInteger index = [[self.cellsAndOperations getKeys] indexOfObject:cell];
    if (index != NSNotFound)
    {
        DDLogVerbose(@"Cancelling THUMB OPERATION %@", message.id);
        NSOperation * const oldOperation = [self.cellsAndOperations getObjects][index];
        [oldOperation cancel];
    }

    [self.cellsAndOperations setObject:operation forKey:cell];
    [self.operationQueue addOperation:operation];
}

- (void)detectStructuredDataForMessageAsync: (PEXMessageModel *) message
                                     inCell: (const PEXGuiMessageCell * const) cell
                                  doRefresh: (BOOL) doRefresh
{
    WEAKSELF;
    NSBlockOperation * const operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation * const weakOperation = operation;
    [operation addExecutionBlock:^(void) {
        PEXGuiChatController * sSelf = weakSelf;

        // Obtain detector from pool.
        // If none is returned, create a new one and push it back later.
        NSDataDetector * detector = [sSelf.dataDetectorPool popFront];
        if (detector == nil){
            NSError * error = NULL;
            detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber error:&error];
            if (detector == nil || error != nil){
                DDLogError(@"Data detector could not be created %@", error);
                return;
            }
            DDLogVerbose(@"New detector initialized");
        }

        // Detect text in each given message.
        NSUInteger patternsDetected = 0;
        NSMutableArray<PEXInTextData *> * detectedDataArray = [[NSMutableArray alloc] init];
        NSAttributedString *attribStr = [sSelf detectDataInMessage:message
                                                      withDetector:detector
                                                       inOperation:weakOperation
                                                  patternsDetected:&patternsDetected
                                                 dataDetectedArray:detectedDataArray];

        // Operation with detector is finished, it can be returned to the pool.
        [sSelf.dataDetectorPool pushBackOnlyIfNonFull:detector async:YES];

        if (weakOperation.isCancelled) {
            message.dataDetectionStarted = NO;
            message.dataDetectionFinished = NO;
            return;
        }

        message.numDataDetectedInBody = patternsDetected;
        message.detectedData = detectedDataArray;
        if (patternsDetected == 0) {
            message.dataDetectionFinished = YES;
            return;
        }

        //TODO: maybe do in a message-owned mutex?
        message.attributedString = [attribStr mutableCopy];
        message.dataDetectionFinished = YES;
        DDLogVerbose(@"Detection finished %@, %@", message.id, message);

        // UI refresh operation.
        // Has to be done on main thread as it loads UI related data
        // to decide if UI refresh is needed.
        if (doRefresh) {
            [sSelf refreshMessageUIIfNeededAsync:message inOperation:weakOperation];
        }
    }];

    // If cell is specified, this is loading on demand.
    // If cell is already occupied by another model, computation for old one is cancelled.
    if (cell != nil) {
        [self.cellsAndDataOperationsLock lock];
        @try {
            const NSUInteger index = [[self.cellsAndDataOperations getKeys] indexOfObject:cell];
            if (index != NSNotFound) {
                DDLogVerbose(@"OldDetectionOperationCancelled");
                NSOperation *const oldOperation = [self.cellsAndDataOperations getObjects][index];
                [oldOperation cancel];
            }

            [self.cellsAndDataOperations setObject:operation forKey:cell];
        } @finally {
            [self.cellsAndDataOperationsLock unlock];
        }
    }

    [self.operationQueue addOperation:operation];
}

- (NSArray *) loadReceivedFilesForMessage: (const PEXMessageModel * const) message
                              inOperation: (__weak const NSOperation * const) weakOperation
{
    PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance]
            query:[PEXDbReceivedFile getURI]
       projection:[PEXDbReceivedFile getFullProjection]
        selection:[PEXDbReceivedFile getWhereForMessage]
    selectionArgs:[PEXDbReceivedFile getWhereForMessageArgs:message.message]
        sortOrder:nil];

    NSMutableArray * const result = [[NSMutableArray alloc] init];

    while ([cursor moveToNext])
    {
        if (weakOperation.isCancelled) return nil;

        PEXDbReceivedFile * const receivedFile = [[PEXDbReceivedFile alloc] init];
        [receivedFile createFromCursor:cursor];
        [result addObject:receivedFile];
    }

    return result;
}

- (PEXMessageModel *) messageByPath: (NSIndexPath * const) indexPath
{
    return [self.datesAndMessages getObjectAtIndexPath:indexPath];
}

// Action

- (PEXMessageModel *) renewMessage: (PEXMessageModel *) oldMessage
{
    PEXMessageModel * result = nil;

    NSIndexPath * const indexPath =
            [self.datesAndMessages indexPathforObject:oldMessage
                                            inSection:[PEXDateUtils dateWithoutTimeComponent:oldMessage.date]];

    if (indexPath)
    {
        result = [self.datesAndMessages getObjectAtIndexPath:indexPath];
    } else {
        DDLogVerbose(@"Message not found");
    }

    return result;
}

- (void)addTransferClickActions:(PEXGuiMessageFileView *const)messageView
                     forMessage: (const PEXMessageModel * const) message {

    // ACCEPT
    void (^acceptFile)(void) = ^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILE_ACCEPT];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.contentLock lock];
            PEXMessageModel *msg = [self renewMessage:message];
            if (msg)
                    [PEXMessageManager confirmTransfer:msg.id accept:YES];
            [self.contentLock unlock];
        });
    };
    [messageView setAcceptBlock:acceptFile];

    // REJECT
    void (^rejectFile)(void) = ^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILE_REJECT];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.contentLock lock];
            PEXGuiBinaryDialogExecutor *const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
            executor.primaryButtonText = PEXStrU(@"B_reject_file");
            executor.secondaryButtonText = PEXStrU(@"B_close");
            executor.text = PEXStr(@"txt_reject_file_transfer_question");
            executor.primaryAction = ^{

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self.contentLock lock];
                    PEXMessageModel *msg = [self renewMessage:message];
                    if (msg)
                        [PEXMessageManager confirmTransfer:msg.id accept:NO];
                    [self.contentLock unlock];
                });
            };

            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [executor show];
            });

            [self.contentLock unlock];
        });
    };
    [messageView setRejectBlock:rejectFile];

    // CANCEL
    void (^cancelTransfer)(void) = ^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILE_CANCEL];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.contentLock lock];
            PEXGuiBinaryDialogExecutor *const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
            executor.primaryButtonText = PEXStrU(@"B_cancel_transfer");
            executor.secondaryButtonText = PEXStrU(@"B_close");
            executor.text = PEXStr(@"txt_cancel_file_transfer_question");
            executor.primaryAction = ^{

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self.contentLock lock];
                    PEXMessageModel *msg = [self renewMessage:message];

                    if (msg)
                        [[PEXFtTransferManager instance] cancelTransfer:msg.message];

                    [self.contentLock unlock];
                });
            };

            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [executor show];
            });

            [self.contentLock unlock];
        });
    };
    [messageView setCancelBlock:cancelTransfer];
}

- (UIView*) getViewForMessage: (PEXMessageModel *)message {
    @try {
        NSIndexPath *const indexPath =
                [self.datesAndMessages indexPathforObject:message
                                                inSection:[PEXDateUtils dateWithoutTimeComponent:message.date]];

        return (PEXGuiMessageFileCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
    } @catch(NSException *e){
        DDLogError(@"Could not capture view from index path %@", e);
    }

    return self.collectionView;
}

- (void)userClickedMessage:(const PEXMessageModel *const)message
                     onURL:(NSURL *)url
                  withData:(PEXInTextDataLink *)data
                  withView:(PEXGuiMessageView *) messageView {
    // Short click -> show options to open link, copy link, message details.
    [self hideKeyboard];
    self.currentMessageURL = url;
    self.currentMessageView = messageView;
    self.linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:PEXStrU(@"B_cancel")
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:
                                                             [NSString stringWithFormat:@"%@ %@", PEXStrU(@"L_open_url"), [url absoluteString]],
                                                                       PEXStrU(@"L_copy_text"),
                                                                       PEXStrU(@"L_message_menu"),
                                                                       nil];

    [self.linkActionSheet showInView:messageView];
}

- (void)userClickedMessage:(const PEXMessageModel *const)message
                   onPhone:(NSString *)phone
                  withData:(PEXInTextDataPhoneNumber *)data
                  withView:(PEXGuiMessageView *) messageView {
    // Short click -> show options to call number, text number, copy number, message details.
    [self hideKeyboard];
    self.currentPhoneNumber = phone;
    self.currentMessageView = messageView;
    self.phoneNumberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:PEXStrU(@"B_cancel")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:
                                                      [NSString stringWithFormat:@"%@ %@", PEXStrU(@"L_call_phone"), phone],
                                                                PEXStrU(@"L_send_text"),
                                                                PEXStrU(@"L_copy_text"),
                                                                PEXStrU(@"L_message_menu"),
                                                                nil];

    [self.phoneNumberActionSheet showInView:messageView];

}

- (void)userLongClickedMessage:(const PEXMessageModel *const)message
                         onURL:(NSURL *)url
                      withData:(PEXInTextDataLink *)data
                      withView:(PEXGuiMessageView *) messageView {
    // Long click -> Activity popup. With copy to clipboard option. As in Messenger.
    [self hideKeyboard];
    [self.activityHelper openUrls:@[url] forView:self.collectionView];
}

- (void)userLongClickedMessage:(const PEXMessageModel *const)message
                       onPhone:(NSString *)phone
                      withData:(PEXInTextDataPhoneNumber *)data
                      withView:(PEXGuiMessageView *) messageView {
    // Long click -> Activity popup. With copy to clipboard option. As in Messenger.
    [self hideKeyboard];
    [self.activityHelper openItems:@[phone] forView:self.collectionView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    @try {
        if (actionSheet == self.phoneNumberActionSheet && self.currentPhoneNumber != nil) {
            [self onPhonePopup:actionSheet didDismissWithButtonIndex:buttonIndex];

        } else if (actionSheet == self.linkActionSheet && self.currentMessageURL != nil) {
            [self onLinkPopup:actionSheet didDismissWithButtonIndex:buttonIndex];

        } else {
            DDLogWarn(@"Action sheet could not be opened");
        }

    } @catch(NSException *e){
        DDLogError(@"Exception in handling telephone number in action sheet %@", e);
    }
}

- (void)onPhonePopup:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            NSURL *telUrl = [PEXUtils buildTelUrlFromString:self.currentPhoneNumber];
            [[UIApplication sharedApplication] openURL:telUrl];
            break;
        }

        case 1: {
            NSURL *smsUrl = [PEXUtils buildSmsUrlFromString:self.currentPhoneNumber];
            [[UIApplication sharedApplication] openURL:smsUrl];
            break;
        }

        case 2: {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:self.currentPhoneNumber];
            break;
        }

        case 3: {
            [self.currentMessageView invokeClickAction];
            break;
        }

        default:
            break;
    }
}

- (void)onLinkPopup:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            [[UIApplication sharedApplication] openURL:self.currentMessageURL];
            break;
        }

        case 1: {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:[self.currentMessageURL absoluteString]];
            break;
        }

        case 2: {
            [self.currentMessageView invokeClickAction];
            break;
        }

        default:
            break;
    }
}

- (void) addMessageOnClickAction: (PEXGuiMessageView * const) messageView
                      forMessage: (const PEXMessageModel * const) message
{
    WEAKSELF;
    dispatch_block_t messageContextAction = ^{
        __typeof(self) sSelf = weakSelf;
        [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_CLICKABLE_AREA];

        [sSelf.contentLock lock];
        PEXRefDictionary *const actionsAndPresentations = [[PEXRefDictionary alloc] init];

        // DETAILS
        void (^showDetails)(void) = ^{
            __typeof(self) sSelf2 = weakSelf;
            [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_POPUP_DETAIL];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [sSelf2.contentLock lock];
                PEXMessageModel *const msg = [sSelf2 renewMessage:message];

                if (msg) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [sSelf2 hideKeyboard];

                        PEXGuiMessageDetailController *const messageDetail =
                                [[PEXGuiMessageDetailController alloc] initWithMessage:msg];

                        [messageDetail showInClosingWindow:sSelf2 title:nil withUnaryListener:nil];
                    });
                }
                [sSelf2.contentLock unlock];
            });
        };

        PEXGuiContextItemHolder *const detailsItemHolder = [[PEXGuiContextItemHolder alloc] init];
        detailsItemHolder.text = PEXStr(@"B_details");
        detailsItemHolder.icon = PEXImg(@"info");
        [actionsAndPresentations setObject:detailsItemHolder
                                    forKey:showDetails];

        // COPY TEXT
        void (^copyText)(void) = ^{
            __typeof(self) sSelf2 = weakSelf;
            [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_POPUP_COPY];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [sSelf2.contentLock lock];
                PEXMessageModel *msg = [sSelf2 renewMessage:message];

                if (msg) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [UIPasteboard generalPasteboard].string = msg.body;
                    });
                }
                [sSelf2.contentLock unlock];
            });
        };

        PEXGuiContextItemHolder *const copyItemHolder = [[PEXGuiContextItemHolder alloc] init];
        copyItemHolder.text = PEXStr(@"L_copy_text");
        copyItemHolder.icon = PEXImg(@"copy");
        [actionsAndPresentations setObject:copyItemHolder
                                    forKey:copyText];

        // DELETE MESSAGE
        void (^deleteMessage)(void) = ^{
            __typeof(self) sSelf2 = weakSelf;
            [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_POPUP_REMOVE];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [sSelf2.contentLock lock];
                PEXGuiBinaryDialogExecutor *const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:weakSelf];
                executor.primaryButtonText = PEXStrU(@"B_delete");
                executor.secondaryButtonText = PEXStrU(@"B_cancel");
                executor.text = PEXStr(@"txt_delete_message_question");
                executor.primaryAction = ^{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        PEXMessageModel *msg = [sSelf2 renewMessage:message];
                        if (msg)
                            [PEXMessageManager removeMessageForId:msg.id];
                    });
                };

                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    [executor show];
                });
                [sSelf2.contentLock unlock];
            });
        };

        PEXGuiContextItemHolder *const deleteItemHolder = [[PEXGuiContextItemHolder alloc] init];
        deleteItemHolder.text = PEXStr(@"B_delete");
        deleteItemHolder.icon = PEXImg(@"trash");
        [actionsAndPresentations setObject:deleteItemHolder
                                    forKey:deleteMessage];

        // FORWARD MESSAGE
        void (^forwardMessage)(void) = ^{
            __typeof(self) sSelf2 = weakSelf;
            [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_POPUP_FORWARD];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [sSelf2.contentLock lock];
                const PEXMessageModel *const msg = [sSelf2 renewMessage:message];
                if (msg) {
                    if (msg.isFile) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [sSelf2 forwardFilesFromMessage:msg.message];
                        });
                    }
                    else {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [sSelf2 forwardMessage:msg.body];
                        });
                    }
                }
                [sSelf2.contentLock unlock];
            });
        };

        PEXGuiContextItemHolder *const forwardItemHolder = [[PEXGuiContextItemHolder alloc] init];
        forwardItemHolder.text = PEXStr(@"L_forward");
        forwardItemHolder.icon = PEXImg(@"broadcast");
        [actionsAndPresentations setObject:forwardItemHolder
                                    forKey:forwardMessage];

        // FILE PREVIEW
        const PEXMessageModel *const msg = [sSelf renewMessage:message];
        if (msg && msg.isFile) {
            NSArray *const fileUrls = [sSelf getFileUrlsForMessage:msg.message];
            NSArray *const qlItems = [PEXGuiPreviewExecutor extractQlItems:fileUrls];
            if (qlItems.count > 0) {
                void (^previewFiles)(void) = ^{
                    __typeof(self) sSelf2 = weakSelf;
                    [PEXReport logUsrButton:PEX_EVENT_BTN_MSG_POPUP_PREVIEW];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [sSelf2.contentLock lock];

                        if (qlItems.count == fileUrls.count) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [sSelf2 previewFile:qlItems];
                            });
                        }
                        else {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [PEXGuiFactory showTextBox:sSelf2.fullscreener
                                                  withText:PEXStr(@"txt_some_file_cannot_be_previewed")
                                                completion:^{
                                                    [sSelf2 previewFile:qlItems];
                                                }];
                            });
                        }

                        [sSelf2.contentLock unlock];
                    });
                };

                PEXGuiContextItemHolder *const previewFilesItemHolder = [[PEXGuiContextItemHolder alloc] init];
                previewFilesItemHolder.text = PEXStr(@"L_quick_preview");
                previewFilesItemHolder.icon = PEXImg(@"preview");
                [actionsAndPresentations setObject:previewFilesItemHolder
                                            forKey:previewFiles];
            }
        }

        // SHOW THE DIALOG
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            PEXGuiContextMenuViewController *menu = [[PEXGuiContextMenuViewController alloc] initWithActionsAndPresentations:actionsAndPresentations];
            menu.screenName = @"MessageMenu";
            [menu showInClosingWindow:weakSelf title:nil withUnaryListener:nil];
        });

        [sSelf.contentLock unlock];
    };

    [messageView setContextMenuAction: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), messageContextAction);
    }];
}

- (void) previewFile: (NSArray * const) qlItems
{
    [[PEXGNFC instance] unsetCurrentChatSip];
    self.previewHolderController = [PEXGVU showModalTransparentController];

    self.previewExecutor = [[PEXGuiPreviewExecutor alloc] initWithListener:self
                                                               superController:self.previewHolderController];
    [self.previewExecutor prepareWithActivityItems:qlItems];
    [self.previewExecutor present];
    [[PEXGuiShieldManager instance] addVictim:self.previewHolderController];
}

- (void)previewDidDismiss
{
    [[PEXGuiShieldManager instance] removeVictim:self.previewHolderController];

    WEAKSELF;
    [self.previewHolderController dismissViewControllerAnimated:true completion:^{
        weakSelf.previewHolderController = nil;
        weakSelf.previewExecutor = nil;
        [PEXGNFC instance].currentChatSip = self.contact.sip;
    }];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // cancel list loading
    _cancel = true;

    //cancel independent filedata loaders
    [self.operationQueue cancelAllOperations];

    PEXAppState * const appState = [PEXAppState instance];
    [appState.chatAccountingManager removeListener:self];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (NSArray *)getFileUrlsForMessage: (const PEXDbMessage * const) message
{
    PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance]
            query:[PEXDbReceivedFile getURI]
       projection:[PEXDbReceivedFile getFullProjection]
        selection:[PEXDbReceivedFile getWhereForMessage]
    selectionArgs:[PEXDbReceivedFile getWhereForMessageArgs:message]
        sortOrder:nil];

    NSMutableArray * const result = [[NSMutableArray alloc] init];

    while ([cursor moveToNext])
    {
        PEXDbReceivedFile * const receivedFile = [[PEXDbReceivedFile alloc] init];
        [receivedFile createFromCursor:cursor];

        NSURL * const url = [PEXGuiChatController getRefreshedSavedUrlForDbFile:receivedFile];

        if (url)
            [result addObject:url];
    }

    return result;
}

- (NSArray *)loadThumbsForMessage:(const PEXMessageModel *const)message
                         andFiles:(NSArray *const)receivedFiles
                      inOperation: (__weak const NSOperation * const) weakOperation
{
    if (weakOperation.isCancelled) return nil;

    NSMutableArray *result = [[NSMutableArray alloc] init];

    for (PEXDbReceivedFile * const receivedFile in receivedFiles)
    {
        if (weakOperation.isCancelled) return nil;
        UIImage * thumbnail = PEXImg(@"file");

        @try {
            if (message.isOutgoing.integerValue == 1) {
                NSURL *const refreshedUrl = [PEXGuiChatController getRefreshedSavedUrlForDbFile:receivedFile];
                const PEXFileData *const fileData = [PEXFileData fileDataFromUrl:refreshedUrl];
                thumbnail = fileData ? fileData.thumbnail : PEXImg(@"file");
            }
            else {
                NSString *const refreshedPath = [PEXDhKeyHelper getRefreshedThumbnailPath:receivedFile.thumbFileName];
                thumbnail = [PEXFileData generateThumbnailForNonAsset:refreshedPath];
            }

            [result addObject:thumbnail];
        } @catch(NSException * e){
            DDLogError(@"Exception in generating thumbnail %@", e);
        }
    }

    if (weakOperation.isCancelled) return nil;

    return result;
}

- (NSAttributedString *)detectDataInMessage: (const PEXMessageModel *const)message
                               withDetector: (NSDataDetector *) detector
                                inOperation: (__weak const NSOperation * const) weakOperation
                           patternsDetected: (NSUInteger *) patternsDetected
                          dataDetectedArray: (NSMutableArray<PEXInTextData *> *) detectedDataArray
{
    if (weakOperation.isCancelled) {
        return nil;
    }

    __block NSUInteger count = 0;

    // Start building attributed text.
    NSString * string = message.body;
    NSMutableAttributedString *attributedText = message.attributedString;

    // Enumeration action block.
    PEXEnumerateDataDetectorAction enumAction;
    enumAction = ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        const NSRange matchRange = [match range];
        PEXInTextData * inTextData = nil;

        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            inTextData = [PEXInTextDataLink linkWithUrl:url range:matchRange];

        } else if ([match resultType] == NSTextCheckingTypePhoneNumber) {
            NSString *phoneNumber = [match phoneNumber];
            inTextData = [PEXInTextDataPhoneNumber numberWithPhoneNumber:phoneNumber range:matchRange];

        }

        inTextData.match = match;
        if (inTextData == nil){
            return;
        }

        [detectedDataArray addObject:inTextData];

        // Add given attribute object to the text.
        //[attributedText addAttribute:CCHLinkAttributeName value:inTextData range:matchRange];
        if (++count >= 100) {
            *stop = YES;
        }
    };

    // Find data types in string.
    [detector enumerateMatchesInString:string
                               options:0
                                 range:NSMakeRange(0, [string length])
                            usingBlock:enumAction];

    if (patternsDetected != NULL){
        *patternsDetected = count;
    }

    return attributedText;
}

- (UIImage *)fileImage
{
    /**
     * After profiling we discovered loading same image for each message
     * again is significant overhead. This image can be reused for each message
     * so we load it once.
     */
    static UIImage * fileImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileImage = PEXImg(@"file");
    });

    return fileImage;
}

// return nil if saved is unreachable
+ (NSURL *) getRefreshedSavedUrlForDbFile: (const PEXDbReceivedFile * const) receivedFile
{
    return [PEXFileData getRefreshedSavedUrlForUrl:[NSURL URLWithString:receivedFile.path]
    isAsset: (receivedFile.isAsset.integerValue == 1)];
}

- (void)forwardFilesFromMessage: (const PEXDbMessage * const) message
{
    PEXGrandSelectionManager * const grandManager = [[PEXGrandSelectionManager alloc] init];
    grandManager.selectedFileContainers = [self getFileUrlsForMessage:message];

    PEXGuiFileSelectNavigationController* fileNavigation = [[PEXGuiFileSelectNavigationController alloc]
            initWithViewTitle:PEXStrU(@"L_choose_file")
                selectWithContacts:true
                      grandManager:grandManager];

    fileNavigation.completionEx =
            ^{
                [PEXGNFC instance].currentChatSip = self.contact.sip;
            };

    [fileNavigation prepareOnScreen:self];
    [fileNavigation show:self];

    [[PEXGNFC instance] unsetCurrentChatSip];
}

- (void) forwardMessage: (NSString * const) text
{
    PEXGrandSelectionManager * grandManager = [[PEXGrandSelectionManager alloc] init];
    grandManager.messageText = text;

    PEXGuiMessageComposerController * const composer =
                [[PEXGuiMessageComposerController alloc] init];

    PEXGuiBroadcastNavigationController * const navi =
                [[PEXGuiBroadcastNavigationController alloc] initWithViewController:composer
                                                                 composerController:composer grandManager:grandManager];

    navi.completionEx =
            ^{
                [PEXGNFC instance].currentChatSip = self.contact.sip;
            };

    [navi prepareOnScreen:self];
    [navi show:self];

    [[PEXGNFC instance] unsetCurrentChatSip];
}

- (void) preload
{
    [super preload];
    _contentLoaded = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:)
                                                 name:PEX_ACTION_FTRANSFET_UPDATE_PROGRESS_DB
                                               object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void) receiveNotification:(NSNotification * const) notification
{

    if (![[notification name] isEqualToString:PEX_ACTION_FTRANSFET_UPDATE_PROGRESS_DB])
        return;

    const PEXFtProgress *const progressInfo =
            notification.userInfo[PEX_EXTRA_FTRANSFET_UPDATE_PROGRESS_DB];

    [self.contentLock lock];

    PEXGuiMessageFileCell *cellToUpdate = nil;

    for (NSUInteger sectionIndex = 0; sectionIndex < self.datesAndMessages.count; ++sectionIndex)
    {
        NSArray<PEXMessageModel*> *const messages = [self.datesAndMessages objectsAt:sectionIndex];

        for (NSUInteger messageIndex = 0; messageIndex < messages.count; ++messageIndex)
        {
            const PEXMessageModel *const message = messages[messageIndex];

            if (progressInfo.messageId == message.id.longLongValue)
            {
                NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:messageIndex inSection:sectionIndex];

                if ([[self.collectionView indexPathsForVisibleItems] containsObject:indexPath])
                {
                    cellToUpdate = (PEXGuiMessageFileCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
                }

                break;
            }
        }

        if (cellToUpdate)
            break;
    }

    if (cellToUpdate) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self wrapCollectionViewUpdate:^{
                [((PEXGuiMessageFileView *) [cellToUpdate getSubview]) applyFtProgress:progressInfo];
            }];
        });
    }

    [self.contentLock unlock];
}

// KEYBOARD

- (void) keyboardWillHide:(NSNotification *)notification
{
    /*
     because of IPH-85 Selecting text in chat view hides the keyboard and breaks the UI
     the sliding logic was moved to youDidEndEditing and the notification details are
     stored in keyboardNotification
     */

    self.keyboardNotification = notification;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardNotification = notification;

    [super keyboardWillShow: notification];
}

- (void) hideKeyboard {
    [self.composerView resignFirstResponder];
}

- (void)youDidEndEditing
{
    [self slideToHide:self.keyboardNotification];

    [super youDidEndEditing];
}

- (void) viewDidAppear:(BOOL)animated
{
    self.screenName = @"Messages";
    [super viewDidAppear:animated];
}

@end