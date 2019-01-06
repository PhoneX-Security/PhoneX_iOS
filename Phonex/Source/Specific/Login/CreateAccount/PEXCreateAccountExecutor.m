//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCreateAccountExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiCreateAccountController.h"
#import "PEXGuiDialogProgressCanceller.h"
#import "PEXGuiWindowController.h"
#import "PEXCreateAccountHolder.h"
#import "PEXCreateAccountTask.h"
#import "PEXCreateAccountHolder.h"
#import "PEXGuiFactory.h"
#import "DDXMLNode.h"
#import "PEXReport.h"


@implementation PEXNewAccountInfo
@end

@interface PEXCreateAccountExecutor ()

@property (nonatomic) PEXCreateAccountTask * createAccountTask;

@end

@implementation PEXCreateAccountExecutor {

}

- (void) show
{
    PEXGuiProgressController * const progress = [[PEXGuiProgressController alloc] init];

    PEXGuiWindowController * const taskWindowCOntroller =
            [[PEXGuiWindowController alloc] initWithViewController:progress];

    PEXCreateAccountTask * const task = [[PEXCreateAccountTask alloc] init];
    task.createAccountInfo = self.holder;

    [progress setTheTask:task];
    self.createAccountTask = task;

    [task addListener:self];
    self.topController = taskWindowCOntroller;

    [super show];

    [taskWindowCOntroller prepareOnScreen:self.parentController];
    [taskWindowCOntroller show:self.parentController];
}

- (void)taskEnded:(const PEXTaskEvent *const)event
{
    NSString * popupText;
    void (^customCompletion)(void);
    bool reloadCpatcha = false;

    const PEXCreateAccountResult result = self.createAccountTask.result;
    switch (result)
    {
        case PEX_CREATE_ACCOUNT_REQUEST_DATA_ERROR:
            popupText = PEXStr(@"msg_create_account_request_data_error");
            break;

        case PEX_CREATE_ACCOUNT_RESPONSE_DATA_ERROR:
            popupText = PEXStr(@"msg_create_account_response_data_error");
            break;

        case PEX_CREATE_ACCOUNT_CONNECTION_ERROR:
            popupText = PEXStr(@"msg_create_account_connection_error");
            break;

        case PEX_CREATE_ACCOUNT_REQUEST_ERROR:
            popupText = PEXStr(@"msg_create_account_http_response_error");
            break;

        case PEX_CREATE_ACCOUNT_SUCCESSFUL_RESPONSE:
        {
            customCompletion = [self checkJsonResponse: self.createAccountTask.jsonResult errorText:&popupText];
            reloadCpatcha = true;
            [PEXReport logEvent: PEX_EVENT_NEW_ACCOUNT_CREATED];
            break;
        }
    }

    PEXGuiController * const parentController = self.parentController;
    void (^finalCompletion)(void) = customCompletion ?
            customCompletion :
            ^{
                [PEXGuiFactory showErrorTextBox:parentController withText:popupText];
                if (reloadCpatcha)
                    [(PEXGuiCreateAccountController *)self.parentController reloadCaptcha];
            };


    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [self dismissWithCompletion:finalCompletion];
    });

}

- (void(^)(void)) checkJsonResponse: (NSDictionary * const) jsonData errorText: (NSString **) errorTextOut
{
    void (^result)(void);
    NSString *errorText;

    const int responseCode = ((NSNumber *) jsonData[@"responseCode"]).integerValue;

    switch (responseCode)
    {
        case 200: {
            errorText = PEXStr(@"msg_account_successfully_created");

            PEXNewAccountInfo *const newAccountInfo = [[PEXNewAccountInfo alloc] init];

            newAccountInfo.username = jsonData[@"username"];

            id password = jsonData[@"password"];
            if ([password isKindOfClass:[NSNumber class]])
            {
                // NSNumber
                newAccountInfo.tempPassword = [password stringValue];
            }
            else
            {
                // NSString
                newAccountInfo.tempPassword = password;
            }

            NSNumber * const expirationDateInSeconds = jsonData[@"expirationTimestamp"];

            newAccountInfo.expirationDate =
                    [NSDate dateWithTimeIntervalSince1970: expirationDateInSeconds.longLongValue];

            id<PEXNewAccountCreatedListener> listenerRefCopy = self.listener;

            result = ^{
                [listenerRefCopy newAccountCreated:newAccountInfo];
            };

            break;
        }

        case 400:
            errorText = PEXStr(@"msg_something_is_missing");
            break;

        case 401:
            errorText = PEXStr(@"msg_bad_captcha");
            break;

        case 402:
            errorText = PEXStr(@"msg_user_already_in_trial");
            break;

        case 404:
            errorText = PEXStr(@"msg_username_exists");
            break;

        case 405:
            errorText = PEXStr(@"msg_invalid_username_format");
            // this shouldn't happen since there is a validation also on client side
            break;

        case 406:
            errorText = PEXStr(@"msg_invalid_product_code");
            break;

        case 407:
            errorText = PEXStr(@"msg_product_code_alredy_taken");
            break;

        case 408:
            errorText = PEXStr(@"msg_invalid_version");
            break;

        case 409:
            errorText = PEXStr(@"msg_the_ecode_expired");
            break;

            // this shouldn't really happen
        default:
            //Log.ef(TAG, "Error: %d: unknown error", code);
            errorText = PEXStr(@"msg_unknown_error");
            break;
    }

    *errorTextOut = errorText;

    return result;
}

- (void) taskStarted: (const PEXTaskEvent * const) event {}
- (void)taskProgressed:(const PEXTaskEvent *const)event {}
- (void)taskCancelStarted:(const PEXTaskEvent *const)event {}
- (void)taskCancelEnded:(const PEXTaskEvent *const)event {}
- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {}


@end