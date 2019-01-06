//
//  PEXGuiFileSelectVisitor.m
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileSelectAndPreviewVisitor.h"
#import "PEXGuiFileSelectVisitor_Protected.h"
#import "PEXGuiLoginController.h"

#import "PEXGuiTransparentController.h"
#import "PEXGuiPreviewActivity.h"
#import "PEXGuiShieldManager.h"
#import "PEXGuiFactory.h"
#import "PEXReport.h"
#import "PEXGuiFileDetailController.h"

@interface PEXGuiFileSelectAndPreviewVisitor ()

@property (nonatomic) UIActivityViewController * const activityController;

@property (nonatomic) UIViewController * optionsControllerHolder;
@property (nonatomic) PEXGuiTransparentController * previewControllerHolder;

@end

@implementation PEXGuiFileSelectAndPreviewVisitor

- (void) specifyFileView: (PEXGuiFileView * const) fileView
                withData: (const PEXFileData * const) data;
{
    [super specifyFileView:fileView withData:data];

    // we cannot preview/open asset files
    if (![PEXGuiFileUtils isAssetUrl:data.url])
    {
        WEAKSELF;
        __weak __typeof(fileView) weakFileView = fileView;
        [fileView setActionBlock:^{
            [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_ACTION];
            [weakSelf openDocument:data forView:weakFileView];
        }];
        [fileView setLongActionBlock:^{
            [weakSelf documentDetails:data forView:weakFileView];
        }];
    }
    else
    {
        [fileView setEnabled:false];
    }
}


- (void) openDocument: (const PEXFileData * const) data forView: (UIView * const) view
{
    [self openInActivity:data forView:view];
}

- (void) documentDetails: (const PEXFileData * const) data forView: (UIView * const) view {
    PEXGuiFileDetailController *const detail =
            [[PEXGuiFileDetailController alloc] initWithFile:data];

    [PEXGAU showInNavigation:detail
                          in:self.controller
                       title:PEXStrU(@"B_details")];

    // This shows detail controller as a modal window.
    //[detail showInClosingWindow:self.controller title:nil withUnaryListener:nil];
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

- (void) openInActivity: (const PEXFileData * const) data forView: (UIView * const) view
{
    if ([PEXGuiPreviewExecutor extractQlItems:@[data.url]].count == 0) {
        [PEXGuiFactory showErrorTextBox:self.controller.fullscreener
                               withText:PEXStr(@"txt_cannot_find_or_assets")];
        return;
    }

    self.optionsControllerHolder = [PEXGVU showModalTransparentController];

    // INIT ACTIVITIES
    PEXGuiOpenInActivity * const openInAppActivity = [[PEXGuiOpenInActivity alloc] init];
    openInAppActivity.superController = self.optionsControllerHolder;

    PEXGuiPreviewActivity * const previewActivity = [[PEXGuiPreviewActivity alloc] init];
    previewActivity.superController = self.optionsControllerHolder;

    // INIT ACTIVITY CONTROLLER
    self.activityController =
        [self getActivityController:@[data.url]
              applicationActivities:@[openInAppActivity, previewActivity]];


    // SETUP ACTIVITIES
    openInAppActivity.activityController = self.activityController;
    openInAppActivity.delegate = self;

    previewActivity.activityController = self.activityController;
    previewActivity.delegate = self;

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

///////////////////////////////
////// OPEN IN LISTENER ///////
///////////////////////////////

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

///////////////////////////////
////// PREVIEW LISTENER ///////
///////////////////////////////

- (void)previewDidDismiss
{
    [self dismissActivity];
}

@end
