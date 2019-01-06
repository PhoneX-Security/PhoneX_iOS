//
//  PEXGuiOpenInActivity.m
//  Phonex
//
//  Created by Matej Oravec on 09/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiOpenInActivity.h"

#import <MobileCoreServices/MobileCoreServices.h> // For UTI
#import <ImageIO/ImageIO.h>
#import "PEXGuiLoginController.h"

@interface PEXGuiOpenInActivity () <UIActionSheetDelegate>

@property (nonatomic) NSArray *fileURLs;

@property (nonatomic) UIDocumentInteractionController * docController;

- (NSString *)UTIForURL:(NSURL *)url;
- (void)openDocumentInteractionControllerWithFileURL:(NSURL *)fileURL;
- (void)openSelectFileActionSheet;

@end

@implementation PEXGuiOpenInActivity

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
    return PEXStr(@"L_open_in");
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"openIn"];
}

- (bool) canPerformWithItem: (const id) item
{
    return [item isKindOfClass:[NSURL class]] && [(NSURL *)item isFileURL];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    self.fileURLs = activityItems;
}

- (void)performActivity
{
    if (!self.activityController){
        [self activityDidFinish:YES];
        return;
    }

    //  Check to see if it's presented via popover
    if ([self.activityController respondsToSelector:@selector(dismissPopoverAnimated:)])
    {
        [self.activityController dismissPopoverAnimated:YES];
        [((UIPopoverController *)self.activityController).delegate
            popoverControllerDidDismissPopover:self.activityController];

        [self present];
    }
    else if([self.activityController presentingViewController])
    {
        //  Not in popover, dismiss as if iPhone
        [self.activityController dismissViewControllerAnimated:YES completion:^(void){
            [self present];
        }];
    }
    else
    {
        [self present];
    }
}

- (void) present
{/*
    if (self.fileURLs.count > 1)
    {
        [self openSelectFileActionSheet];
    }
    else*/
    {
        [self openDocumentInteractionControllerWithFileURL:self.fileURLs.lastObject];
    }
}

#pragma mark - Helper
- (NSString *)UTIForURL:(NSURL *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    return (NSString *)CFBridgingRelease(UTI) ;
}

- (void)openDocumentInteractionControllerWithFileURL:(NSURL *)fileURL
{
    // Open "Open in"-menu
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.docController.delegate = self;
    self.docController.UTI = [self UTIForURL:fileURL];
    BOOL sucess; // Sucess is true if it was possible to open the controller and there are apps available

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        sucess = [self.docController presentOpenInMenuFromRect:CGRectZero inView:self.superController.view animated:YES];
    }
    else
    {
        sucess = [self.docController presentOpenInMenuFromRect:self.superController.view.frame inView:self.superController.view animated:YES];
    }

    if(!sucess){

        // There is no app to handle this file
        NSString *deviceType = [UIDevice currentDevice].localizedModel;
        NSString *message = [NSString stringWithFormat:PEXStr(@"txt_no_suitable_app_available"), deviceType];

        // Display alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:PEXStr(@"L_no_suitable_app_available")
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:PEXStrU(@"B_ok")
                                              otherButtonTitles:nil];
        [alert show];

        // Inform app that the activity has finished
        // Return NO because the service was canceled and did not finish because of an error.
        // http://developer.apple.com/library/ios/#documentation/uikit/reference/UIActivity_Class/Reference/Reference.html

        [self activityDidFinish:NO];
    }
}

- (void)dismissDocumentInteractionControllerAnimated:(BOOL)animated {

    [self.docController dismissMenuAnimated:animated];
    [self activityDidFinish:NO];
}

- (void)openSelectFileActionSheet
{
    UIActionSheet * const actionSheet = [[UIActionSheet alloc] initWithTitle:PEXStr(@"L_select_file")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];

    for (NSURL *fileURL in self.fileURLs) {
        [actionSheet addButtonWithTitle:[fileURL lastPathComponent]];
    }

    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:PEXStr(@"B_cancel")];

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [actionSheet showFromRect:CGRectZero inView:self.superController.view animated:YES];
    }
    else
    {
        [actionSheet showFromRect:self.superController.view.frame inView:self.superController.view animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void) documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    [self.delegate openInAppActivityWillPresentDocumentInteractionController:self];
}

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    [self.docController dismissMenuAnimated:true];
    [self.delegate openInAppActivityDidDismissDocumentInteractionController:self];
}

- (void) documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    [self.delegate openInAppActivityDidDismissDocumentInteractionController:self];
    [self.delegate openInAppActivityDidSendToApplication:application];

    [self activityDidFinish:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        [self openDocumentInteractionControllerWithFileURL:self.fileURLs[buttonIndex]];
    }
    else
    {
        [self activityDidFinish:NO];
    }
}

@end
