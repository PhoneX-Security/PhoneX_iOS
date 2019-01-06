//
//  PEXGuiConversationItemView.m
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiChatItemView.h"

#import "PEXGuiMenuLine.h"
#import "PEXGuiClassicLabel.h"
#import "PEXDbMessage.h"
#import "PEXUser.h"

#import "PEXGuiChat.h"
#import "PEXDbContact.h"

#import "PEXGuiNotificationCenter.h"

@interface PEXGuiChatItemView ()

//@property (nonatomic) PEXGuiClassicLabel * L_name;
@property (nonatomic) PEXGuiClassicLabel * L_textPreview;
@property (nonatomic) PEXGuiClassicLabel * L_date;
@property (nonatomic) PEXGuiClassicLabel * L_time;

@end

@implementation PEXGuiChatItemView

- (id)initWithChat:(const PEXGuiChat * const) chat
{
    self = [super init];

    [self initGuiStuff];
    [self applyChat:chat];

    return self;
}

- (void) initGuiStuff
{
    self.L_name = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")
                                                     fontColor:PEXCol(@"black_normal")];
    self.L_name.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.L_name];

    self.L_textPreview = [[PEXGuiClassicLabel  alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                             fontColor:PEXCol(@"light_gray_low")];
    self.L_textPreview.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.L_textPreview];

    self.L_date = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_date];

    self.L_time = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_time];
}

- (void) applyChat: (const PEXGuiChat * const) chat
{
    [self applyContact:chat.withContact];
    [self applyMessage:[chat getNewestMessage]];
}

- (void) applyContact: (const PEXDbContact * const) contact
{
    // TODO check equality when more added
    self.L_name.text = contact.displayName;
}

+ (bool) contact: (const PEXDbContact * const) c1
     needsUpdate: (const PEXDbContact * const) c2
{
    return ![c1.displayName isEqualToString: c2.displayName];
}

- (void) applyMessage: (const PEXDbMessage * const) message
{
    if (![self.L_textPreview.text isEqualToString:message.body])
        self.L_textPreview.text = message.body;

    // not compared because of creation of other strings // TODO store date?
    self.L_date.text = [PEXDateUtils dateToDateString:message.date];
    self.L_time.text = [PEXDateUtils dateToTimeString:message.date];
}

- (void) highlighted
{
    [self setNotificationColor:PEXCol(@"orange_low")];
}

- (void) normal
{
    [self setNotificationColor:PEXCol(@"light_gray_low")];
}

- (void) setNotificationColor: (UIColor * const) color
{
    self.L_date.textColor = color;
    self.L_time.textColor = color;
    self.L_textPreview.textColor = color;
}

+ (bool) message: (const PEXDbMessage * const) m1
     needsUpdate: (const PEXDbMessage * const) m2
{
    if (![m1.isOutgoing isEqualToNumber:m2.isOutgoing]) return true;
    //if (![m1.body isEqualToString:m2.body]) return true;
    if (![m1.read isEqualToNumber:m2.read]) return true;

    return false;
}


- (void) wrapTextPreview
{
    const CGFloat maxWidth = self.L_date.frame.origin.x -
        PEXVal(@"dim_size_large") -
        self.L_textPreview.frame.origin.x;
    [PEXGVU setWidth:self.L_textPreview to:maxWidth];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU moveToLeft:self.L_name withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveAboveCenter:self.L_name];

    [PEXGVU moveToLeft:self.L_textPreview withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveBelowCenter: self.L_textPreview];

    [PEXGVU moveToRight:self.L_date withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveAboveCenter: self.L_date];
    [PEXGVU setWidth:self.L_name until:self.L_date withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveToRight:self.L_time withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveBelowCenter: self.L_time];
    [PEXGVU setWidth:self.L_textPreview until:self.L_time withMargin:PEXVal(@"dim_size_large")];
}

@end
