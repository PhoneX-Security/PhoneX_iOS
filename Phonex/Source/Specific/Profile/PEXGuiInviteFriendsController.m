//
// Created by Dusan Klinec on 09.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiInviteFriendsController.h"
#import "PEXGuiSendLogsController.h"
#import "PEXGuiFactory.h"

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
#import "PEXGuiToastView.h"
#import "PEXGuiTextView_Protected.h"
#import "UITextView+PEXPaddings.h"


@interface PEXGuiInviteFriendsController()

@property (nonatomic) PEXGuiReadOnlyTextView * TV_intro;
@property (nonatomic) PEXGuiMessageTextComposerView * TV_userMessageComposer;
@property (nonatomic) PEXGuiButtonMain * B_inviteText;
@property (nonatomic) PEXGuiButtonMain * B_inviteMail;
@property (nonatomic) PEXGuiButtonMain * B_inviteCopy;

@property (nonatomic) BOOL canSendText;
@property (nonatomic) BOOL canSendMail;

@property (nonatomic) MFMessageComposeViewController *messageController;
@property (nonatomic) MFMailComposeViewController *mailController;
@end

@implementation PEXGuiInviteFriendsController {

}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"InviteFriends";

    self.TV_intro = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_intro];

    self.B_inviteText = [[PEXGuiButtonMain alloc] init];
    self.B_inviteMail = [[PEXGuiButtonMain alloc] init];
    self.B_inviteCopy = [[PEXGuiButtonMain alloc] init];

    self.canSendText = [MFMessageComposeViewController canSendText];
    self.canSendMail = [MFMailComposeViewController canSendMail];

    if (self.canSendText) {
        [self.mainView addSubview:self.B_inviteText];
    }

    if (self.canSendMail) {
        [self.mainView addSubview:self.B_inviteMail];
    }

    [self.mainView addSubview:self.B_inviteCopy];

    self.TV_userMessageComposer = [[PEXGuiMessageTextComposerView alloc] init];
    [self.mainView addSubview:self.TV_userMessageComposer];
}

- (void) initContent
{
    self.TV_intro.text = PEXStr(@"txt_invite_friends_intro");
    [self.B_inviteText setTitle:PEXStrU(@"B_invite_text") forState:UIControlStateNormal];
    [self.B_inviteMail setTitle:PEXStrU(@"B_invite_mail") forState:UIControlStateNormal];
    [self.B_inviteCopy setTitle:PEXStrU(@"B_invite_copy") forState:UIControlStateNormal];
    self.TV_userMessageComposer.text = PEXStr(@"txt_invite_friends_txt");
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally: self.TV_intro withMargin:PEXVal(@"dim_size_medium")];
    [self.TV_intro setPaddingNumTop:nil left:@(0.0f) bottom:nil rigth:@(0.0f)];
    [self.TV_intro sizeToFit];

    [PEXGVU scaleHorizontally:self.TV_userMessageComposer];
    [PEXGVU setHeight:self.TV_userMessageComposer to:100.0f];
    [PEXGVU move:self.TV_userMessageComposer below:self.TV_intro];

    UIView * below = self.TV_userMessageComposer;
    if (self.canSendText) {
        [PEXGVU move:self.B_inviteText below:below withMargin:PEXVal(@"dim_size_large")];
        [PEXGVU scaleHorizontally:self.B_inviteText withMargin:PEXVal(@"dim_size_large")];
        below = self.B_inviteText;
    }

    if (self.canSendMail) {
        [PEXGVU move:self.B_inviteMail below:below withMargin:PEXVal(@"dim_size_large")];
        [PEXGVU scaleHorizontally:self.B_inviteMail withMargin:PEXVal(@"dim_size_large")];
        below = self.B_inviteMail;
    }

    [PEXGVU move:self.B_inviteCopy below:below withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU scaleHorizontally: self.B_inviteCopy withMargin:PEXVal(@"dim_size_large")];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_inviteText addTarget:self action:@selector(inviteText:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.B_inviteMail addTarget:self action:@selector(inviteMail:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.B_inviteCopy addTarget:self action:@selector(inviteCopy:)
                  forControlEvents:UIControlEventTouchUpInside];

    [self.TV_userMessageComposer setDelegate:self];
}

-(void) disableAll {
    [self.B_inviteText setEnabled:NO];
    [self.B_inviteMail setEnabled:NO];
    [self.B_inviteCopy setEnabled:NO];
}

-(void) enableAll {
    [self.B_inviteText setEnabled:YES];
    [self.B_inviteMail setEnabled:YES];
    [self.B_inviteCopy setEnabled:YES];
}

- (IBAction) inviteText: (id) sender
{
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }

    NSString *message = [self.TV_userMessageComposer text];

    [self disableAll];
    self.messageController = [[MFMessageComposeViewController alloc] init];
    self.messageController.messageComposeDelegate = self;
    [self.messageController setBody:message];
    [self.messageController setRecipients:@[]];

    // Present message view controller on screen
    WEAKSELF;
    [self.fullscreener presentViewController:self.messageController animated:YES completion:^{
        [weakSelf enableAll];
    }];
}

- (IBAction) inviteMail: (id) sender
{
    if(![MFMailComposeViewController canSendMail]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support mails!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }

    // Email Subject
    NSString *emailTitle = PEXStr(@"txt_invite_mail_title");
    // Email Content
    NSString *messageBody = [self.TV_userMessageComposer text];

    [self disableAll];
    self.mailController = [[MFMailComposeViewController alloc] init];
    self.mailController.mailComposeDelegate = self;
    [self.mailController setSubject:emailTitle];
    [self.mailController setMessageBody:messageBody isHTML:NO];

    // Present mail view controller on screen
    WEAKSELF;
    [self.fullscreener presentViewController:self.mailController animated:YES completion:^{
        [weakSelf enableAll];
    }];
}

- (IBAction) inviteCopy: (id) sender
{
    WEAKSELF;
    void(^completion)(void) = ^{
        [weakSelf.fullscreener dismissViewControllerAnimated:true completion:nil];
    };

    [self disableAll];
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:[self.TV_userMessageComposer text]];

    // Notify user it was copied
    [PEXGuiToastView showToastInParentView:self.view
                                  withText:PEXStr(@"txt_invite_friend_copied")
                              withDuration:3.0f
                            withCompletion:completion];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    WEAKSELF;
    void(^completion)(void) = ^{
        [weakSelf.fullscreener dismissViewControllerAnimated:true completion:nil];
    };

    dispatch_block_t completionResult = completion;
    switch (result) {
        case MessageComposeResultCancelled: {
            DDLogVerbose(@"Composing cancelled");
            completionResult = nil;
            break;
        }

        case MessageComposeResultFailed: {
            DDLogVerbose(@"Sending failed");
            completionResult = ^{
                [PEXGuiFactory showErrorTextBox:self withText:PEXStr(@"txt_invite_sending_error") completion:nil];
            };
            break;
        }

        case MessageComposeResultSent: {
            DDLogVerbose(@"Compose sent");
            completionResult = ^{
                [PEXGuiFactory showTextBox:self withText:PEXStr(@"txt_invite_sending_success") completion:completion];
            };
            break;
        }

        default:
            DDLogVerbose(@"Undetermined result: %d", (int)result);
            break;
    }

    [controller dismissViewControllerAnimated:YES completion:completionResult];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    WEAKSELF;
    void(^completion)(void) = ^{
        [weakSelf.fullscreener dismissViewControllerAnimated:true completion:nil];
    };

    dispatch_block_t completionResult = completion;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            DDLogVerbose(@"Mail cancelled");
            completionResult = nil;
            break;
        case MFMailComposeResultSaved:
            DDLogVerbose(@"Mail saved");
            break;
        case MFMailComposeResultSent: {
            DDLogVerbose(@"Mail sent");
            completionResult = ^{
                [PEXGuiFactory showTextBox:self withText:PEXStr(@"txt_invite_sending_success") completion:completion];
            };
            break;
        }
        case MFMailComposeResultFailed: {
            DDLogVerbose(@"Mail sent failure: %@", [error localizedDescription]);
            completionResult = ^{
                [PEXGuiFactory showErrorTextBox:self withText:PEXStr(@"txt_invite_sending_error") completion:nil];
            };
            break;
        }
        default:
            break;
    }

    [controller dismissViewControllerAnimated:YES completion:completionResult];
}


@end


