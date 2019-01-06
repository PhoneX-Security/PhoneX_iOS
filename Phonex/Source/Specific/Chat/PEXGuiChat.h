//
// Created by Matej Oravec on 02/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "PEXDbMessage.h"

@class PEXDbMessage;
@class PEXDbContact;

@interface PEXGuiChat : NSObject<NSCopying>

@property (nonatomic) PEXDbContact * withContact;
@property (nonatomic, readonly) PEXDbMessage * lastReceivedMessage;
@property (nonatomic, readonly) PEXDbMessage * lastOutgoingMessage;
@property (nonatomic, assign) bool highlighted;

- (PEXDbMessage *)getNewestMessage;
- (void) setMessage: (PEXDbMessage * const) message;

- (BOOL)isEqualToChat:(const PEXGuiChat * const)chat;

@end