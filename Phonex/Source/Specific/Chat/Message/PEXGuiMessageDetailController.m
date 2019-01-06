//
//  PEXGuiMessageDetailController.m
//  Phonex
//
//  Created by Matej Oravec on 20/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageDetailController.h"
#import "PEXGuiController_Protected.h"

#import "PEXDbMessage.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXMessageModel.h"
#import "PEXGuiDetailView.h"

#import "PEXGuiMessageTextOnlyView.h"

#import "PEXDateUtils.h"
#import "PEXDbReceivedFile.h"
#import "PEXGuiFileUtils.h"
#import "PEXGuiBaseLabel.h"
#import "PEXGuiClassicLabel.h"
#import "UITextView+PEXPaddings.h"
#import "PEXUtils.h"
#import "PEXMessageDigest.h"

@interface PEXGuiMessageDetailController ()

@property (nonatomic) const PEXMessageModel * message;

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiDetailView * V_from;
@property (nonatomic) PEXGuiDetailView * V_to;
@property (nonatomic) PEXGuiDetailView * V_status;
@property (nonatomic) PEXGuiDetailView * V_seen;

@property (nonatomic) PEXGuiDetailView * V_sent;
@property (nonatomic) PEXGuiDetailView * V_received;

@property (nonatomic) PEXGuiDetailView * V_totalSize;

@property (nonatomic) UIView * V_filesTitle;
@property (nonatomic) PEXGuiBaseLabel *L_filesTitle;
@property (nonatomic) PEXGuiReadOnlyTextView * V_files;

@property (nonatomic) CGFloat subViewMaxHeight;
@property (nonatomic) CGFloat subViewMaxWidth;
@end

@implementation PEXGuiMessageDetailController

- (id) initWithMessage: (const PEXMessageModel * const) message
{
    self = [super init];

    self.message = message;
    self.subViewMaxHeight = 0;
    self.subViewMaxWidth = 0;
    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"MessageDetail";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{

        self.V_from = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_from];

        self.V_to = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_to];

        self.V_status = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_status];

        self.V_sent = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_sent];

        if (self.message.isOutgoing.integerValue == 0) {
            self.V_received = [[PEXGuiDetailView alloc] init];
            [self.linearView addView:self.V_received];
        }

        self.V_seen = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.V_seen];

        if ([self hasFiles]){
            self.V_totalSize = [[PEXGuiDetailView alloc] init];
            [self.linearView addView:self.V_totalSize];

            self.L_filesTitle = [[PEXGuiClassicLabel alloc]
                    initWithFontSize:PEXVal(@"dim_size_small_medium")
                           fontColor:PEXCol(@"light_gray_low")];
            self.L_filesTitle.text = PEXStrU(@"L_files");
            [self.L_filesTitle sizeToFit];

            self.V_filesTitle = [[UIView alloc] init];
            [PEXGVU setHeight: self.V_filesTitle
                           to: self.L_filesTitle.frame.size.height + PEXVal(@"dim_size_medium")];
            [self.V_filesTitle addSubview:self.L_filesTitle];
            [self.linearView addView:self.V_filesTitle];

            self.V_files = [[PEXGuiReadOnlyTextView alloc] init];
            [self.linearView addView:self.V_files];
        }
    }];
}

- (void) initContent
{
    [super initContent];

    PEXDbMessage * msg = self.message.message;
    [self.V_from setName:PEXStrU(@"L_from")];
    [self.V_from setValue:msg.from];

    [self.V_to setName:PEXStrU(@"L_to")];
    [self.V_to setValue:msg.to];

    [self.V_status setName:PEXStrU(@"L_status")];
    const PEXMessageStatus * const status = [PEXGuiMessageTextOnlyView getStatusFromMessage:msg describeAll:true];
    [self.V_status setValue: status.nameDescription];

    [self.V_sent setName:PEXStrU(@"L_message_sent")];
    [self.V_sent setValue:[self dateToText: msg.sendDate]];

    [self.V_seen setName:PEXStrU(@"L_seen")];
    [self.V_seen setValue:[self dateToText: (msg.read.integerValue == 1) ? msg.readDate : nil]];

    if (self.message.isOutgoing.integerValue == 0) {
        [self.V_received setName:PEXStrU(@"L_message_received")];
        [self.V_received setValue:[self dateToText: msg.date]];
    }

    if ([self hasFiles]){
        [self.V_totalSize setName:PEXStrU(@"L_total_size")];
        [self.V_totalSize setValue:[[self getTotalSize] description]];

        self.L_filesTitle.text = PEXStrU(@"L_files");
    }
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.V_from];
    [PEXGVU scaleHorizontally:self.V_to];
    [PEXGVU scaleHorizontally:self.V_status];
    [PEXGVU scaleHorizontally:self.V_sent];
    [PEXGVU scaleHorizontally:self.V_seen];
    if (self.message.isOutgoing.integerValue == 0) {
        [PEXGVU scaleHorizontally:self.V_received];
    }
    if ([self hasFiles]){
        [PEXGVU scaleHorizontally:self.V_totalSize];
        [PEXGVU scaleHorizontally: self.V_filesTitle];
        [PEXGVU moveToLeft:self.L_filesTitle withMargin:PEXVal(@"dim_size_large")];
        [PEXGVU moveToBottom:self.L_filesTitle];

        [PEXGVU scaleHorizontally: self.V_files withMargin:PEXVal(@"dim_size_medium")];
        [self.V_files setPaddingNumTop:@(0.0f) left:@(0.0f) bottom:nil rigth:@(0.0f)];

        [self.linearView removeView:self.V_files];
        [self.V_files.textContainer setLineBreakMode:NSLineBreakByCharWrapping];
        [self.V_files setAttributedText:[self buildFilePreview]];
        [self.V_files sizeToFit];
        [self.linearView addView:self.V_files];

        // Resize if needed.
        [self adjustToMaxHeight];
        [PEXGVU scaleFull:self.linearView];
    }
}

- (void) initBehavior
{
    [super initBehavior];

    [self.V_from setEnabled:false];
    [self.V_to setEnabled:false];
    [self.V_status setEnabled:false];
    [self.V_sent setEnabled:false];
    [self.V_seen setEnabled:false];
    if (self.message.isOutgoing.integerValue == 0) {
        [self.V_received setEnabled:false];
    }
    if ([self hasFiles]){
        [self.V_totalSize setEnabled:false];
        [self.V_files setScrollEnabled:false];
    }
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    self.subViewMaxHeight = [parent subviewMaxHeight];
    self.subViewMaxWidth = [parent subviewMaxWidth];
    [self adjustToMaxHeight];
}

- (void) adjustToMaxHeight {
    const CGFloat contentHeight = self.linearView.contentSize.height;
    const CGFloat maxHeight = self.subViewMaxHeight <= 0 ? contentHeight : self.subViewMaxHeight;

    const CGFloat contentWidth = self.linearView.contentSize.width;
    const CGFloat maxWidth = self.subViewMaxWidth <= 0 ? contentWidth : self.subViewMaxWidth;

    [PEXGVU setSize:self.mainView
                  x:maxWidth
                  y:MIN(maxHeight, contentHeight)];
}

- (NSString *) dateToText: (NSDate *) date {
    if (date == nil || [date timeIntervalSince1970] < 10000){
        return @" - ";
    }

    return [NSString stringWithFormat:@"%@ %@",
                               [PEXDateUtils dateToTimeString:date],
                               [PEXDateUtils dateToDateString:date]];
}

- (BOOL) hasFiles {
    return [self.message isFile] && self.message.receivedFiles != nil && [self.message.receivedFiles count] > 0;
}

- (PEXGuiFileRepresentation * ) getTotalSize {
    uint64_t totalSize = 0;
    for(PEXDbReceivedFile * file in self.message.receivedFiles){
        totalSize += (uint64_t)[file.size longLongValue];
    }

    return [PEXGuiFileUtils bytesToRepresentation:totalSize];
}

- (NSAttributedString *) buildFilePreview {
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] init];
    NSAttributedString * newline = [[NSAttributedString alloc] initWithString: @"\n"];

    NSDictionary * fileNameAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")],  // dim_size_medium
            //NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };

    NSDictionary * fileAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:PEXVal(@"dim_size_small_medium")],
            NSForegroundColorAttributeName : PEXCol(@"light_gray_low")
    };

    NSUInteger cntFiles = [self.message.receivedFiles count];
    NSUInteger idx = 0;
    uint64_t totalSize = 0;
    for(PEXDbReceivedFile * file in self.message.receivedFiles){
        const BOOL last = idx+1 == cntFiles;

        totalSize += (uint64_t)[file.size longLongValue];
        PEXGuiFileRepresentation * frepr = [PEXGuiFileUtils bytesToRepresentation:(uint64_t)[file.size longLongValue]];
        NSString * hexHash = [PEXMessageDigest base64ToHex:file.fileHash];

        NSAttributedString * fname = [[NSAttributedString alloc] initWithString: file.fileName
                                                                     attributes:fileNameAttributes];

        NSString * hashString = [NSString stringWithFormat:@"SHA-256:\u00A0%@", hexHash];

        // In case of a preview, show meta hash
        if (hexHash == nil){
            NSString * hexMetaHash = [PEXMessageDigest base64ToHex:file.fileMetaHash];
            hashString = [NSString stringWithFormat:@"SHA-256:\u00A0%@", hexMetaHash];
        }

        NSAttributedString * fhash = hashString == nil ? nil :[[NSAttributedString alloc] initWithString: hashString
                                                                                              attributes:fileAttributes];

        NSString * sizeAndMime = [NSString stringWithFormat:@"%@, %@", [frepr description], file.mimeType];
        NSAttributedString * fsize = [[NSAttributedString alloc] initWithString:sizeAndMime
                                                                     attributes:fileAttributes];

        [str appendAttributedString:fname];
        [str appendAttributedString:newline];

        [str appendAttributedString:fsize];
        [str appendAttributedString:newline];

        if (fhash != nil) {
            [str appendAttributedString:fhash];
        }

        if (!last){
            [str appendAttributedString:newline];
            [str appendAttributedString:newline];
        }

        ++idx;
    }

    return str;
}

@end
