//
//  PEXContactRemoveExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 07/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactRemoveExecutor.h"

#import "PEXContactRemoveTask.h"
#import "PEXContactRenameEvents.h"
#import "PEXTaskListener.h"

#import "PEXGuiContactsController.h"
#import "PEXDbContact.h"

#import "PEXContactRemoveEvents.h"
#import "PEXUnmanagedObjectHolder.h"

#import "PEXGuiFactory.h"
#import "PEXContactRenameTask.h"
#import "PEXService.h"
#import "PEXDbCallLog.h"
#import "PEXMessageManager.h"

@interface  PEXContactRemoveExecutor ()

@property (nonatomic, weak) PEXGuiContactsController * contactsController;
@property (nonatomic) const PEXDbContact * contactToRemove;
@property (nonatomic) PEXContactRemoveTask * removeTask;
@property (nonatomic) PEXContactRenameTask * renameTask;

@end

@implementation PEXContactRemoveExecutor

- (id) initWithController: (PEXGuiContactsController *) contactsController
          contactToRemove: (const PEXDbContact * const) contact
{
    self = [super init];

    [PEXUnmanagedObjectHolder addActiveObject:self forKey:self];
    self.contactsController = contactsController;
    self.contactToRemove = contact;

    return self;
}

- (BOOL) removeSystemContact: (PEXDbContact const * ) contact{

    // Fix for system account that cannot be removed. Rename is called instead.
    if (![[PEXService instance] isUriSystemContact:self.contactToRemove.sip]) {
        self.renameTask = nil;
        return NO;
    }

    // Already hidden?
    if (self.contactToRemove.hideContact != nil && [self.contactToRemove.hideContact boolValue]){
        DDLogWarn(@"Contact should be already hidden.");
        NSString * errorText = PEXStr(@"txt_add_contact_unknown_user");

        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showTextBox:self.contactsController text:errorText title:PEXStrU(@"L_contact_remove_failed")];
            [weakSelf finishFailed];
        });
        return YES;
    }

    self.renameTask = [[PEXContactRenameTask alloc] init];
    self.renameTask.contactAddress = self.contactToRemove.sip;
    self.renameTask.contactAlias = [PEXDbContact prependHidePrefix:self.contactToRemove.displayName wasPresent:nil];
    [self.renameTask addListener:self];
    [self.renameTask start];
    return YES;
}

- (void) execute
{
    if ([self removeSystemContact:self.contactToRemove]){
        return;
    }

    // Ordinary remove task.
    self.removeTask =
    [PEXContactRemoveTask taskWithContactAddress:self.contactToRemove.sip];
    [self.removeTask addListener:self];
    [self.removeTask start];
}

- (void) taskStarted: (const PEXTaskEvent * const) event{}

- (void) taskSysUserRenameEnded: (const PEXTaskEvent * const) event {
    const PEXContactRenameTaskEventEnd * const ev= (PEXContactRenameTaskEventEnd *) event;
    PEXContactRenameResultDescription desc = [ev getResult].resultDescription;

    if (desc == PEX_CONTACT_RENAME_RESULT_RENAMED)
    {
        // Remove call logs.
        [PEXDbCallLog removeCallLogsFor:self.contactToRemove.sip cr:[PEXDbAppContentProvider instance]];

        // Remove messages.
        [PEXMessageManager removeAllForContact:self.contactToRemove];

        [self finish];
        return;
    }

    if (desc == PEX_CONTACT_RENAME_CANCELLED)
    {
        [self finishFailed];
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
        case PEX_CONTACT_RENAME_RESULT_RENAMED:break;
        case PEX_CONTACT_RENAME_CANCELLED:break;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [PEXGuiFactory showTextBox:self.contactsController text:errorText title:PEXStrU(@"L_contact_remove_failed")];
    });

    [self finishFailed];
    return;
}

- (void) taskEnded: (const PEXTaskEvent * const) event
{
    if (self.renameTask != nil){
        [self taskSysUserRenameEnded:event];
        return;
    }

    const PEXContactRemoveTaskEventEnd * const remEvent = (PEXContactRemoveTaskEventEnd *) event;
    PEXContactRemoveResult * const result = [remEvent getResult];
    const PEXContactRemoveResultDescription desc = result.resultDescription;

    if (desc == PEX_CONTACT_REMOVE_RESULT_REMOVED)
    {
        [self finish];
        return;
    }

    if (desc == PEX_CONTACT_REMOVE_CANCELLED)
    {
        [self finishFailed];
        return;
    }


    NSMutableString * finalText =
    [NSMutableString stringWithFormat:@"Contact: %@", self.contactToRemove.sip];

    NSString * errorText;
    switch (desc)
    {
        case PEX_CONTACT_REMOVE_RESULT_CONNECTION_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_connection_problem");
            break;
        case PEX_CONTACT_REMOVE_RESULT_NO_NETWORK:
            errorText = PEXStr(@"txt_add_contact_no_network");
            break;
        case PEX_CONTACT_REMOVE_RESULT_ILLEGAL_LOGIN_NAME:
            errorText = PEXStr(@"txt_add_contact_illegal_login_name");
            break;
        case PEX_CONTACT_REMOVE_RESULT_SERVERSIDE_PROBLEM:
            errorText = PEXStr(@"txt_add_contact_serverside_problem");
            break;
        case PEX_CONTACT_REMOVE_RESULT_UNKNOWN_USER:
            errorText = PEXStr(@"txt_add_contact_unknown_user");
            break;
        case PEX_CONTACT_REMOVE_RESULT_REMOVED:break;
        case PEX_CONTACT_REMOVE_CANCELLED:break;
    }

    [finalText appendString:errorText];

    dispatch_async(dispatch_get_main_queue(), ^{
        [PEXGuiFactory showTextBox:self.contactsController text:finalText title:PEXStrU(@"L_contact_remove_failed")];
    });

    [self finishFailed];
}

- (void) finishFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.contactsController setEnabled:true forContact:self.contactToRemove];
    });

    [self finish];
}

- (void) finish
{
    [PEXUnmanagedObjectHolder removeActiveObjectForKey:self];
}

- (void) taskProgressed: (const PEXTaskEvent * const) event{}
- (void) taskCancelStarted: (const PEXTaskEvent * const) event{}
- (void) taskCancelEnded: (const PEXTaskEvent * const) event{}
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event{}

@end
