//
// Created by Dusan Klinec on 24.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "PEXGuiFileDetailController.h"
#import "PEXFileData.h"
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
#import "PEXGuiThumailView.h"
#import "PEXService.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "UIViewController+PEXRelayout.h"
#import "PEXGuiUtils.h"
#import "PEXGuiPreviewExecutor.h"
#import "PEXGuiShieldManager.h"

@interface PEXGuiFileDetailController () <PEXGuiPreviewDelegate>
@property (nonatomic) PEXFileData const * const file;
@property (nonatomic) NSData * fileSha256;
@property (nonatomic) NSString * UTI;
@property (nonatomic) NSString * mime;
@property (nonatomic) UIImage * nThumb;
@property (nonatomic) BOOL dataLoaded;

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiReadOnlyTextView *V_fileDescription;

@property (nonatomic) UIView * V_thumbNail;
@property (nonatomic) PEXGuiThumailView *I_thumbnail;

@property (nonatomic) CGFloat subViewMaxHeight;
@property (nonatomic) CGFloat subViewMaxWidth;

@property (nonatomic) UIViewController * previewHolderController;
@property (nonatomic) PEXGuiPreviewExecutor * previewExecutor;
@end

@implementation PEXGuiFileDetailController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.subViewMaxHeight = 0;
        self.subViewMaxWidth = 0;
        self.dataLoaded = NO;
    }

    return self;
}

- (id)initWithFile:(const PEXFileData *const)file {
    self = [self init];
    self.file = file;
    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"FileDetail";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    WEAKSELF;
    [PEXGVU executeWithoutAnimations:^{
        weakSelf.V_fileDescription = [[PEXGuiReadOnlyTextView alloc] init];
        [weakSelf.linearView addView:weakSelf.V_fileDescription];

        const CGFloat height = [weakSelf getThumbSize];
        weakSelf.V_thumbNail = [[UIView alloc] init];
        //[PEXGVU setSize:weakSelf.V_thumbNail x:height y:height];
        [weakSelf.linearView addView:weakSelf.V_thumbNail];

        weakSelf.I_thumbnail = [[PEXGuiThumailView alloc] init];
        [weakSelf.V_thumbNail addSubview:weakSelf.I_thumbnail];
    }];
}

- (void) initContent
{
    [super initContent];
}

- (void) initLayout
{
    [super initLayout];
    [self layoutView];
    [self loadDataAsync];
}

- (void) layoutView {
    WEAKSELF;
    [PEXGVU executeWithoutAnimations:^{
        [PEXGVU scaleFull:weakSelf.linearView];
        [PEXGVU scaleHorizontally:weakSelf.V_fileDescription withMargin:PEXVal(@"dim_size_medium")];

        // File description.
        [weakSelf.V_fileDescription setPaddingNumTop:nil left:@(0.0f) bottom:nil rigth:@(0.0f)];
        [weakSelf.linearView removeView:weakSelf.V_fileDescription];
        [weakSelf.V_fileDescription.textContainer setLineBreakMode:NSLineBreakByCharWrapping];
        [weakSelf.V_fileDescription setAttributedText:[weakSelf buildFilePreview]];
        [weakSelf.V_fileDescription sizeToFit];
        [weakSelf.linearView addView:weakSelf.V_fileDescription];

        // Thumbnail.
        CGFloat maxWidth = [weakSelf getMaxThumbSize];
        CGFloat height = [weakSelf getMaxThumbSize];
        CGFloat width = [weakSelf getMaxThumbSize];
        UIImage * thumb = weakSelf.nThumb != nil ? weakSelf.nThumb : weakSelf.file.thumbnail;
        if (thumb != nil){
            // Picture too big?
            width = thumb.size.width;
            height = thumb.size.height;

            if (width > maxWidth){
                height = (MIN(width,height)/MAX(width,height)) * maxWidth;
                width = maxWidth;
            }
        }

        [weakSelf.linearView removeView:weakSelf.V_thumbNail];
        [PEXGVU setSize:weakSelf.V_thumbNail x:width y:height + PEXVal(@"dim_size_medium")];

        [weakSelf.I_thumbnail setImage:thumb];
        [PEXGVU scaleFull:weakSelf.I_thumbnail];
        [weakSelf.I_thumbnail layoutSubviews];
        [weakSelf.linearView addView:weakSelf.V_thumbNail];
        [PEXGVU centerHorizontally:weakSelf.V_thumbNail];

        // Resize if needed.
        [weakSelf adjustToMaxHeight];
        [PEXGVU scaleFull:weakSelf.linearView];
    }];
}

- (void) initBehavior
{
    [super initBehavior];
    [self.V_fileDescription setScrollEnabled:false];

    // Adding two gesture recognizers so user is can guess the action to get preview.
    WEAKSELF;
    PEXGuiBlockGestureRecognizer * previewRecognizer = [[PEXGuiBlockGestureRecognizer alloc] initWithBlock:^{
        [weakSelf showPreview];
    }];

    PEXGuiLongBlockGestureRecognizer * previewLongRecognizer = [[PEXGuiLongBlockGestureRecognizer alloc] initWithBlock:^{
        [weakSelf showPreview];
    }];

    previewRecognizer.numberOfTapsRequired = 2;
    [previewLongRecognizer requireGestureRecognizerToFail:previewRecognizer];
    [self.V_thumbNail addGestureRecognizer:previewRecognizer];
    [self.V_thumbNail addGestureRecognizer:previewLongRecognizer];
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
                  y:maxHeight]; // if modal window, use MIN(maxHeight, contentHeight)
}

- (NSString *) dateToText: (NSDate *) date {
    if (date == nil || [date timeIntervalSince1970] < 10000){
        return @" - ";
    }

    return [NSString stringWithFormat:@"%@ %@",
                                      [PEXDateUtils dateToTimeString:date],
                                      [PEXDateUtils dateToDateString:date]];
}

- (void) loadDataAsync{
    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:@"fileLoad" async:YES block:^{
        // Already run?
        if (weakSelf.dataLoaded){
            return;
        } else {
            weakSelf.dataLoaded = YES;
        }

        // Compute hash
        NSURL * url = weakSelf.file.url;
        weakSelf.fileSha256 = [PEXMessageDigest getFileDigestURL:url
                                                    hashFunction:HASH_SHA256
                                                       canceller:nil
                                                             len:nil];

        // Detect mime type
        // Borrowed from http://stackoverflow.com/questions/5996797/determine-mime-type-of-nsdata-loaded-from-a-file
        // itself, derived from  http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[[url path] pathExtension], NULL);
        CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);

        weakSelf.UTI = (__bridge_transfer id)UTI;
        weakSelf.mime = mimeType ? (__bridge_transfer id)mimeType : @"application/octet-stream";

        // Thumb
        CGFloat pixels = [PEXGuiUtils pointsToPixels:[weakSelf getThumbSize]];
        weakSelf.nThumb = [PEXGuiFileUtils generateThumnailForFileUrl: url maxSizeInPixels:@(pixels)];

        [PEXService executeOnMain:YES block:^{
            [weakSelf layoutView];

            // In case this is in the modal window, relayout the whole window with the following call.
            //[weakSelf relayoutHierarchy];
        }];
    }];
}

- (void) showPreview {
    self.previewHolderController = [PEXGVU showModalTransparentController];

    self.previewExecutor = [[PEXGuiPreviewExecutor alloc] initWithListener:self
                                                           superController:self.previewHolderController];
    [self.previewExecutor prepareWithActivityItems:[PEXGuiPreviewExecutor extractQlItems:@[self.file.url]]];
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
    }];
}

- (CGFloat) getMaxThumbSize {
    if (self.view && self.view.frame.size.width > 0){
        return self.view.frame.size.width;
    }

    return [PEXResValues getThumbnailDetailSize];
}

- (CGFloat) getThumbSize {
    return [PEXResValues getThumbnailDetailSize];
}

- (NSAttributedString *) buildFilePreview {
    PEXGuiDetailsTextBuilder * bld = [[PEXGuiDetailsTextBuilder alloc] init];
    [bld appendFirstLabel:PEXStrU(@"B_file")];
    [bld appendValue:self.file.filename];

    NSString * type = ![PEXUtils isEmpty:self.UTI] ? self.UTI : @" - ";
    [bld appendLabel:PEXStr(@"L_file_type")];
    [bld appendValue:type];

    NSString * mime = ![PEXUtils isEmpty:self.mime] ? self.mime : @" - ";
    [bld appendLabel:PEXStr(@"L_file_mime_type")];
    [bld appendValue:mime];

    PEXGuiFileRepresentation * frepr = [PEXGuiFileUtils bytesToRepresentation:(uint64_t)self.file.size];
    [bld appendLabel:PEXStr(@"L_file_size")];
    [bld appendValue:[frepr description]];

    [bld appendLabel:PEXStr(@"L_file_date")];
    [bld appendValue:[self dateToText:self.file.date]];

    NSString * hash = @" - ";
    [bld appendLabel:PEXStr(@"L_sha256")];
    if (self.fileSha256 != nil){
        NSString * hashTmp = [PEXMessageDigest bytes2hex:self.fileSha256];
        if (![PEXUtils isEmpty:hashTmp]){
            hash = hashTmp;
        }
    }
    [bld appendValue:hash];
    return [bld result];
}

@end
