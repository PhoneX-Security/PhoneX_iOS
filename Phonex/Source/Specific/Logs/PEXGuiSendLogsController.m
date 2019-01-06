//
// Created by Matej Oravec on 24/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSendLogsController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiButtonMain.h"
#import "PEXLogsSender.h"
#import "PEXGuiMessageTextComposerView.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXStringUtils.h"
#import "PEXPrepareAndSendLogsExecutor.h"
#import "PEXGuiFactory.h"
#import "PEXReport.h"


@interface PEXGuiSendLogsController()

@property (nonatomic) PEXGuiReadOnlyTextView * TV_intro;
@property (nonatomic) PEXGuiButtonMain * B_sendTheStuff;
@property (nonatomic) PEXGuiMessageTextComposerView * TV_userMessageComposer;

@end

@implementation PEXGuiSendLogsController {

}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"SendLogs";

    self.TV_intro = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_intro];

    self.B_sendTheStuff = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_sendTheStuff];

    self.TV_userMessageComposer = [[PEXGuiMessageTextComposerView alloc] init];
    [self.mainView addSubview:self.TV_userMessageComposer];
}

- (void) initContent
{
    self.TV_intro.text = PEXStr(@"txt_send_logs_intro");
    [self.B_sendTheStuff setTitle:PEXStrU(@"B_send") forState:UIControlStateNormal];
    self.TV_userMessageComposer.placeholder = PEXStr(@"txt_describe_your_issue");
    self.TV_userMessageComposer.text = @"";
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally: self.TV_intro];
    [self.TV_intro sizeToFit];

    [PEXGVU scaleHorizontally:self.TV_userMessageComposer];
    [PEXGVU setHeight:self.TV_userMessageComposer to:100.0f];
    [PEXGVU move:self.TV_userMessageComposer below:self.TV_intro];

    [PEXGVU move:self.B_sendTheStuff below:self.TV_userMessageComposer withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU scaleHorizontally: self.B_sendTheStuff withMargin:PEXVal(@"dim_size_large")];

    //self.TV_userMessageComposer.placeholder = PEXStr(@"txt_message_placeholder");
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_sendTheStuff addTarget:self action:@selector(startSending:)
                  forControlEvents:UIControlEventTouchUpInside];

    [self.TV_userMessageComposer setDelegate:self];
}

- (IBAction) startSending: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGS_START_SENDING];
    PEXGuiBinaryDialogExecutor * const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
    executor.primaryButtonText = PEXStrU(@"B_send");
    executor.secondaryButtonText = PEXStrU(@"B_cancel");
    executor.text = [PEXStringUtils isEmpty:self.TV_userMessageComposer.text] ?
            PEXStr(@"txt_send_logs_without_description_question") :
            PEXStr(@"txt_send_logs_question");

    WEAKSELF;
    executor.primaryAction = ^{
        [weakSelf sendTheStuff];
    };

    [executor show];
}

- (void) sendTheStuff
{
    PEXPrepareAndSendLogsExecutor * executor = [[PEXPrepareAndSendLogsExecutor alloc] init];
    executor.parentController = self;
    executor.userMessage = self.TV_userMessageComposer.text;

    WEAKSELF;
    void(^completion)(void) = ^{
        [weakSelf.fullscreener dismissViewControllerAnimated:true completion:nil];
    };

    executor.preparationCompletion = ^(const bool success){

        if (success)
        {
            [PEXGuiFactory showTextBox:self withText:PEXStr(@"txt_logs_sending_success") completion:completion];
        }
        else
        {
            [PEXGuiFactory showErrorTextBox:self withText:PEXStr(@"txt_logs_sending_error") completion:completion];
        }
    };

    [executor show];
}

@end