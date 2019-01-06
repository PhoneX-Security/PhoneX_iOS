//
//  PEXGuiConversationItemView.h
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiClickableHighlightedView.h"
#import "PEXGuiRowItemView.h"

#import "PEXGuiStaticDimmer.h"

@class PEXGuiMenuLine;
@class PEXGuiChat;
@class PEXDbMessage;
@class PEXDbContact;
@class PEXGuiClassicLabel;

@interface PEXGuiChatItemView : PEXGuiRowItemView<UIGestureRecognizerDelegate,PEXGuiStaticDimmer>

@property (nonatomic) PEXGuiClassicLabel * L_name;

- (id)initWithChat:(const PEXGuiChat * const) chat;
- (void) initGuiStuff;
- (void) applyChat: (const PEXGuiChat * const) chat;

+ (bool) contact: (const PEXDbContact * const) c1
     needsUpdate: (const PEXDbContact * const) c2;
- (void) applyContact: (const PEXDbContact * const) contact;

- (void) applyMessage: (const PEXDbMessage * const) message;
- (void) highlighted;
- (void) normal;
+ (bool) message: (const PEXDbMessage * const) m1
     needsUpdate: (const PEXDbMessage * const) m2;

@end
