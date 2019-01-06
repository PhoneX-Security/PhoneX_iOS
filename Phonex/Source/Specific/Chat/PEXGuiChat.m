//
// Created by Matej Oravec on 02/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiChat.h"

#import "PEXDbContact.h"

@interface PEXGuiChat ()

@property (nonatomic) PEXDbMessage * lastReceivedMessage;
@property (nonatomic) PEXDbMessage * lastOutgoingMessage;
@property (nonatomic) PEXDbMessage * theNewestMessage;

@end

@implementation PEXGuiChat {

}

- (PEXDbMessage *)getNewestMessage
{
    return self.theNewestMessage;
}

- (void) setMessage: (PEXDbMessage * const) message
{
    if (message.isOutgoing.integerValue == 1)
        self.lastOutgoingMessage = message;
    else
        self.lastReceivedMessage = message;

    // set the newest
    if (!self.lastOutgoingMessage) {
        self.theNewestMessage = self.lastReceivedMessage;
        return;
    }

    if (!self.lastReceivedMessage) {
        self.theNewestMessage = self.lastOutgoingMessage;
        return;
    }

    self.theNewestMessage =
            (([PEXDateUtils date:self.lastReceivedMessage.date isOlderThan:self.lastOutgoingMessage.date]) ?
            self.lastOutgoingMessage :
            self.lastReceivedMessage);
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];

    [copy setWithContact:self.withContact];
    [copy setLastReceivedMessage:self.lastReceivedMessage];
    [copy setLastOutgoingMessage:self.lastOutgoingMessage];

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToChat:other];
}

- (BOOL)isEqualToChat:(const PEXGuiChat * const)chat {
    if (self == chat)
        return YES;
    if (chat == nil)
        return NO;
    if (![self.withContact isEqualToContact:chat.withContact])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.withContact hash];
}

@end