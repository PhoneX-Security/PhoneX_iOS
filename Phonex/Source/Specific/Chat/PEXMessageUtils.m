//
//  PEXMessageUtils.m
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMessageUtils.h"

#import "PEXStringUtils.h"
#import "PEXMessageManager.h"

@implementation PEXMessageUtils

+ (bool) isSendeable: (NSString * const) messageText
{
    NSString * const textToSend = messageText;
    // null length
    if (textToSend.length == 0)
        return false;

    // white spaces and tabs only
    if ([PEXStringUtils isEmpty:textToSend])
        return false;

    return true;
}

+ (void) callSendMessage: (NSString *) to body: (NSString *) body
{

    [[PEXMessageManager instance] sendMessage:[[PEXAppState instance] getPrivateData].username
                                           to:to
                                         body:body];
}

@end
