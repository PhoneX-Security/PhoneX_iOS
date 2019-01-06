//
// Created by Matej Oravec on 19/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageView.h"
#import "PEXGuiMessageView_Protected.h"
#import "PEXGuiImageView.h"
#import "PEXMessageModel.h"
#import "PEXStopwatch.h"
#import "PEXInTextData.h"
#import "PEXInTextDataLink.h"
#import "PEXInTextDataPhoneNumber.h"

#define PEX_MEESSAGE_OFFLINE_STATUS 202L

@interface PEXGuiMessageView () {
    int _currentReadAck;
    int _currentlyIngoing;
    int _lastlyIngoing;
    PEXMessageStatus const * _currentStatus;
}

@property (nonatomic, copy) void(^horizontalLayouter)(void);
@property (nonatomic, copy) void(^statusHorizontalLayouter)(void);

@end

@implementation PEXGuiMessageView

- (void) initGuiStuff
{
    self.V_bodyContainer = [[UIView alloc] init];
    [self addSubview:self.V_bodyContainer];

    self.timeView = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.timeView];

    self.readAck = [[PEXGuiImageView alloc] init];
    [self addSubview:self.readAck];

    self.statusView = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"light_gray_low")];

    [self addSubview:self.statusView];

    self.seenDateSet = nil;
    self.L_seen = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_seen];

    self.longClickRecognizer = [[PEXGuiLongBlockGestureRecognizer alloc] initWithBlock:nil];
    self.longClickRecognizer.delegate = self;

    self.clickRecognizer = [[PEXGuiBlockGestureRecognizer alloc] initWithBlock:nil];
    self.clickRecognizer.delegate = self;

    _currentReadAck = -1;
    _currentlyIngoing = -1;
    _lastlyIngoing = -2;
    _currentStatus = nil;
}

// The view is already widened by the parentController
- (void) setMessage: (const PEXMessageModel * const) message
{
    if (message.message.isOutgoing.integerValue) {
        [self setOutgoing];
    } else {
        [self setIncomming];
    }

    self.timeView.text = [PEXDateUtils dateToTimeString:message.date];

    [self setReadAckState:message.message];
    [self setStatusInternal:message.message];
}

-(void) setReadAckState: (const PEXDbMessage * const) message
{
    int readAckNew = 0;
    if ([message.isOutgoing boolValue] && [message.type integerValue] == PEXDBMessage_MESSAGE_TYPE_SENT){
        if ([message.read boolValue]){
            readAckNew = 1;
        } else {
            readAckNew = 2;
        }
    } else {
        readAckNew = 0;

    }

    // If setting the same value, do nothing. Optimization.
    if (_currentReadAck == readAckNew){
        return;
    }

    // Apply given change.
    if (readAckNew == 1){
        [self.readAck setImage:[self readAckImage]];

    } else if (readAckNew == 2){
        [self.readAck setImage:[self deliveredAckImage]];

    } else {
        [self.readAck setImage:nil];

    }

    _currentReadAck = readAckNew;
}

- (void) setSeen: (NSDate *) date
{
    self.seenDateSet = date;
}

- (void) clearMessage
{
    self.timeView.text = @"...";
    self.statusView.text = @"...";
    [self.readAck setImage:nil];
}

// @see needs update
- (void) setStatusInternal: (const PEXDbMessage * const) message
{
    [self setStatus: [PEXGuiMessageView getStatusFromMessage:message describeAll:false]];
}

+ (const PEXMessageStatus *) getStatusFromMessage: (const PEXDbMessage *const) message
                                      describeAll: (const bool) showAll
{
    PEXMessageStatus * const status = [[PEXMessageStatus alloc] init];

    // seen sent messages
    if ((message.read.integerValue == 1) && (message.isOutgoing.integerValue == 1))
    {
        status.nameDescription = (showAll ?  PEXStr(@"L_message_seen") : @"");
        status.type = PEX_MESSAGE_STATUS_TYPE_NORMAL;
    }
    else
    {

        status.type = PEX_MESSAGE_STATUS_TYPE_CAUTION;

        switch (message.type.integerValue)
        {
            case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED:
                //status.nameDescription = showAll ? PEXStr(@"L_message_downloaded") : @"";
                //status.type = PEX_MESSAGE_STATUS_TYPE_NORMAL;
                //break;
            case PEXDBMessage_MESSAGE_TYPE_INBOX:
                status.nameDescription =
                        (showAll ?
                        (message.isOffline.boolValue ?
                                [NSString stringWithFormat:@"%@ (%@)", PEXStr(@"L_message_received"), PEXStr(@"L_offline")] :
                                PEXStr(@"L_message_received"))
                        : (message.isOffline.boolValue ? [NSString stringWithFormat:@"(%@)", PEXStr(@"L_offline")] :
                                @""));
                status.type = PEX_MESSAGE_STATUS_TYPE_NORMAL;
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_READY:
                // See IPH-219 ... Outgoing && Ready
                status.nameDescription =
                        (message.isOutgoing.integerValue == 0) ?
                                PEXStr(@"L_message_ready") :
                                PEXStr(@"L_message_queued_backoff");
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADED:
                //status.nameDescription =
                //(message.errorCode.integerValue == PEX_MEESSAGE_OFFLINE_STATUS) ?
                //[NSString stringWithFormat:@"%@ (%@)", PEXStr(@"L_message_uploaded"), PEXStr(@"L_offline")] :
                //PEXStr(@"L_message_sent");
                //break;
            case PEXDBMessage_MESSAGE_TYPE_SENT:
                status.nameDescription =
                        (showAll ?
                                (message.errorCode.integerValue == PEX_MEESSAGE_OFFLINE_STATUS ?
                                        [NSString stringWithFormat:@"%@ (%@)", PEXStr(@"L_message_sent"), PEXStr(@"L_offline")] :
                                        PEXStr(@"L_message_sent"))
                                : (message.errorCode.integerValue == PEX_MEESSAGE_OFFLINE_STATUS ? [NSString stringWithFormat:@"%@ (%@)", PEXStr(@"L_message_sent"), PEXStr(@"L_offline")] :
                                        @""));
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOAD_FAIL:
                //status.nameDescription = PEXStr(@"L_message_upload_failed");
                //status.type = PEX_MESSAGE_STATUS_TYPE_CRITICAL;
                //break;
            case PEXDBMessage_MESSAGE_TYPE_FAILED:
                status.nameDescription = PEXStr(@"L_message_failed");
                status.type = PEX_MESSAGE_STATUS_TYPE_CRITICAL;
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOAD_FAIL:
                //status.nameDescription = PEXStr(@"L_message_download_error");
                //break;
            case PEXDBMessage_MESSAGE_TYPE_FILE_ERROR_RECEIVING:
                status.nameDescription = PEXStr(@"L_message_receiving_error");
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_REJECTED:
                status.nameDescription = PEXStr(@"L_message_rejected");
                status.type = PEX_MESSAGE_STATUS_TYPE_CRITICAL;
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING:
                //status.nameDescription = PEXStr(@"L_message_uploading");
                //break;
            case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING_FILES:
                //status.nameDescription = PEXStr(@"L_message_uploading");
                //break;
            case PEXDBMessage_MESSAGE_TYPE_PENDING:
                //status.nameDescription = PEXStr(@"L_message_pending");
                //break;
            case PEXDBMessage_MESSAGE_TYPE_QUEUED:
                //status.nameDescription = PEXStr(@"L_message_queued");
                //break;
                status.nameDescription = PEXStr(@"L_message_sending");
                break;

            case PEXDBMessage_MESSAGE_TYPE_ENCRYPT_FAIL:
                status.nameDescription =
                        (message.errorCode.integerValue == PEXDBMessage_ERROR_MISSING_CERT) ?
                                PEXStr(@"L_message_encrypt_no_certificate") :
                                PEXStr(@"L_message_encrypt_failed");

                status.type = PEX_MESSAGE_STATUS_TYPE_CRITICAL;
                break;

            case PEXDBMessage_MESSAGE_TYPE_QUEUED_BACKOFF:
                status.nameDescription = PEXStr(@"L_message_queued_backoff");
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING:
                status.nameDescription = PEXStr(@"L_message_downloading");
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META:
                status.nameDescription = PEXStr(@"L_message_downloading_meta");
                break;

            case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META:
                status.nameDescription = PEXStr(@"L_message_downloaded_meta");
                break;

                // HEH? See Android Project fo inspiration
                // case PEXDBMessage_DECRYPTION_STATUS_NOT_DECRYPTED:
                // case PEXDBMessage_DECRYPTION_STATUS_DECRYPTION_ERROR:
                // case PEXDBMessage_DECRYPTION_STATUS_NO_ENCRYPTION:
                // case PEXDBMessage_DECRYPTION_STATUS_OK

            default:
                status.nameDescription = @"L_message_UNKNOWN_STATE";
                status.type = PEX_MESSAGE_STATUS_TYPE_CRITICAL;
        }
    }

    return status;
}

- (void) setStatus: (PEXMessageStatus const *) status
{
    if (_currentStatus != nil && [_currentStatus isEqualToStatus:status]){
        return;
    }

    self.statusView.text = status.nameDescription;

    UIColor * textColor;
    switch (status.type)
    {
        case PEX_MESSAGE_STATUS_TYPE_NORMAL: textColor = PEXCol(@"light_gray_low"); break;
        case PEX_MESSAGE_STATUS_TYPE_CRITICAL: textColor = PEXCol(@"red_low"); break;
        case PEX_MESSAGE_STATUS_TYPE_CAUTION: textColor = PEXCol(@"orange_low"); break;
    }

    self.statusView.text = status.nameDescription;
    self.statusView.textColor = textColor;
    _currentStatus = status;

    self.statusHorizontalLayouter();
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat distance = PEXVal(@"dim_size_nano");

    [PEXGVU setHeight:self to:
            self.V_bodyContainer.frame.size.height +
                    self.timeView.frame.size.height +
                    distance + (3 * distance) + // - time/status - body -
                    (self.seenDateSet ? distance + PEXVal(@"dim_size_small_medium") : 0.0f)]; // seen -

    if (self.seenDateSet)
    {
        self.L_seen.text = [NSString stringWithFormat:@"%@ %@", PEXStr(@"L_seen"), [PEXDateUtils dateToTimeString:self.seenDateSet]];
        [PEXGVU moveToBottom:self.self.L_seen withMargin:distance];
        [PEXGVU move:self.V_bodyContainer above:self.L_seen withMargin:distance];
    }
    else
    {
        self.L_seen.text = nil;
        [PEXGVU moveToBottom:self.V_bodyContainer withMargin:distance];
    }

    [PEXGVU move:self.statusView above:self.V_bodyContainer withMargin:distance];
    [PEXGVU move:self.timeView above:self.V_bodyContainer withMargin:distance];
    [PEXGVU move:self.readAck above:self.V_bodyContainer withMargin:distance];

    if (self.statusHorizontalLayouter)
        self.statusHorizontalLayouter();
    if (self.horizontalLayouter)
        self.horizontalLayouter();
}

/// OUTGOING

- (void) setOutgoing
{
    WEAKSELF;
    _currentlyIngoing = 0;
    self.statusHorizontalLayouter = ^{
        [weakSelf layoutStatusHorizontalOutgoing];
    };

    self.horizontalLayouter = ^{
        [weakSelf layoutGeneralHorizontalOutgoing];
    };
}

- (void) setIncomming
{
    WEAKSELF;
    _currentlyIngoing = 1;
    self.statusHorizontalLayouter = ^{
        [weakSelf layoutStatusHorizontalIncoming];
    };

    self.horizontalLayouter = ^{
        [weakSelf layoutGeneralHorizontalIncoming];
    };
}

- (void) layoutStatusHorizontalOutgoing
{
    [PEXGVU move:self.statusView leftOf:self.timeView withMargin:PEX_PARGIN];
}

- (void) layoutGeneralHorizontalOutgoing
{
    [PEXGVU moveToRight:self.V_bodyContainer withMargin:PEX_PARGIN];
    [PEXGVU moveToRight:self.readAck withMargin:PEX_PARGIN];
    [PEXGVU move:self.timeView leftOf:self.readAck];

    if (self.seenDateSet)
        [PEXGVU moveToRight:self.L_seen withMargin:PEX_PARGIN];

    self.V_bodyContainer.backgroundColor = PEXCol(@"light_gray_high");
}

/// INCOMING

- (void) layoutStatusHorizontalIncoming
{
    [PEXGVU move:self.statusView rightOf: self.timeView withMargin:PEX_PARGIN];
}

- (void) layoutGeneralHorizontalIncoming
{
    [PEXGVU moveToLeft:self.V_bodyContainer withMargin:PEX_PARGIN];
    [PEXGVU moveToLeft:self.timeView withMargin:PEX_PARGIN];

    if (self.seenDateSet)
        [PEXGVU moveToLeft:self.L_seen withMargin:PEX_PARGIN];

    self.V_bodyContainer.backgroundColor = PEXCol(@"light_orange_normal");
}

// TODO some interface for all components
- (CGFloat) staticHeight
{
    return self.frame.size.height;
}

+ (bool) message: (const PEXDbMessage * const) m1
     needsUpdate: (const PEXDbMessage * const) m2
{
    if (![m1.type isEqualToNumber: m2.type]) return true;
    if (![m1.read isEqualToNumber: m2.read]) return true;
    if (![m1.errorCode isEqualToNumber: m2.errorCode]) return true;
    if (![m1.readDate isEqualToDate: m2.readDate]) return true;

    return false;
}

+ (void) updateMessage: (const PEXDbMessage * const) m1
                  with: (const PEXDbMessage * const) m2
{
    m1.type = m2.type;
    m1.read = m2.read;
    m1.errorCode = m2.errorCode;

    // with status ?
    m1.readDate = m2.readDate;
}

- (UIImage *)deliveredAckImage
{
    /**
     * After profiling we discovered loading same image for each message
     * again is significant overhead. This image can be reused for each message
     * so we load it once.
     */
    static UIImage * ackImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ackImage = PEXImg(@"check2");
    });
    
    return ackImage;
}

- (UIImage *)readAckImage
{
    /**
     * After profiling we discovered loading same image for each message
     * again is significant overhead. This image can be reused for each message
     * so we load it once.
     */
    static UIImage * rackImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rackImage = PEXImg(@"doublecheck");
    });
    
    return rackImage;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Defining click area here.
    const CGFloat verticalPadding = PEXVal(@"dim_size_nano");
    const CGPoint touchPoint = [touch locationInView:self];

    // Height is determined by the bottom of the body container.
    // Clicking on date/status should also be considered as clicking a message.
    // But action buttons for file transfer need to be excluded.
    // Width is determined by body container as the main view occupies the whole row.
    // It can be annoying to invoke actions when clicking totally outside the message body (horizontally).
    const CGFloat x = _currentlyIngoing == 1 ? self.frame.origin.x : self.V_bodyContainer.frame.origin.x - PEXVal(@"dim_size_large");
    const CGFloat y = self.frame.origin.y + verticalPadding;
    const CGFloat width = self.V_bodyContainer.frame.size.width + 2*PEXVal(@"dim_size_large");
    const CGFloat height = self.V_bodyContainer.frame.origin.y + self.V_bodyContainer.frame.size.height - verticalPadding;
    const CGRect allowedClickingRect = CGRectMake(x, y, width, height);

    return CGRectContainsPoint(allowedClickingRect, touchPoint);
}

- (void)updateGestureRecognizers {
    NSArray * recognizers = @[];

    const BOOL hasClickAction = [self.clickRecognizer hasAction];
    const BOOL hasLongClickAction = [self.longClickRecognizer hasAction];
    if (hasClickAction && hasLongClickAction){
        [self.clickRecognizer requireGestureRecognizerToFail:self.longClickRecognizer];
        recognizers = @[self.clickRecognizer, self.longClickRecognizer];

    } else if (hasClickAction){
        recognizers = @[self.clickRecognizer];

    } else if (hasLongClickAction){
        recognizers = @[self.longClickRecognizer];

    }

    [self setGestureRecognizers:recognizers];
}

- (void)setContextMenuAction:(dispatch_block_t)action {
    [self setClickAction:action];
}

- (void)invokeClickAction {
    [self.clickRecognizer executeTheAction];
}

- (void)setLongClickAction:(dispatch_block_t)action {
    [self.longClickRecognizer setAction:action];
    [self updateGestureRecognizers];
}

- (void)setClickAction:(dispatch_block_t)action {
    [self.clickRecognizer setAction:action];
    [self updateGestureRecognizers];
}

- (void)updateMessage:(const PEXDbMessage *const)message {
    DDLogError(@"Not implemented");
}

- (void)prepareForReuse {
    [self.clickRecognizer setAction:nil];
    [self.longClickRecognizer setAction:nil];
}

@end
