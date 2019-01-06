//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"
#import "PEXMuteNotificationUpdateExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiProgressController_Protected.h"

@interface PEXMuteNotificationUpdateExecutor() {}
@property (nonatomic) PEXGuiProgressController * progress;
@end

@implementation PEXMuteNotificationUpdateExecutor {

}

- (void) show
{
    self.progress = [[PEXGuiProgressController alloc] init];
    self.progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowController =
            [[PEXGuiWindowController alloc] initWithViewController:self.progress];

    [self.progress setShowProgressBar:NO];
    [self.progress showTaskStarted:nil];
    self.topController = taskWindowController;

    [super show];

    [taskWindowController prepareOnScreen:self.parentController];
    [taskWindowController show:self.parentController];
}

- (void)finishWithSuccess:(BOOL)success completionHandler: (dispatch_block_t) completionHandler {
    WEAKSELF;
    DDLogVerbose(@"Going to dismiss executor");
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf dismissWithCompletion:completionHandler];
    });
}

@end