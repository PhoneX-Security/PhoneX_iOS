//
// Created by Dusan Klinec on 21.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiChatLinkActivity.h"
#import "PEXGuiTransparentController.h"
#import "PEXFileData.h"
#import "PEXGuiShieldManager.h"
#import "PEXGuiOpenInActivity.h"

@interface PEXGuiChatLinkActivity () <PEXGuiOpenInActivityDelegate>

@property (nonatomic) UIActivityViewController * const activityController;

@property (nonatomic) UIViewController * optionsControllerHolder;
@property (nonatomic) PEXGuiTransparentController * previewControllerHolder;

@end

@implementation PEXGuiChatLinkActivity

- (void) openUrl: (NSURL *) url forView: (UIView * const) view
{
    if (url == nil){
        DDLogError(@"URL to open is nil");
        return;
    }

    [self openInActivity:@[url] forView:view];
}

- (void) openUrls: (NSArray<NSURL*>*) urls forView: (UIView * const) view
{
    [self openInActivity:urls forView:view];
}

- (void) openItems: (NSArray*) items forView: (UIView * const) view
{
    [self openInActivity:items forView:view];
}

- (void) openInActivity: (NSArray *) items forView: (UIView * const) view
{
    self.optionsControllerHolder = [PEXGVU showModalTransparentController];

    PEXGuiOpenInActivity * const openInAppActivity = [[PEXGuiOpenInActivity alloc] init];
    openInAppActivity.superController = self.optionsControllerHolder;

    // INIT ACTIVITY CONTROLLER
    self.activityController =
            [self getActivityController:items
                  applicationActivities:nil];

//    openInAppActivity.activityController = self.activityController;
//    openInAppActivity.delegate = self;

    //https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIPopoverPresentationController_class/index.html
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) &&
            SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        self.activityController.popoverPresentationController.sourceView = self.optionsControllerHolder.view;
        self.activityController.popoverPresentationController.sourceRect = view.frame;
    }

    // SHOW IT
    [self.optionsControllerHolder presentViewController:self.activityController animated:true completion:nil];
    [[PEXGuiShieldManager instance] addVictim:self.optionsControllerHolder];
}

///////////////////////////////////////////
////////////// ACTIVITY ///////////////////
///////////////////////////////////////////

- (UIActivityViewController *) getActivityController:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    // INIT ACTIVITY CONTROLLER
    UIActivityViewController * const result =
            [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                              applicationActivities:applicationActivities];

    // iOS 7
    WEAKSELF;
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        [result setCompletionWithItemsHandler:
                ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                    [weakSelf activityWithItemsHandler:activityType completed:completed returnedItems:returnedItems error:activityError];
                }];
    }
    else
    {
        [result setCompletionHandler:^(NSString *activityType, BOOL completed){
            [weakSelf activityHandler:activityType completed:completed];
        }];
    }

    return result;
}

- (void) activityHandler:(NSString * const) activityType completed:(const BOOL) completed
{
    [self dismissActivity];
}

- (void) activityWithItemsHandler:(NSString * const)activityType completed:(const BOOL) completed
                    returnedItems:(NSArray * const) returnedItems error: (NSError * const) activityError
{
    [self dismissActivity];
}

- (void)openInAppActivityWillPresentDocumentInteractionController:(PEXGuiOpenInActivity*)activity
{
    // DO NOTHING
}

- (void)openInAppActivityDidDismissDocumentInteractionController:(PEXGuiOpenInActivity*)activity
{
    [self dismissActivity];
}

- (void)openInAppActivityDidEndSendingToApplication:(PEXGuiOpenInActivity*)activity
{
    [self dismissActivity];
}

- (void)openInAppActivityDidSendToApplication:(NSString*)application
{
    [self dismissActivity];
}

- (void) dismissActivity
{
    [[PEXGuiShieldManager instance] removeVictim:self.optionsControllerHolder];
    [self.optionsControllerHolder dismissViewControllerAnimated:true completion:nil];
    self.optionsControllerHolder = nil;
}

@end
