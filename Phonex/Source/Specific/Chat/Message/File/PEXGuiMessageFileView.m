//
//  PEXGuiMessageFileView.m
//  Phonex
//
//  Created by Matej Oravec on 11/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageFileView.h"
#import "PEXGuiMessageView_Protected.h"

#import "PEXGuiProgressBar.h"
#import "PEXGuiImageView.h"

#import "PEXGuiCentricButtonView.h"
#import "PEXRefDictionary.h"
#import "PEXGuiNegCrossView.h"
#import "PEXGuiTick.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiThumailView.h"
#import "PEXGuiSimpleFileView.h"
#import "PEXReport.h"
#import "PEXMessageModel.h"
#import "PEXGuiMessageTextBodyTextView.h"

#define PEX_GUI_FILE_VIEW_POOL_SIZE 5
@interface PEXGuiMessageFileView ()
{
    NSMutableArray<PEXGuiSimpleFileView*> * _fileViewPool;
}

@property (nonatomic) PEXGuiCentricButtonView * B_accept;
@property (nonatomic) PEXGuiCentricButtonView * B_reject;
@property (nonatomic) PEXGuiCentricButtonView * B_cancel;
@property (nonatomic) UIView * V_actionsContainer;

@property (nonatomic) PEXGuiProgressBar * PV_Progress;

@property (nonatomic) PEXGuiLinearRollingView * C_namesAndThumbs;
@property (nonatomic) PEXGuiMessageTextBodyView * TV_body;
@property (nonatomic, copy) void (^contentLayouter)(void);

@end

@implementation PEXGuiMessageFileView

- (void) setAcceptBlock: (void (^)(void))block
{
    [self.B_accept addActionBlock:block];
}

- (void) setCancelBlock: (void (^)(void))block
{
    [self.B_cancel addActionBlock:block];
}

- (void) setRejectBlock: (void (^)(void))block
{
    [self.B_reject addActionBlock:block];
}

- (void) setVisibleReceiveOptions: (const bool) visible
{
    [self.B_accept setHidden:!visible];
    [self.B_reject setHidden:!visible];
}

- (void) setVisibleCancelOption: (const bool) visible
{
    [self.B_cancel setHidden:!visible];
}

- (void) showActions: (const bool) visible
{
    if ((!self.V_actionsContainer.isHidden) ^ visible)
        [self.V_actionsContainer setHidden:!visible];
}

- (void) setVisibleProgress: (const bool) visible
{
    [self.PV_Progress setHidden:!visible];
    if (visible)
        [self.PV_Progress.superview bringSubviewToFront:self.PV_Progress];
}

- (void) initGuiStuff
{
    [super initGuiStuff];

    self.PV_Progress = [[PEXGuiProgressBar alloc] init];
    self.PV_Progress.trackTintColor = PEXCol(@"invisible");
    [self addSubview: self.PV_Progress];

    self.V_actionsContainer = [[UIView alloc] init];
    [self addSubview:self.V_actionsContainer];

    UIView * const tick = [[PEXGuiImageView alloc] initWithImage: [self saveGreenImage]];

    self.B_accept = [[PEXGuiCentricButtonView alloc] initWithImage:tick];
    [self.V_actionsContainer addSubview:self.B_accept];

    self.B_reject = [[PEXGuiCentricButtonView alloc] initWithImage:[[PEXGuiNegCrossView alloc]
                                                                    initWithColor:PEXCol(@"red_normal")]];
    [self.V_actionsContainer addSubview:self.B_reject];

    self.B_cancel = [[PEXGuiCentricButtonView alloc] initWithImage:[[PEXGuiNegCrossView alloc]
                                                                    initWithColor:PEXCol(@"red_normal")]];
    [self.V_actionsContainer addSubview:self.B_cancel];

    [self.V_actionsContainer setHidden:true];
    [self setVisibleProgress:false];
    [self setVisibleCancelOption:false];
    [self setVisibleReceiveOptions:false];

    _fileViewPool = [[NSMutableArray alloc] initWithCapacity:PEX_GUI_FILE_VIEW_POOL_SIZE];

    self.C_namesAndThumbs = [[PEXGuiLinearRollingView alloc] init];
    self.C_namesAndThumbs.userInteractionEnabled = NO;
    [self.V_bodyContainer addSubview:self.C_namesAndThumbs];

    self.TV_body = [[PEXGuiMessageTextBodyView alloc] initWithFrame:CGRectZero];
    self.TV_body.backgroundColor = PEXCol(@"invisible");
    [self.V_bodyContainer addSubview:self.TV_body];
}

/****************/
/* LAYOUT START */
/****************/

- (void) layoutSubviews
{
    //const CGFloat height = PEXVal(@"tab_height");
    //const CGFloat width = 2.0f * height;

    const CGFloat actionsHeight = PEXVal(@"tab_height");
    const CGFloat actionsWidth = 2.0f * actionsHeight;

    [PEXGVU setWidth:self.V_bodyContainer to:self.frame.size.width - (2 * PEX_PARGIN)];

    if (self.contentLayouter)
        self.contentLayouter();

    // actions
    [PEXGVU setSize:self.V_actionsContainer x:actionsWidth y:actionsHeight];

    //const CGFloat size = height;
    const CGFloat size = actionsHeight;

    [PEXGVU setSize:self.B_accept x:size y:size];
    [PEXGVU setSize:self.B_reject x:size y:size];
    [PEXGVU setSize:self.B_cancel x:size y:size];

    [PEXGVU moveToRight:self.B_cancel];
    [PEXGVU moveToRight:self.B_reject];
    [PEXGVU moveToLeft:self.B_accept];

    [PEXGVU scaleHorizontally:self.PV_Progress on:self.V_bodyContainer];

    // relayout all super stuff
    [super layoutSubviews];

    if (!self.V_actionsContainer.isHidden)
    {
        [PEXGVU setHeight:self to:self.frame.size.height + actionsHeight];

        [PEXGVU moveToRight:self.V_actionsContainer];
        [PEXGVU moveToRight:self.B_cancel];
        [PEXGVU moveToBottom:self.V_actionsContainer];
    }
    else
    {
        //[PEXGVU setHeight:self to:self.frame.size.height - actionsHeight];
    }

    [PEXGVU move:self.PV_Progress below:self.V_bodyContainer];
}

// call only on ready >= or uploaded
- (void)setNamesAndThumbs: (NSArray * const)namesAndThumb
                  message:(const PEXMessageModel * const) message
{
    self.TV_body.hidden = YES;
    self.C_namesAndThumbs.hidden = NO;

    NSMutableArray<PEXGuiSimpleFileView *> * viewsToAddToCollection = [[NSMutableArray alloc] init];
    const int existingContainers = [self.C_namesAndThumbs count];

    NSUInteger containerIdx = 0;
    const NSUInteger thumbCount = namesAndThumb.count / 2;
    for (NSUInteger i = 0; i < namesAndThumb.count; ++i) {
        NSString * const name = namesAndThumb[i];
        UIImage * const thumb = namesAndThumb[++i];

        PEXGuiSimpleFileView * itemView = nil;
        if (containerIdx >= existingContainers){
            // New container has to be configured & added to the view.
            // Try obtain one from the pool.
            itemView = [_fileViewPool lastObject];
            if (itemView == nil) {
                itemView = [[PEXGuiSimpleFileView alloc] init];
                [itemView initGui];

            } else {
                [_fileViewPool removeLastObject];
            }

            [viewsToAddToCollection addObject:itemView];

        } else {
            // Already in the view - reuse it.
            itemView = (PEXGuiSimpleFileView *)[self.C_namesAndThumbs getViewAtIndex:containerIdx];
        }

        [itemView applyThumb:thumb filename:name];
        itemView.backgroundColor = PEXCol(@"invisible");
        containerIdx += 1;
    }

    // Add new views, remove old views.
    WEAKSELF;
    if (existingContainers > thumbCount || [viewsToAddToCollection count] > 0) {
        [PEXGVU executeWithoutAnimations:^{
            for (PEXGuiSimpleFileView *itemView in viewsToAddToCollection) {
                [weakSelf.C_namesAndThumbs addView:itemView];
            }

            for (NSInteger idx = 0; existingContainers > thumbCount && idx < (existingContainers - thumbCount); ++idx) {
                PEXGuiSimpleFileView *itemView = (PEXGuiSimpleFileView *) [weakSelf.C_namesAndThumbs removeLastView];
                if ([_fileViewPool count] < PEX_GUI_FILE_VIEW_POOL_SIZE) {
                    [_fileViewPool addObject:itemView];
                }
            }
        }];
    }

    self.contentLayouter = ^{
        [weakSelf layoutNamesAndThumbs];
    };

    [super setMessage:message];
}

- (void) clean
{
    self.C_namesAndThumbs.hidden = YES;
    self.TV_body.hidden = YES;
}

- (void) layoutNamesAndThumbs
{
    [PEXGVU scaleHorizontally:self.C_namesAndThumbs];

    for (UIView * const view in self.C_namesAndThumbs.subviews)
        [PEXGVU scaleHorizontally:view];

    [PEXGVU setHeight:self.V_bodyContainer to:self.C_namesAndThumbs.frame.size.height];
}

// The view is already widened by the parentController
- (void) setMessage: (const PEXMessageModel * const) message
{
    [self clean];
    self.TV_body.hidden = NO;
    self.TV_body.text = message.body;

    WEAKSELF;
    self.contentLayouter = ^{
        [weakSelf layoutTextBody];
    };

    [super setMessage:message];
}

- (void) layoutTextBody
{
    [PEXGVU scaleHorizontally:self.TV_body];
    [self.TV_body sizeToFit];

    [PEXGVU setWidth:self.V_bodyContainer to:self.TV_body.frame.size.width];
    [PEXGVU setHeight:self.V_bodyContainer to:self.TV_body.frame.size.height];
}

/****************/
/* LAYOUT END   */
/****************/

- (void) applyFtProgress:(const PEXFtProgress * const) progress
{
    [self.PV_Progress setProgress: (((float)progress.progress) / 100.0f)];


    DDLogDebug(@"PROGRESS: %d", progress.progress);
}

- (void) layoutGeneralHorizontalOutgoing
{
    [super layoutGeneralHorizontalOutgoing];
}

- (void) layoutGeneralHorizontalIncoming
{
    [super layoutGeneralHorizontalIncoming];
}

// called at UPDATE and SETMESSAGE
- (void) setStatusInternal: (const PEXDbMessage * const) message
{
    [super setStatusInternal:message];

    const NSInteger messageType = message.type.integerValue;
    const bool isOutgoing = (message.isOutgoing.integerValue == 1);
    const bool isReady = (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_READY);

    const bool fileTransferIsInProgressSomehow =
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING ||
                    messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META ||
                    messageType == PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING_FILES ||
                    messageType == PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING);

    // See IPH-219 ... Outgoing && Ready
    const bool fileIsReadyToDownload =
            ((isReady && !isOutgoing) ||
            messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META);

    const bool uploadedFileIsBeingResendOnFailure = isOutgoing && isReady;

    // action panel in general
    [self showActions:fileTransferIsInProgressSomehow || fileIsReadyToDownload || uploadedFileIsBeingResendOnFailure];
    [self setVisibleReceiveOptions: fileIsReadyToDownload];

    [self setVisibleProgress: fileTransferIsInProgressSomehow];
    [self setVisibleCancelOption: fileTransferIsInProgressSomehow || uploadedFileIsBeingResendOnFailure];
}

- (bool)hasThumbs
{
    return self.C_namesAndThumbs != nil;
}

+ (bool) messageReadyForThumbnails: (const PEXDbMessage * const) message
{
    const NSInteger messageType = message.type.integerValue;

    return (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING_FILES) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADED) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_READY) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_FILE_REJECTED) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_SENT) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_PENDING) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_QUEUED) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_QUEUED_BACKOFF) ||
            (messageType == PEXDBMessage_MESSAGE_TYPE_INBOX);
}

- (UIImage *)saveGreenImage
{
    /**
     * After profiling we discovered loading same image for each message
     * again is significant overhead. This image can be reused for each message
     * so we load it once.
     */
    static UIImage * saveGreenImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        saveGreenImage = PEXImg(@"save_green");
    });

    return saveGreenImage;
}

@end
