//
//  PEXGuiChangePasswordExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiChangePasswordExecutor.h"

#import "PEXGuiChangePasswordController.h"
#import "PEXChangePasswordTask.h"
#import "PEXStringUtils.h"

#import "PEXUserPrivate.h"
#import "PEXUtils.h"
#import "PEXLoginHelper.h"
#import "PEXGuiLoginController.h"
#import "PEXAppDelegate.h"
#import "PEXLoginExecutor.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXGuiFactory.h"

@interface PEXGuiChangePasswordExecutor ()
{
    volatile bool _taskInProgress;
}
@property (nonatomic) PEXGuiController * parent;
@property (nonatomic) PEXTask * task;

@property (nonatomic) NSLock * lock;

@end

@implementation PEXGuiChangePasswordExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    _taskInProgress = false;
    self.parent = parent;
    self.lock = [[NSLock alloc] init];

    return self;
}

/*
- (void)show
{
    self.showedController = [[PEXGuiChangePasswordController alloc] init];
    self.topController = [self.showedController showInWindowWithTitle:self.parent
                                                  title:PEXStrU(@"L_change_password")
                                     withBinaryListener:self];
    [super show];
}*/

- (void) topControllerShowed: (PEXGuiController * const) topController
{
    self.topController = topController;

    [super show];
}


- (void)secondaryButtonClicked
{
    [self.lock lock];
    if (!_taskInProgress)
    {
        // called by PEXGuiChangePasswordController on dismiss
        // [self dismiss];
    }
    else
    {
        [self.task cancel];
    }
    [self.lock unlock];
}

- (void)primaryButtonClicked
{
    [self.lock lock];
    if (!_taskInProgress)
    {
        _taskInProgress = true;
        [self callTask];
    }
    [self.lock unlock];
}

// must be called in mutex
- (void) callTask
{
    NSString * const old = [self.showedController oldPassword];
    NSString * const new = [self.showedController newPassword];
    NSString * const newRepeated = [self.showedController newPasswordRepeated];

    if (![PEXStringUtils string:new hasLengthAtLeast:PEX_PASSWORD_MIN_LENGTH] ||
            ![PEXStringUtils containsAtLeastOneDigit:new])
    {
        [self.showedController setErrorText:PEXStr(@"txt_pass_change_min_length")];
        _taskInProgress = false;
        return;
    }

    if (![new isEqualToString:newRepeated])
    {
        [self.showedController setErrorText:PEXStr(@"txt_pass_change_must_be_equal")];
        _taskInProgress = false;
        return;
    }

    PEXUserPrivate * const oldPrivateData = [[PEXAppState instance] getPrivateData];
    PEXUserPrivate * const newPrivateData = [oldPrivateData initCopy];
    NSString * const username = oldPrivateData.username;

    PEXChangePasswordParams * params = [[PEXChangePasswordParams alloc] init];
    params.userSIP = username;
    params.targetUserSIP = username;
    params.rekeyDB = YES;
    params.rekeyKeyStore = YES;
    params.derivePasswords = YES;
    params.userNewPass = new;
    params.userOldPass = old;

    // Configure task.
    PEXChangePasswordTask * const task = [[PEXChangePasswordTask alloc] init];
    self.task = task;
    task.privData = oldPrivateData;
    task.nwPrivData = newPrivateData;
    task.params = params;
    [task addListener:self];

    [self.showedController setBusy];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self.task start];
                   });
}

- (void) taskCancelled
{
    self.task = nil;
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       // do not call this, because the PEXGuiChangePasswordController is being dismissed
                       // [self.showedController setAvailable];
                       _taskInProgress = false;

                   });
}

- (void)taskSuccessful
{
    self.task = nil;

    PEXUserPrivate * const privateCopy = [[[PEXAppState instance] getPrivateData] copy];

    // TODO the task sets the app into a "rozjebany" stav, probably because of some bugs in internal
    // TODO processes of itself.
    // TODO that is why we for safety relog the user.

    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {

                       PEXGuiLoginController * instance = [PEXGuiLoginController instance];

                       [instance showBusier];

                       [instance performLogoutWithAftermath:^{

                           // will be deleted on login if preferences dont allow
                           [PEXLoginHelper storeCredentialsToKeychain:privateCopy forceStore:true];

                           [PEXAppDelegate startAutoLoginOnSuccess:^{
                               [PEXLoginExecutor loginAftermath:[[PEXAppState instance] getPrivateData].username];
                               [PEXLoginExecutor showLoggedGui:false];

                               // delay hiding the activity indicator and wait for other stuff to show
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [instance hideBusier];
                               });
                           } onFailureWithCredentials:^(const PEXCredentials *credentials) {
                               // some error which should not happen
                               [instance hideBusier];

                               // FOR USER'S SANITY SAFETY IN ANY CASE
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [instance hideBusier];
                                   [PEXGuiFactory showErrorTextBox:instance
                                                          withText:PEXStr(@"L_app_started")];
                               });
                           }];
                       } willLoginImmediatelly:true];
                   });
}

- (void) taskFailed: (NSString * const) errorText
{
    self.task = nil;
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self.showedController setErrorText:errorText];
                       [self.showedController setAvailable];
                       [self taskCancelled];
                   });
}

- (void) taskEnded:(const PEXTaskEvent *const)event
{
    const PEXTaskFinishedEvent * const ev = (PEXTaskFinishedEvent *) event;
    PEX_TASK_FINIHED_STATE state = ev.finishState;

    if (state == PEX_TASK_FINISHED_OK)
    {
        [self taskSuccessful];
        return;
    }

    if (state == PEX_TASK_FINISHED_CANCELLED)
    {
        [self taskCancelled];
        return;
    }

    NSString * errorText;
    // TODO more describing error sentence?
    errorText = PEXStr(@"txt_pass_change_error");
    switch (state)
    {
        case PEX_TASK_FINISHED_ERROR:
            if ([PEXUtils doErrorMatch:ev.finishError domain:PEXPassChangeErrorDomain code:PEXPassChangeErrorNotAuthorized]){
                errorText = PEXStr(@"txt_pass_change_error_incorrect_old_password_or_connection");
                DDLogWarn(@"Not authorized!");
            } else if ([PEXUtils doErrorMatch:ev.finishError domain:PEXPassChangeErrorDomain code:PEXPassChangeErrorServerCall]){
                errorText = PEXStr(@"txt_pass_change_error_connection_error");
                DDLogWarn(@"SOAP error.");
            } else {
                errorText = PEXStr(@"txt_pass_change_error_communication_with_server_error");
                DDLogWarn(@"Another error, password is probably not valid.");
            }

            break;
        case PEX_TASK_FINISHED_NA:
        case PEX_TASK_FINISHED_OK:
        case PEX_TASK_FINISHED_CANCELLED:break;
            break;
    }

    [self taskFailed:errorText];
}

- (void) taskCancelEnded:(const PEXTaskEvent *const)event{}
- (void) taskCancelProgressed:(const PEXTaskEvent *const)event{}
- (void) taskCancelStarted:(const PEXTaskEvent *const)event{}
- (void) taskProgressed:(const PEXTaskEvent *const)event{}
- (void) taskStarted:(const PEXTaskEvent *const)event{}

- (void) dismiss
{
    [self dismissWithCompletion:nil];
}

@end
