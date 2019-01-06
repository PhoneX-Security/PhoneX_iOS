//
// Created by Dusan Klinec on 31.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiLogController.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiLinearContainerView.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiMessageTextComposerView.h"
#import "PEXGuiLinearScalingView.h"
#import "PEXLogsZipper.h"
#import "PEXGuiToastView.h"

#define PEX_LOGLINES_PREFS @"net.phonex.loglines"

@interface PEXGuiLogController()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSUInteger logLines;

@property (nonatomic) PEXGuiLinearContainerView * linearView;
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) PEXGuiLinearContainerView * B_buttons;
@property (nonatomic) PEXGuiMessageTextComposerView * TV_logLines;
@property (nonatomic) PEXGuiButtonMain * B_refresh;
@property (nonatomic) PEXGuiButtonMain * B_bottom;
@property (nonatomic) PEXGuiButtonMain * B_copy;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_status;
@end

@implementation PEXGuiLogController {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.logLines = 200;
    }

    return self;
}

- (void)loadLogLines {
    PEXAppPreferences * prefs = [PEXAppPreferences instance];
    self.logLines = (NSUInteger) [prefs getIntPrefForKey:PEX_LOGLINES_PREFS defaultValue:250];
}

-(void) logLinesField {
    [self.TV_logLines setText:[NSString stringWithFormat:@"%d", (int)self.logLines]];
}

- (void)initGuiComponents {
    [super initGuiComponents];
    [self loadLogLines];

    self.linearView = [[PEXGuiLinearRollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        self.B_buttons = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
        self.TV_logLines = [[PEXGuiMessageTextComposerView alloc] init];
        self.B_refresh = [[PEXGuiButtonMain alloc] init];
        self.B_bottom = [[PEXGuiButtonMain alloc] init];
        self.B_copy = [[PEXGuiButtonMain alloc] init];

        // Required for correct setting of button bar.
        [self logLinesField];
        [self.B_refresh setTitle:PEXStrU(@"REFR") forState:UIControlStateNormal];
        [self.B_bottom setTitle:PEXStrU(@"BOTT") forState:UIControlStateNormal];
        [self.B_copy setTitle:PEXStrU(@"C") forState:UIControlStateNormal];

        [self.linearView addView:self.B_buttons];
        [self.B_buttons addView:self.TV_logLines];
        [self.B_buttons addView:self.B_refresh];
        [self.B_buttons addView:self.B_copy];
        [self.B_buttons addView:self.B_bottom];

        // Required so tv_status is placed below buttons.
        [PEXGVU setHeight:self.B_buttons to:self.B_refresh.frame.size.height];

        self.TV_status = [[PEXGuiReadOnlyTextView alloc] init];
        [PEXGVU setHeight:self.TV_status to:2048];  // will be adjusted later, for scrolling purposes. Last element in the linear layout
        self.TV_status.backgroundColor = PEXCol(@"light_gray_high");
        [self.linearView addView:self.TV_status];

        DDLogVerbose(@"All done");
    }];
}

- (void) initContent
{
    [super initContent];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.B_buttons];
    [PEXGVU setHeight:self.B_buttons to:self.B_refresh.frame.size.height];

    [PEXGVU scaleHorizontally:self.TV_status];
    [PEXGVU scaleVertically:self.TV_status below:self.B_buttons master:self.mainView withMargin:PEXVal(@"line_width_small")];

    [self.linearView sizeToFit];
    [PEXGVU scaleFull:self.linearView];
}

- (void)initBehavior
{
    [super initBehavior];

    self.queue = dispatch_queue_create("tuning_queue", nil);
    self.lock = [[NSLock alloc] init];

    [self.lock lock];

    [self.TV_status.textContainer setLineBreakMode:NSLineBreakByCharWrapping];
    [self.B_refresh addTarget:self action:@selector(refresh:)
             forControlEvents:UIControlEventTouchUpInside];

    [self.B_bottom addTarget:self action:@selector(bottom:)
             forControlEvents:UIControlEventTouchUpInside];

    [self.B_copy addTarget:self action:@selector(copyLog:)
             forControlEvents:UIControlEventTouchUpInside];

    [self.lock unlock];
}

- (IBAction) bottom: (id) sender
{
    [self.TV_status scrollRangeToVisible:NSMakeRange([self.TV_status.text length], 0)];
    [self.TV_status setScrollEnabled:NO];
    [self.TV_status setScrollEnabled:YES];
}

- (IBAction) copyLog: (id) sender
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:[self.TV_status text]];

    // Notify user it was copied
    [PEXGuiToastView showToastInParentView:self.view
                                  withText:@"Log was copied to the clipboard"
                              withDuration:1.0f
                            withCompletion:nil];
}

- (IBAction) refresh: (id) sender
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *logLinesNum = [f numberFromString:[self.TV_logLines text]];
    self.logLines = (NSUInteger) [logLinesNum integerValue];

    PEXAppPreferences * prefs = [PEXAppPreferences instance];
    [prefs setIntPrefForKey:PEX_LOGLINES_PREFS value:self.logLines];

    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat prevContentOffset = weakSelf.TV_status.contentOffset.y;
        [weakSelf fillStatusText];
        [weakSelf.TV_status setContentOffset:CGPointMake(0, prevContentOffset)];
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    [self.lock lock];

    [center removeObserver:self];

    [self.lock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void) fillStatusText
{
    dispatch_async(self.queue, ^{
        @try {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.B_refresh setEnabled:NO];
            });

            NSString *const textToShow = [self getLastLogLines:self.logLines];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.TV_status setText:textToShow];
                [self.TV_status.textContainer setLineBreakMode:NSLineBreakByCharWrapping];
                [self.B_refresh setEnabled:YES];
            });
        } @catch(NSException * e){
            DDLogError(@"Exception in generating tuning report: %@", e);
        }
    });
}

- (size_t) numOfNewLinesInFile: (NSString *) filepath limit: (unsigned long) limit offset: (long *) offset {
    const size_t bufferSize = 65535;
    NSMutableData * readBuffData = [NSMutableData dataWithLength:bufferSize];
    char * buff = (char *) [readBuffData mutableBytes];

    size_t numBytesSoFar = 0;
    size_t numLinesSoFar = 0;

    const size_t lineBuffSize = limit + 1;
    NSMutableData * newLinesBuff = [[NSMutableData alloc] initWithLength:offset == NULL ? sizeof(long)*1 : sizeof(long)*lineBuffSize];
    long * lineOffsetBuff = (long*) [newLinesBuff mutableBytes];
    size_t lineBuffCount = 0;
    size_t lineBuffIdx = 0;

    FILE *fd = NULL;
    @try {
        fd = fopen([filepath UTF8String], "r");
        if (fd == NULL) {
            [NSException raise:@"logReadException" format:@"Could not open file %@", filepath];
        }

        // Read file in chunks, writing to ZIP stream.
        size_t len = 0;
        while (YES) {
            len = fread(buff, 1, bufferSize, fd);

            // EOF / error?
            if (len == 0) {
                break;
            }

            [readBuffData setLength:len];

            // Find newlines in the string.
            for(size_t i=0; i<len; i++){
                if (buff[i] == '\n'){
                    if (offset != NULL){
                        lineBuffCount = lineBuffCount >= lineBuffSize ? lineBuffSize : lineBuffCount + 1;
                        lineOffsetBuff[lineBuffIdx] = numBytesSoFar+i;
                        lineBuffIdx = (lineBuffIdx+1) % lineBuffSize;
                    }
                    numLinesSoFar += 1;
                }
            }

            numBytesSoFar += len;

            // Reset back to normal.
            [readBuffData setLength:bufferSize];
        }

        if (offset != NULL){
            if (numLinesSoFar <= limit){
                *offset = 0;
            }

            // Line buffer is full. lineBuffIdx points to a new element - older record in the array
            *offset = lineOffsetBuff[lineBuffIdx];
        }

        return numLinesSoFar;

    } @catch (NSException *e) {
        DDLogError(@"Exception in processing log file %@, exc: %@", filepath, e);

    } @finally {
        if (fd != NULL) {
            fclose(fd);
        }
    }

    return 0;
}

- (NSString *) getLastLogLines: (NSInteger) linesLimit
{
    const NSInteger filesToProcess = 10;

    PEXLogsZipper * zipper = [[PEXLogsZipper alloc] init];
    zipper.logFilesToSend = filesToProcess;

    NSArray * filepaths = [zipper getLogFilesPaths];

    // Number of files processed so far.
    NSInteger numFilesProcessed = 0;
    // Number of bytes read so far, in total.
    size_t numBytesSoFar = 0;
    // Number of lines processed so far, in total
    long numLinesSoFar = 0;

    NSFileManager const * const fmgr = [NSFileManager defaultManager];

    const size_t bufferSize = 65535;
    const size_t lineBufferSize = (bufferSize+1)*2;
    NSMutableData * readBuffData = [NSMutableData dataWithLength:bufferSize+1];
    NSMutableData * currentLineData = [NSMutableData dataWithLength:lineBufferSize];
    NSMutableString * logToReturn = [[NSMutableString alloc] init];
    char * buff = (char*) [readBuffData mutableBytes];
    char * buffBack = (char*) [currentLineData mutableBytes];

    // Sort order of the items in filepaths is important here as we may limit number of MB sent
    // and the most recent logs are more important than old ones.
    for (const id filepath in filepaths) {
        if (filesToProcess > 0 && numFilesProcessed >= filesToProcess){
            break;
        }

        @autoreleasepool {
            long fileOffset = 0;

            // If total byte limit is in place, seek start of the reading.
            if (linesLimit >= 0) {
                long linesRemaining = linesLimit - numLinesSoFar;
                if (linesRemaining <= 0) {
                    break;
                }

                long totalLines = [self numOfNewLinesInFile:filepath limit:(unsigned long)linesRemaining+1 offset:&fileOffset];
                numLinesSoFar += totalLines >= linesRemaining ? linesRemaining : totalLines;
            }

            FILE *fd = NULL;
            @try {
                fd = fopen([filepath UTF8String], "r");
                if (fd == NULL) {
                    [NSException raise:@"logSendException" format:@"Could not open file %@", filepath];
                }

                // Seek on positive offset.
                // Moving offset+1 because offset points to \n
                if (fileOffset > 0 && fseek(fd, fileOffset+1, SEEK_SET) < 0) {
                    [NSException raise:@"logSendException" format:@"Seek was not successful for file %@", filepath];
                }

                // Read file in chunks, writing to ZIP stream.
                size_t len = 0;
                size_t backLen = 0;
                while (YES) {
                    len = fread(buff, 1, bufferSize, fd);

                    // EOF / error?
                    if (len == 0) {
                        break;
                    }

                    for(size_t i = 0; i<len;i++){
                        if (buff[i] == '\n'){
                            [currentLineData setLength:backLen];
                            NSString * curLine = backLen == 0 ? @"" : [[NSString alloc] initWithData:currentLineData encoding:NSUTF8StringEncoding];
                            [logToReturn appendString: curLine];
                            [logToReturn appendString: @"\n\n"];

                            // Reset state back to normal.
                            backLen = 0;
                            [currentLineData setLength:lineBufferSize];
                            continue;
                        }

                        buffBack[backLen++] = buff[i];
                    }

                    // Note buffBack might contain some non-terminated lines on the end of the buffer.
                    numBytesSoFar += len;
                }

                // Dump rest of the buffBack - line buffer.
                if (backLen > 0){
                    [currentLineData setLength:backLen];
                    [logToReturn appendString:[[NSString alloc] initWithData:currentLineData encoding:NSUTF8StringEncoding]];
                    [logToReturn appendString: @"\n\n"];

                    // Reset back to normal.
                    [currentLineData setLength:lineBufferSize];
                }

                numFilesProcessed += 1;
            } @catch (NSException *e) {
                DDLogError(@"Exception in processing log file %@, exc: %@", filepath, e);

            } @finally {
                if (fd != NULL) {
                    fclose(fd);
                }
            }
        }
    }

    return [logToReturn stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end