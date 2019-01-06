//
//  PEXSelectionManager.m
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiDialogBinaryListener.h"
#import "PEXGrandSelectionManager.h"
#import "PEXService.h"
#import "PEXMessageManager.h"
#import "PEXFileToSendEntry.h"
#import "NSBundle+PEXResCrypto.h"

#import "PEXMessageUtils.h"
#import "PEXFileRestrictorManager.h"
#import "PEXGuiFactory.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXChatAccountingManager.h"

@interface PEXGrandSelectionManager ()

@property (nonatomic) NSMutableArray * controllers;
@property (nonatomic) NSMutableArray * listeners;
@end

@implementation PEXGrandSelectionManager

- (id) init
{
    self = [super init];

    self.controllers = [[NSMutableArray alloc] init];
    self.listeners = [[NSMutableArray alloc] init];

    return self;
}

- (void) addListener: (id<PEXGrandListener>) listener
{
    [self.listeners addObject:listener];
}

- (void) removeListener: (id<PEXGrandListener>) listener
{
    [self.listeners removeObject:listener];
}

- (void) addController: (UIViewController * const) controller
{
    [self.controllers addObject:controller];
}

- (void) removeController: (UIViewController * const) controller
{
    [self.controllers removeObject:controller];

    if (self.controllers.count < 1)
        [self disintegrate];
}

- (void) disintegrate
{
    NSArray * controllers =[self.controllers copy];
    for (UIViewController * const controller in controllers)
         [controller dismissViewControllerAnimated:true completion:nil];

    for (id<PEXGrandListener> listener in self.listeners)
         [listener disintegrated];
}

- (void) finish
{
    NSArray * const recipients = self.recipients;

    if (self.selectedFileContainers)
    {
        const int64_t availableFiles =
                [PEXFileRestrictorFactory getAvailableFileCountForPermissions:[PEXFileRestrictorFactory getFilesPermissions]];

        NSArray * const selectedFileContainers = self.selectedFileContainers;

        if ((availableFiles != -1) && (availableFiles < (selectedFileContainers.count * recipients.count)))
        {
            [PEXGrandSelectionManager showNotEnoughFilesToSpend:availableFiles parent:[self getPrentController]];
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {

            for (PEXDbContact * curRecipient in recipients){
                [[PEXMessageManager instance] sendFile:[[PEXAppState instance] getPrivateData].username
                            to:curRecipient.sip
                         title:nil
                          desc:nil
                         files:selectedFileContainers
                ];
            }
        });

        [self disintegrate];
    }
    else
    {
        const int64_t availableMessages = [PEXChatAccountingManager getAvailableMessages:nil];

        if ((availableMessages != -1) && (availableMessages < recipients.count))
        {
            [PEXGrandSelectionManager showNotEnoughMessagesToSpend:availableMessages parent:[self getPrentController]];
            return;
        }

        NSString * const text = self.messageText;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            for (const PEXDbContact *contact in recipients) {
                [PEXMessageUtils callSendMessage:contact.sip body:text];
            }
        });

        [self disintegrate];
    }
}

+(void) showNotEnoughFilesToSpend: (const int64_t) available
                           parent: (UIViewController * const) parent
{
    NSString * const text = [NSString stringWithFormat:@"%@\n%@: %lld",
                    PEXStr(@"txt_not_enough_files_to_spend"), PEXStr(@"L_files_to_spend"), available];

    [self showNotEnoughParent:parent withLoadingText:text];
}

+(void) showNotEnoughMessagesToSpend: (const int64_t) available
                              parent: (UIViewController * const) parent
{
    NSString * const text = [NSString stringWithFormat:@"%@\n%@: %lld",
                    PEXStr(@"txt_not_enough_messages_to_spend"), PEXStr(@"L_messages_to_spend"), available];

    [self showNotEnoughParent:parent withLoadingText:text];
}

+ (void)showNotEnoughParent:(UIViewController *const)parent
            withLoadingText: (NSString * const) leadingText
{
    PEXGuiNotEnoughListener * const listener = [[PEXGuiNotEnoughListener alloc] init];
    listener.parent = parent;

    listener.dialog = [PEXGuiFactory showBinaryDialog:parent
                           withText:leadingText
                           listener:listener
                      primaryAction:PEXStrU(@"L_buy")
                    secondaryAction:nil];
}

- (UIViewController *) getPrentController
{
    return self.controllers[self.controllers.count - 1];
}

@end

@interface PEXGuiNotEnoughListener ()


@end

@implementation PEXGuiNotEnoughListener
{

}

- (void) secondaryButtonClicked
{
    WEAKSELF;
    [[self dialog] dismissViewControllerAnimated:true completion:^{
        if (weakSelf.secondaryClickBlock){
            weakSelf.secondaryClickBlock();
        }
    }];
}

- (void) primaryButtonClicked
{
    WEAKSELF;
    UIViewController * const parent = self.parent;
    [[self dialog] dismissViewControllerAnimated:true completion:^{
        if (weakSelf.primaryClickBlock){
            weakSelf.primaryClickBlock();
        }

        PEXGuiManageLicenceController * const controller = [[PEXGuiManageLicenceController alloc] init];
        [controller showInNavigation:parent title:PEXStrU(@"L_manage_licence")];
    }];
}

@end