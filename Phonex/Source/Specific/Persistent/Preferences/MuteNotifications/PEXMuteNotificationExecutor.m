//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiDialogBinaryListener.h"
#import "PEXMuteNotificationExecutor.h"
#import "PEXGuiMuteNotificationController.h"
#import "PEXGuiFactory.h"
#import "PEXUtils.h"
#import "PEXAccountSettingsTask.h"
#import "PEXSOAPResult.h"
#import "PEXService.h"
#import "PEXMuteNotificationUpdateExecutor.h"


@interface PEXMuteNotificationExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiMuteNotificationController *muteController;

@property (nonatomic) PEXMuteNotificationUpdateExecutor *executor;

@property (nonatomic) PEXAccountSettingsTask * task;

@property (nonatomic) NSString * prefKey;
@end

@implementation PEXMuteNotificationExecutor

- (id) initWithParentController: (PEXGuiController * const)parent prefKey:(NSString *) prefKey
{
    self = [super init];

    self.parent = parent;
    self.prefKey = prefKey;

    return self;
}

- (void)show
{
    self.muteController = [[PEXGuiMuteNotificationController alloc] init];
    self.muteController.prefKey = self.prefKey;

    self.topController = [self.muteController showInWindowWithTitle:self.parent
                                                                        title:PEXStrU(@"L_mute_notification")
                                                           withBinaryListener:self];
    [super show];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self.parent viewDidReveal];
    [super dismissWithCompletion:completion];
}

- (void)secondaryButtonClicked
{
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    WEAKSELF;
    NSNumber * const selectedPeriod = [self.muteController getSelectedPeriod];
    uint64_t muteUntilMilli = [PEXUtils currentTimeMillis] + [selectedPeriod longLongValue];

    dispatch_block_t successBlock = ^{
        DDLogVerbose(@"Settings update successful");
        [[PEXUserAppPreferences instance] setNumberPrefForKey:self.prefKey value:@(muteUntilMilli)];

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dismissWithCompletion:nil];
        });
    };

    dispatch_block_t failureBlock = ^{
        DDLogError(@"Settings update task failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showErrorTextBox:self.muteController
                                   withText:PEXStr(@"txt_settings_change_failed")
                                 completion:^{
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [weakSelf dismissWithCompletion:nil];
                                     });
                                 }];
        });
    };

    // Do network call only if we need to update server side value.
    if (![PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND isEqualToString:self.prefKey]){
        successBlock();
        return;
    }

    [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
        // We need internet connection.
        if (![[PEXService instance] isConnectivityWorking]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [PEXGuiFactory showErrorTextBox:weakSelf.muteController
                                       withText:PEXStr(@"txt_internet_connection_required")
                                     completion:^{
                                         [weakSelf dismissWithCompletion:nil];
                                     }];
            });
            return;
        }

        // Settings task.
        weakSelf.task = [[PEXAccountSettingsTask alloc] init];
        weakSelf.task.privData = [[PEXAppState instance] getPrivateData];
        weakSelf.task.retryCount = 3;
        weakSelf.task.muteUntilMilli = @(muteUntilMilli);
        weakSelf.task.completionHandler = ^(PEXAccountSettingsTask *task) {
            if (task.lastResult.code == PEX_SOAP_CALL_RES_OK){
                successBlock();

            } else {
                failureBlock();
            }
        };

        // Progress monitor, indeterminate.
        weakSelf.executor = [[PEXMuteNotificationUpdateExecutor alloc] init];
        weakSelf.executor.parentController = weakSelf.muteController;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.executor show];
        });

        // Execute on the background task.
        [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
            [weakSelf.task requestWithRetryCount];
        }];
    }];
}

@end
