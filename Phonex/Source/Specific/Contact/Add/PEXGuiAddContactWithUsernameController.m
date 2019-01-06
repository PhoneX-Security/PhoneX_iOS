//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiAddContactWithUsernameController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiButtonMain.h"
#import "PEXContactAddTask.h"
#import "PEXService.h"
#import "PEXStringUtils.h"
#import "PEXDbContentProvider.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbContact.h"
#import "PEXContactRenameTask.h"
#import "PEXContactAddTaskStage.h"
#import "PEXContactAddEvents.h"
#import "PEXGuiUtils.h"
#import "PEXGuiRenameContactController.h"
#import "PEXGuiPhonexCheckBox.h"
#import "PEXGuiClassicLabel.h"
#import "PEXReport.h"
#import "PEXLoginNameValidator.h"
#import "UIView+AJWValidator.h"
#import "AJWValidator.h"

@interface PEXGuiAddContactWithUsernameController ()

@property (nonatomic) PEXGuiTextField * TF_username;

@property (nonatomic) UILabel * L_alias;
@property (nonatomic) PEXGuiClickableView * B_alias;
@property (nonatomic) PEXGuiPhonexCheckBox * CB_alias;
@property (nonatomic) PEXGuiTextField * TF_alias;

@property (nonatomic) PEXContactAddTask * addTask;

// in case of system contact
@property (nonatomic) PEXContactRenameTask * renameTask;

@property (nonatomic) AJWValidator * validatorLogin;

@end

@implementation PEXGuiAddContactWithUsernameController {

}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"AddContactWithUserName";

    self.TF_username = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_username];

    self.CB_alias = [[PEXGuiPhonexCheckBox alloc] init];
    [self.mainView addSubview:self.CB_alias];

    self.B_alias = [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview:self.B_alias];

    self.L_alias = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"black_normal")];
    [self.mainView addSubview:self.L_alias];

    self.TF_alias = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_alias];
}

- (void) buildDescription
{
    NSMutableAttributedString * descriptionText = [[NSMutableAttributedString alloc] init];

    NSMutableAttributedString *first = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@ %@",
                            PEXStr(@"txt_add_new_contact_intro"), PEXStr(@"txt_add_new_contact_intro_expl")]];

    [first addAttribute:NSForegroundColorAttributeName
                  value:PEXCol(@"black_normal")
                  range:NSMakeRange(0, first.length)];

    [descriptionText appendAttributedString:first];

    [self.TV_introText setAttributedText:descriptionText];
    self.TV_introText.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
}

- (void) initContent
{
    [super initContent];

    self.TF_username.placeholder = PEXStr(@"L_username");

    if (self.preparedUsername)
        self.TF_username.text = self.preparedUsername;

    [self.B_action setTitle:PEXStrU(@"L_add") forState:UIControlStateNormal];

    self.L_alias.text = PEXStr(@"L_alias_for_the_contact");
    self.TF_alias.placeholder = PEXStr(@"L_alias");

    [self buildDescription];
}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;
    [self.TF_username setDelegate:self];
    self.TF_username.secureTextEntry = NO;
    self.TF_username.autocapitalizationType = UITextAutocapitalizationTypeNone;

    [self.TF_alias setDelegate:self];
    self.TF_alias.secureTextEntry = NO;

    self.CB_alias.checkBlock = ^(const bool isChecked) {
        [weakSelf checkSet:isChecked];
    };

    [self.B_alias addAction:self action:@selector(aliasClicked:)];

    [self.B_action addTarget:self action:@selector(startAddingContact) forControlEvents:UIControlEventTouchUpInside];

    self.validatorLogin = [PEXLoginNameValidator initValidatorWithDomain:YES];
    [self.TF_username ajw_attachValidator:self.validatorLogin];
    [self.TF_username addTarget:self action:@selector(usernameTextChanged:) forControlEvents:UIControlEventEditingChanged];
    _validatorLogin.validatorStateChangedHandler = ^(AJWValidatorState newState) {
        switch (newState) {
            case AJWValidatorValidationStateValid: {
                [weakSelf handleValidLogin];
                break;
            }
            case AJWValidatorValidationStateInvalid: {
                [weakSelf handleInvalidLogin];
                break;
            }
            default:
                break;
        }
    };
}

- (IBAction) aliasClicked: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_ADD_CONTACT_ALIAS_CLICKED];
    [self.CB_alias setChecked:!self.CB_alias.isChecked];
}

- (void) checkSet: (const bool) isChecked
{
    [self.TF_alias setEnabled:isChecked];
}

- (void) initState
{
    [self.TF_alias setEnabled:false];

    if (self.preparedUsername)
        [self.TF_username setEnabled:false];
}

- (void) setBusyInternal: (const bool) busy
{
    [super setBusyInternal:busy];

    if (self.CB_alias.isChecked)
        self.TF_alias.enabled = !busy;

    if (!self.preparedUsername)
        self.TF_username.enabled = !busy;
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat margin = PEXVal(@"dim_size_small");

    [self.TV_introText sizeToFit];
    [PEXGVU moveToTop:self.TV_introText];

    [PEXGVU scaleHorizontally:self.TF_username withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_username below: self.TV_introText];

    [PEXGVU setSize:self.CB_alias x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.CB_alias below:self.TF_username withMargin:margin];
    [PEXGVU moveToLeft:self.CB_alias withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.TF_alias withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_alias below:self.CB_alias withMargin:margin];

    [PEXGVU centerVertically:self.L_alias on:self.CB_alias];
    [PEXGVU move:self.L_alias rightOf:self.CB_alias withMargin:margin];

    // remember user check box wrapper
    const CGFloat upperY = self.TF_username.frame.origin.y + self.TF_username.frame.size.height;
    const CGFloat leftX = self.CB_alias.frame.origin.x;
    self.B_alias.frame = CGRectMake(0.0f /*leftX*/,
            upperY,

            self.L_alias.frame.origin.x +
                    self.L_alias.frame.size.width /*- leftX*/,

            self.TF_alias.frame.origin.y - upperY
    );
    [self.view bringSubviewToFront:self.B_alias];

    [PEXGVU move: self.B_action below: self.TF_alias withMargin:margin];
    [PEXGVU move: self.TV_errorText below: self.B_action];

    [PEXGVU move: self.activityIndicatorView below:self.B_action withMargin:margin];
    [PEXGVU centerHorizontally:self.activityIndicatorView];
}

- (void) startAddingContact
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_ADD_CONTACT];
    @synchronized (self)
    {
        if (!_dismissing && !_taskInProgress)
        {
            [PEXGuiUtils sanitizeTextFieldInputLowerCase:self.TF_username];
            [PEXGuiUtils sanitizeTextFieldInput:self.TF_alias];

            _taskInProgress = true;
            [self setBusy];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self callAddContact];
            });
        }
    }
}

// must be called in mutex
- (void) callAddContact {
    NSString *username = self.TF_username.text;
    NSString *alias = self.TF_alias.text;
    const bool useAlias = [self.CB_alias isChecked];

    // Username autocomplete so we can recognize system account properly.
    username = [[PEXService instance] sanitizeUserContact:username];

    if ([PEXStringUtils isEmpty:username]) {
        [self contactAddFailed:PEXStr(@"txt_add_contact_empty_email")];
        return;
    }

    if (useAlias) {
        if ([PEXStringUtils isEmpty:alias]) {
            [self contactAddFailed:PEXStr(@"txt_rename_contact_empty_alias")];
            return;
        }
    }

    // Check if we handled system contact or not.
    if ([self addSystemContact:username alias:useAlias ? alias : [PEXDbContact usernameWithoutDomain:username]]){
        return;
    }

    // set the add task
    PEXContactAddTask * const addTask = [[PEXContactAddTask alloc] initWithController:self];
    addTask.contactAddress = username;

    if (useAlias)
        addTask.contactAlias = alias;

    [addTask addListener:self];
    self.addTask = addTask;

    [self.addTask start];
}

- (BOOL) addSystemContact: (NSString *) addr alias: (NSString *) alias {

    // Fix for system account that cannot be removed. Rename is called instead.
    if (![[PEXService instance] isUriSystemContact:addr]){
        self.renameTask = nil;
        return NO;
    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbContact * contact = [PEXDbContact newProfileFromDbSip:cr sip:addr projection:[PEXDbContact getLightProjection]];

    NSString * newAlias = nil;
    if (contact != nil && ![PEXStringUtils isEmpty:contact.sip]){
        newAlias = [PEXDbContact stripHidePrefix:alias wasPresent:nil];
    }

    // Already present.
    if (contact != nil && contact.hideContact != nil && ![contact.hideContact boolValue]) {
        DDLogVerbose(@"Contact already added");

        NSString *errorText = PEXStr(@"txt_add_contact_already_added");
        [self contactAddFailed:errorText];

        return YES;
    }

    // Do rename.
    if (newAlias)
    {
        self.renameTask = [[PEXContactRenameTask alloc] init];
        self.renameTask.contactAddress = addr;
        self.renameTask.contactAlias = newAlias;
        [self.renameTask addListener:self];
        [self.renameTask start];
        return YES;
    }

    return NO;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    @synchronized (self)
    {
        _dismissing = true;
        if (_taskInProgress)
        {
            [self.renameTask cancel];
            [self.addTask cancel];
        }
    }

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void) contactAdded
{
    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self.fullscreener dismissViewControllerAnimated:true completion:nil];
    });
}

- (void) contactAddFailed: (NSString * const) errorText
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self setErrorText:errorText];
    });

    [self contactAddCancelled];
}

- (void) contactAddCancelled
{
    self.addTask = nil;
    self.renameTask = nil;

    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self setAvailable];
    });

    @synchronized (self) {
        _taskInProgress = false;
    }
}

-(void) taskSysUserRenameEnded:(const PEXTaskEvent *const)event{
    const PEXContactRenameTaskEventEnd * const ev= (PEXContactRenameTaskEventEnd *) event;
    PEXContactRenameResultDescription desc = [ev getResult].resultDescription;

    if (desc == PEX_CONTACT_RENAME_RESULT_RENAMED)
    {
        [self contactAdded];
        return;
    }

    if (desc == PEX_CONTACT_RENAME_CANCELLED)
    {
        [self contactAddCancelled];
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
    }

    [self contactAddFailed:errorText];
}

- (void) taskEnded:(const PEXTaskEvent *const)event
{
    if (self.renameTask != nil) {
        [self taskSysUserRenameEnded:event];
        return;
    }

    const PEXContactAddTaskEventEnd * const ev= (PEXContactAddTaskEventEnd *) event;
    PEXContactAddResultDescription desc = [ev getResult].resultDescription;

    if (desc == PEX_CONTACT_ADD_RESULT_ADDED)
    {
        [self contactAdded];
        return;
    }

    if (desc == PEX_CONTACT_ADD_CANCELLED)
    {
        [self contactAddCancelled];
        return;
    }

    NSString * errorText;
    switch (desc)
    {
        case PEX_CONTACT_ADD_RESULT_ALREADY_ADDED:
            errorText = PEXStr(@"txt_add_contact_already_added");
            break;
        case PEX_CONTACT_ADD_RESULT_CONNECTION_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_connection_problem");
            break;
        case PEX_CONTACT_ADD_RESULT_ILLEGAL_LOGIN_NAME:
            errorText = PEXStr(@"txt_add_contact_illegal_login_name");
            break;
        case PEX_CONTACT_ADD_RESULT_NO_NETWORK:
            errorText = PEXStr(@"txt_add_contact_no_network");
            break;
        case PEX_CONTACT_ADD_RESULT_SERVERSIDE_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_serverside_problem");
            break;
        case PEX_CONTACT_ADD_RESULT_UNKNOWN_USER:
            errorText = PEXStr(@"txt_add_contact_unknown_user");
            break;
            /* handled previously
        case PEX_CONTACT_ADD_RESULT_ADDED:break;
        case PEX_CONTACT_ADD_CANCELLED:break;
        */
    }

    [self contactAddFailed:errorText];
    return;
}

// NOT INTERESTED

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

- (IBAction) usernameTextChanged: (UITextField *) sender
{
    if (sender.text.length > 0) {
        sender.text = [PEXLoginNameValidator sanitize:sender.text allowDomain:YES];
        [self.validatorLogin validate:sender.text];
    }
}

- (void)handleValidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_username.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
}

- (void)handleInvalidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_username.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];
}

@end