//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiRenameContactController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiTextFIeld.h"
#import "PEXContactRenameTask.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiUtils.h"
#import "PEXStringUtils.h"
#import "PEXDbContact.h"
#import "PEXReport.h"

@interface PEXGuiRenameContactController ()

@property (nonatomic) PEXGuiTextField * TF_newAlias;

// in case of system contact
@property (nonatomic) PEXContactRenameTask * renameTask;

@end

@implementation PEXGuiRenameContactController {

}

+ (void) showRenameControllerWithUsername: (NSString * const) username
                                    alias: (NSString * const) alias
                                forParent: (PEXGuiController * const) parent
{
    PEXGuiRenameContactController *renamer = [[PEXGuiRenameContactController alloc] init];
    renamer.contactsUsername = username;
    renamer.contactsOldAlias = alias;

    NSMutableAttributedString * descriptionText = [[NSMutableAttributedString alloc] init];

    NSString * const usernameToShow = [PEXDbContact usernameWithoutDomain:username];

    NSMutableAttributedString *first = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@ %@",
                            PEXStr(@"txt_change_alias_intro"), usernameToShow]];

    [first addAttribute:NSForegroundColorAttributeName
                  value:PEXCol(@"black_normal")
                  range:NSMakeRange(0, first.length)];

    [descriptionText appendAttributedString:first];

    // THIRD

    NSMutableAttributedString *third = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat: @"\n%@: ", PEXStr(@"L_old_alias")]];

    [third addAttribute:NSForegroundColorAttributeName
                  value:PEXCol(@"light_gray_low")
                  range:NSMakeRange(0, third.length)];

    [descriptionText appendAttributedString:third];

    NSMutableAttributedString *third_val = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithString: alias]];

    [third_val addAttribute:NSForegroundColorAttributeName
                      value:PEXCol(@"black_normal")
                      range:NSMakeRange(0, third_val.length)];

    [descriptionText appendAttributedString:third_val];

    renamer.descriptionIntroe = descriptionText;

    [PEXGAU showInNavigation:renamer
                          in:parent
                       title:PEXStrU(@"L_change_alias")];
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"RenameContact";

    self.TF_newAlias = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_newAlias];
}

- (void) initContent
{
    [super initContent];

    self.TF_newAlias.placeholder = PEXStr(@"L_new_alias");
    [self.B_action setTitle:PEXStrU(@"L_change") forState:UIControlStateNormal];

    [self.TV_introText setAttributedText:self.descriptionIntroe];
    self.TV_introText.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.TF_newAlias setDelegate:self];
    self.TF_newAlias.secureTextEntry = NO;
    [self.B_action addTarget:self action:@selector(startRenamingContact) forControlEvents:UIControlEventTouchUpInside];
}

- (void) setBusyInternal: (const bool) busy
{
    [super setBusyInternal:busy];

    self.TF_newAlias.enabled = !busy;
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat margin = PEXVal(@"dim_size_small");

    [self.TV_introText sizeToFit];
    [PEXGVU moveToTop:self.TV_introText];

    [PEXGVU scaleHorizontally:self.TF_newAlias withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_newAlias below:self.TV_introText];

    [PEXGVU move: self.B_action below: self.TF_newAlias withMargin:margin];
    [PEXGVU move: self.TV_errorText below: self.B_action];

    [PEXGVU move: self.activityIndicatorView below:self.B_action withMargin:margin];
    [PEXGVU centerHorizontally:self.activityIndicatorView];
}

- (void) startRenamingContact
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_RENAME_CONTACT];
    @synchronized (self)
    {
        if (!_dismissing && !_taskInProgress)
        {
            [PEXGuiUtils sanitizeTextFieldInput:self.TF_newAlias];

            _taskInProgress = true;
            [self setBusy];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self callRenameContact];
            });
        }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    @synchronized (self)
    {
        _dismissing = true;
        if (_taskInProgress)
        {
            [self.renameTask cancel];
        }
    }

    [super dismissViewControllerAnimated:flag completion:completion];
}

// must be called in mutex
- (void) callRenameContact
{
    NSString * const alias = self.TF_newAlias.text;

    if ([PEXStringUtils isEmpty:alias])
    {
        [self contactRenameFailed:PEXStr(@"txt_rename_contact_empty_alias")];
        return;
    }

    // Check if is not system.
    if ([PEXStringUtils startsWith:alias prefix:@(PEX_CONTACT_HIDDEN_PREFIX)])
    {
        [self contactRenameFailed:PEXStr(@"txt_add_contact_illegal_login_name")];
        return;
    }

    self.renameTask = [[PEXContactRenameTask alloc] init];
    self.renameTask.contactAddress = self.contactsUsername;
    self.renameTask.contactAlias = alias;
    [self.renameTask addListener:self];

    [self.renameTask start];
}

- (void) contactRenamed
{
    dispatch_async(dispatch_get_main_queue(), ^(void)  {
        [self.fullscreener dismissViewControllerAnimated:true completion:nil];
    });
}

- (void) contactRenameFailed: (NSString * const) errorText
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setErrorText:errorText];
    });

    [self contactRenameCancelled];
}

- (void) contactRenameCancelled
{
    self.renameTask = nil;

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setAvailable];
    });

    @synchronized (self) {
        _taskInProgress = false;
    }
}

- (void) taskEnded:(const PEXTaskEvent *const)event
{
    const PEXContactRenameTaskEventEnd * const ev= (PEXContactRenameTaskEventEnd *) event;
    PEXContactRenameResultDescription desc = [ev getResult].resultDescription;

    if (desc == PEX_CONTACT_RENAME_RESULT_RENAMED)
    {
        [self contactRenamed];
        return;
    }

    if (desc == PEX_CONTACT_RENAME_CANCELLED)
    {
        [self contactRenameCancelled];
        return;
    }

    NSString * errorText;
    switch (desc)
    {
        case PEX_CONTACT_RENAME_RESULT_CONNECTION_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_connection_problem");
            break;
        case PEX_CONTACT_RENAME_RESULT_ILLEGAL_LOGIN_NAME:
            errorText = PEXStr(@"txt_add_contact_illegal_login_name");
            break;
        case PEX_CONTACT_RENAME_RESULT_NO_NETWORK:
            errorText = PEXStr(@"txt_add_contact_no_network");
            break;
        case PEX_CONTACT_RENAME_RESULT_SERVERSIDE_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_serverside_problem");
            break;
        case PEX_CONTACT_RENAME_RESULT_UNKNOWN_USER:
            errorText = PEXStr(@"txt_add_contact_unknown_user");
            break;
            /* handled elsewhere
        case PEX_CONTACT_RENAME_RESULT_RENAMED:break;
        case PEX_CONTACT_RENAME_CANCELLED:break;
        */
    }

    [self contactRenameFailed:errorText];
    return;
}

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}

@end