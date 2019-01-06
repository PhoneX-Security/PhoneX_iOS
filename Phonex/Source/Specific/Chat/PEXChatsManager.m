//
// Created by Matej Oravec on 01/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXChatsManager.h"
#import "PEXControllerManager_Protected.h"

#import "PEXUri.h"
#import "PEXGuiContentLoaderController_Protected.h"
#import "PEXDbContact.h"
#import "PEXDBMessage.h"
#import "PEXGuiChatsController.h"
#import "PEXGuiChat.h"
#import "PEXGuiChatItemView.h"
#import "PEXMessageManager.h"
#import "PEXArrayUtils.h"
#import "PEXGuiChatController.h"
#import "PEXGuiBinaryDialogExecutor.h"

@interface PEXChatsManager ()

@property (nonatomic) NSMutableArray * items;

@end

@implementation PEXChatsManager {

}

- (void) fillController
{
    [self executeOnControllerSync:^{
        [(PEXGuiChatsController *) self.controller largeUpdate];
    }];
}

- (void)loadItems
{
    PEXDbCursor * const cursor = [self loadNewestMessages];

    [self chatsAddedForCursor:cursor];
}

- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbMessage getURI]])
        [self messageAdded: ((PEXDbUri*)uri).itemId];
}

- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbMessage getURI]])
        [self messagesDeleted];
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if ([uri isEqualToUri:[PEXDbContact getURI]])
    {
        [self contactUpdate];
        return;
    }

    if ([uri isEqualToUri:[PEXDbMessage getURI]])
    {
        [self messageUpdate];
        return;
    }
}

// must be called in mute
- (void) messageAdded: (const NSNumber * const) idValue
{
    PEXDbCursor * const cursor = [self loadMessageWithId:idValue];

    [self.lock lock];
    [self chatsAddedForCursor:cursor];
    [self.controller checkEmpty];
    [self.lock unlock];
}

- (void)chatsAddedForCursor:(PEXDbCursor *const)cursor
{
    NSMutableArray * const indexPathsToAdd = [[NSMutableArray alloc] init];
    const bool wasEmpty = [self isEmpty];

    int index = 0;
    while (cursor && [cursor moveToNext])
    {
        PEXDbMessage * const message = [PEXDbMessage messageFromCursor:cursor];
        const PEXGuiChat * chat = [self getPotentialChatByMessage:message outIndex:nil];

        if (!chat)
        {
            PEXDbCursor * const contactCursor =
                    [self loadContactWithSip:[PEXDbMessage getContactSipFromMessage:message]];

            if (contactCursor && [contactCursor moveToNext])
            {
                PEXDbContact * const contact = [PEXDbContact contactFromCursor:contactCursor];
                [self addChatForContact:contact message:message];
            }
        }
            // UPDATE CHAT VIEW MESSAGE
        else if ([PEXDateUtils date:chat.lastOutgoingMessage.date isOlderThan:message.date] ||
                [PEXDateUtils date:chat.lastReceivedMessage.date isOlderThan:message.date])
        {
            [self updateChat:chat withMessage:message];
        }
    }
}

- (void) messagesDeleted
{
    PEXDbCursor * const messageCursor = [self loadNewestMessages];

    [self.lock lock];

    // CHECK AND UPDATE
    NSMutableArray * const checkedIndicies = [[NSMutableArray alloc] init];
    while (messageCursor && [messageCursor moveToNext])
    {
        PEXDbMessage * const message = [PEXDbMessage messageFromCursor:messageCursor];
        NSUInteger index = NSUIntegerMax;
        PEXGuiChat * const chat = [self getPotentialChatByMessage:message outIndex:&index];
        if (chat)
        {
            [checkedIndicies addObject:@(index)];

            if (![chat.lastOutgoingMessage isEqualToMessage:message] ||
                    ![chat.lastReceivedMessage isEqualToMessage:message])
            {
                [self updateChat:chat withMessage:message];
            }
        }
    }

    // REMOVE THOSE WITHOUT ANY MESSAGE
    NSArray * const keys = self.items;
    int modifier = 0;
    for (NSUInteger i = 0; i < keys.count; ++i)
    {
        if (![checkedIndicies containsObject:@(i + modifier)])
        {
            [self removeChat:keys[i]];
            ++modifier;
            --i;
        }
    }

    [self.controller checkEmpty];

    [self.lock unlock];
}

- (void) updateController: (void (^)(void))update shouldBeLarge: (const bool) shouldBeLarge
{
    if (shouldBeLarge)
    {
        [self executeOnControllerSync:^{
            [(PEXGuiChatsController *) self.controller largeUpdate];
        }];
    }
    else
    {
        [self executeOnControllerSync:^{
            update();
        }];
    }
}

- (void) contactUpdate
{
    PEXDbCursor * const cursor = [self loadAllContacts];

    [self.lock lock];

    NSMutableArray * const indexPathsToUpdate = [[NSMutableArray alloc] init];
    while (cursor && [cursor moveToNext])
    {
        PEXDbContact * const dbContact = [PEXDbContact contactFromCursor:cursor];
        for (PEXGuiChat * const chat in self.items)
        {
            const PEXDbContact * const cachedContact = chat.withContact;

            if ([cachedContact isEqualToContact:dbContact] &&
                    [PEXGuiChatItemView contact:cachedContact needsUpdate:dbContact])
            {
                chat.withContact = dbContact;
                const NSUInteger index = [self.items indexOfObject:chat];

                [indexPathsToUpdate addObject:[NSIndexPath indexPathForItem:index inSection:0]];
            }
        }
    }

    if (indexPathsToUpdate.count > 0)
    {
        [self executeOnControllerSync:^{
            [(PEXGuiChatsController *) self.controller updateItemsForIndexPaths:indexPathsToUpdate];
        }];
    }

    [self.lock unlock];
}

- (void) messageUpdate
{
    // laods newest sent and received if exist for each chat
    PEXDbCursor * const messageCursor = [self loadNewestMessages];

    [self.lock lock];

    while (messageCursor && [messageCursor moveToNext])
    {
        PEXDbMessage * const message = [PEXDbMessage messageFromCursor:messageCursor];
        NSString * const sip = [PEXDbMessage getContactSipFromMessage:message];
        PEXGuiChat * chat = [self getPotentialChatByContactSip:sip outIndex:nil];

        if (chat)
        {
            if ((([chat.lastOutgoingMessage isEqualToMessage:message]) &&
                    [PEXGuiChatItemView message:chat.lastOutgoingMessage needsUpdate:message])
                    || (([chat.lastReceivedMessage isEqualToMessage:message]) &&
                    [PEXGuiChatItemView message:chat.lastReceivedMessage needsUpdate:message]))
            {
                [self updateChat:chat withMessage:message];
            }
        }
    }

    [self.lock unlock];
}

- (PEXGuiChat *) addChatForContact: (PEXDbContact * const) contact
                           message:(PEXDbMessage * const) message
{
    PEXGuiChat * const chat = [[PEXGuiChat alloc] init];
    chat.withContact = contact;
    [chat setMessage:message];

    const bool wasEmpty = [self isEmpty];
    [self.items addObject:chat];

    // NOTIFICATION STUFF
    bool update = false;
    if ([PEXGNFC messageNotifies:chat.lastReceivedMessage])
    {
        if ([[PEXGNFC instance] increaseMessageNorificationAsync:chat.withContact.sip
                                                      forMessage:chat.lastReceivedMessage])
        {
            chat.highlighted = true;
            update = true;
        }
        else
        {
            chat.lastReceivedMessage.read = @1;
            [PEXMessageManager readMessage:message];
        }
    }

    const NSUInteger index = self.items.count - 1;

    [self updateController:^{
        [(PEXGuiChatsController *) self.controller addItemsForIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                                                               inSection:0]]];
    }
             shouldBeLarge:wasEmpty];

    [self executeOnControllerSync:^{
        [(PEXGuiChatsController *) self.controller updateItemsForIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                                                               inSection:0]]];
    }];

    [self moveToItsRightPosition:chat];

    return chat;

}

- (void) removeChat: (const PEXGuiChat * const) chat
{
    if ([PEXGNFC messageNotifies:chat.lastReceivedMessage])
        [[PEXGNFC instance] decreaseMessageNorificationAsync];

    const NSUInteger indexOfChat = [self.items indexOfObject:chat];
    [self.items removeObjectAtIndex:indexOfChat];

    [self updateController:^{
        [(PEXGuiChatsController *) self.controller
                removeItemsForIndexPaths:@[[NSIndexPath indexPathForItem:indexOfChat
                                                               inSection:0]]];
    }
             shouldBeLarge:[self isEmpty]];
}

// The new message does no need to be newer than the previous
// because of deletion of the previous
// this method is jucst for chat, view and update and notification
// no control logic included intentionally
- (void) updateChat: (PEXGuiChat * const) chat
        withMessage: (PEXDbMessage * const)newMessage
{
    if (newMessage.isOutgoing.integerValue == 0)
        [self shouldNotifyChat:chat withReceivedMessage:newMessage];

    [chat setMessage:newMessage];

    const NSUInteger index = [self.items indexOfObject:chat];
    [self executeOnControllerSync:^{
        [(PEXGuiChatsController *) self.controller
                updateItemsForIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                               inSection:0]]];
    }];

    [self moveToItsRightPosition:chat];
}

- (void )shouldNotifyChat:(PEXGuiChat *const)chat
      withReceivedMessage:(const PEXDbMessage *const)newMessage
{
    const bool oldMessageNotifies = [PEXGNFC messageNotifies:chat.lastReceivedMessage];
    const bool newMessageNotifies = [PEXGNFC messageNotifies:newMessage];

    bool update = false;

    // NOTIFY IF THE NEW LAST MESSAGE IS READ / UNREAD
    if (oldMessageNotifies && !newMessageNotifies)
    {
        [[PEXGNFC instance] decreaseMessageNorificationAsync];
        chat.highlighted = false;
        update = true;
    }
    else if (!oldMessageNotifies && newMessageNotifies)
    {
        if ([[PEXGNFC instance]
                increaseMessageNorificationAsync:chat.withContact.sip forMessage:newMessage])
        {
            chat.highlighted = true;
            update = true;
        }
        else
        {
            // WE ARE IN THE CHAT OF THE MESSAGE
            // THERE WILL BE DB NOTIFICATION OF READING THE MESSAGE FROM increase...
            // THE LAST MESSAGE STAYS AND THE NEW WILL BE READ SO NO NOTFICATION WILL BE RAISED

            newMessage.read = @1;
            [PEXMessageManager readMessage:newMessage];
        }
    }
    else if (oldMessageNotifies && newMessageNotifies)
    {
        [[PEXGNFC instance] repeatMessageNorificationAsync:chat.withContact.sip];
    }

    if (update)
    {
        const NSUInteger index = [self.items indexOfObject:chat];
        [self executeOnControllerSync:^{
            [(PEXGuiChatsController *) self.controller
                    updateItemsForIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        }];
    }
}

#pragma listing stuff

// must not be in the keys
- (void) moveToItsRightPosition: (const PEXGuiChat * const) chat
{
    NSArray * const keys = self.items;
    NSUInteger finalPosition = 0;

    for (const PEXGuiChat * const currentChat in keys)
    {
        if ([PEXDateUtils date:[chat getNewestMessage].date isNewerThanOrEqualTo:[currentChat getNewestMessage].date])
            break;

        ++finalPosition;
    }

    const NSUInteger from = [self.items indexOfObject:chat];

    if ([PEXArrayUtils moveFrom:from to:finalPosition on:self.items])
    {
        NSIndexPath * const indexPathFrom = [NSIndexPath indexPathForItem:from inSection:0];
        NSIndexPath * const indexPathTo = [NSIndexPath indexPathForItem:finalPosition inSection:0];

        [self executeOnControllerSync:^{
            [(PEXGuiChatsController *) self.controller moveItemFrom:indexPathFrom to:indexPathTo];
        }];
    }
}

- (PEXGuiChat *) getPotentialChatByContactSip: (NSString * const) sip
                                     outIndex: (NSUInteger *) outIndex
{
    PEXGuiChat * result = nil;
    const NSArray * const keys = self.items;

    for (NSUInteger i = 0; i < keys.count; ++i)
    {
        PEXGuiChat * const chat = keys[i];
        if ([sip isEqualToString: [PEXDbMessage getContactSipFromMessage:chat.lastOutgoingMessage]] ||
                [sip isEqualToString: [PEXDbMessage getContactSipFromMessage:chat.lastReceivedMessage]])
        {
            result = chat;
            if (outIndex != nil)
            {
                *outIndex = i;
            }
            break;
        }
    }

    return result;
}

- (PEXGuiChat *) getPotentialChatByMessage: (const PEXDbMessage * const) message
                                  outIndex: (NSUInteger *) outIndex
{
    return [self getPotentialChatByContactSip:[PEXDbMessage getContactSipFromMessage:message] outIndex:outIndex];
}

#pragma database

/* some cursor stuff */
// returns newest sent and received for each chat if they exist
- (PEXDbCursor *) loadNewestMessages
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getNewestMessageFullProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:[NSString stringWithFormat:@"%@ %@",
                                             [PEXDbMessage getNewestMessageFullProjectionGroupBy],
                                             [PEXDbMessage getSortByDateNewestFirst]]];
}

- (PEXDbCursor *) loadMessageWithId:(const NSNumber * const) idValue
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getNewestMessageFullProjection]
        selection: [PEXDbMessage getWhereForId]
    selectionArgs: [PEXDbMessage getWhereForIdArgs:idValue]
        sortOrder:nil];
}

- (PEXDbCursor *) loadNewestMessageForContact: (const PEXDbContact * const) contact
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getNewestMessageFullProjection]
        selection:[PEXDbMessage getWhereForContact]
    selectionArgs:[PEXDbMessage getWhereForContactArgs:contact]
        sortOrder:[NSString stringWithFormat:@"%@ %@",
                                             [PEXDbMessage getNewestMessageFullProjectionGroupBy],
                                             [PEXDbMessage getSortByDateNewestFirst]]];
}


- (PEXDbCursor *) loadAllContacts
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
       projection:[PEXDbContact getLightProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:nil];
}


- (PEXDbCursor *) loadContactWithId: (const NSNumber * const) idValue
{
    return [[PEXDbAppContentProvider instance]
            query:[PEXDbContact getURI]
       projection:[PEXDbContact getLightProjection]
        selection:[PEXDbContact getWhereForId]
    selectionArgs:[PEXDbContact getWhereForIdArgs:idValue]
        sortOrder:nil];
}

- (PEXDbCursor *) loadContactWithSip: (NSString * const) sip
{

    return sip ? [[PEXDbAppContentProvider instance]query:[PEXDbContact getURI]
                                               projection:[PEXDbContact getLightProjection]
                                                selection:[NSString stringWithFormat:@"WHERE %@=?", DBCL(FIELD_SIP)]
                                            selectionArgs:@[sip]
                                                sortOrder:nil]
            : nil;
}

#pragma actions

- (void)callRemoveItem:(const id) item
{

    PEXGuiChat * const chat = item;
    PEXGuiBinaryDialogExecutor * const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self.controller];
    executor.primaryButtonText = PEXStrU(@"B_delete");
    executor.secondaryButtonText = PEXStrU(@"B_cancel");
    executor.text = PEXStr(@"txt_delete_chat_question");

    executor.primaryAction = ^{
        PEXDbContact * const contact = chat.withContact;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                ^(void)
                {
                    [PEXMessageManager removeAllForContact: contact];
                });
    };

    [executor show];
}

- (void)actionOnItem:(const id) item
{
    PEXGuiChat * const chat = item;
    [PEXGuiChatController showChatInNavigation:(PEXGuiChatsController *)self.controller withContact:chat.withContact];
}

@end