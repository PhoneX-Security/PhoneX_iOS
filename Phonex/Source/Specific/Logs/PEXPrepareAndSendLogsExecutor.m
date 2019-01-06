//
// Created by Matej Oravec on 02/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPrepareAndSendLogsExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiWindowController.h"
#import "PEXLogsSender.h"


@implementation PEXPrepareAndSendLogsExecutor {

}

- (void) show
{
    PEXGuiProgressController * const progress = [[PEXGuiProgressController alloc] init];
    progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowCOntroller =
            [[PEXGuiWindowController alloc] initWithViewController:progress];

    self.topController = taskWindowCOntroller;

    [super show];

    [taskWindowCOntroller prepareOnScreen:self.parentController];
    [taskWindowCOntroller show:self.parentController];

    [self startPreparation];
}

- (void) startPreparation
{
    static dispatch_queue_t logsQueue;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logsQueue = dispatch_queue_create("send_logs_queue", DISPATCH_QUEUE_SERIAL);
    });

    WEAKSELF;
    dispatch_async(logsQueue, ^{
        PEXLogsSender * const logSender = [[PEXLogsSender alloc] init];
        logSender.userMessage = weakSelf.userMessage;
        const bool preparationResult = [logSender sendLogs];

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dismissWithCompletion: ^{
                if (weakSelf.preparationCompletion)
                    weakSelf.preparationCompletion(preparationResult);
            }];
        });
    });
}

@end