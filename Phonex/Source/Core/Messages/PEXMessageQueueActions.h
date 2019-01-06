//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSendingState.h"
#import "PEXDbMessageQueue.h"

@protocol PEXMessageQueueActions <NSObject>
-(int) deleteMessage: (int64_t) messageId;
-(int) deleteAndReportToAppLayer: (PEXDbMessageQueue *) msg state: (PEXSendingState *) state;
-(int) setMessageProcessed: (int64_t)  messageId isProcessed: (BOOL) isProcessed;
-(int) storeFinalMessageWithHash: (int64_t)  messageId finalMessage: (NSString *) finalMessage;
@end