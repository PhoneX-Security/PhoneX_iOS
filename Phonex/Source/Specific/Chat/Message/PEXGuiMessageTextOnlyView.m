//
//  PEXGuiMessageTextOnlyView.m
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiMessageTextOnlyView.h"
#import "PEXGuiMessageTextOnlyView_Protected.h"
#import "PEXInTextData.h"
#import "PEXInTextDataLink.h"
#import "PEXInTextDataPhoneNumber.h"
#import "PEXGuiMessageTextBodyTextView.h"
#import "PEXMessageModel.h"

@interface PEXGuiMessageTextOnlyView () <TTTAttributedLabelDelegate>
{

}

@end

@implementation PEXGuiMessageTextOnlyView

- (void) initGuiStuff
{
    [super initGuiStuff];

    self.TV_body = [[PEXGuiMessageTextBodyView alloc] initWithFrame:CGRectZero];
    [self.V_bodyContainer addSubview:self.TV_body];

    DDLogVerbose(@"___initGuiStuff %@", self);
}

// The view is already widened by the parentController
- (void) setMessage: (const PEXMessageModel * const) message
{
    [self.TV_body setText:message.attributedString];

    WEAKSELF;
    __weak __typeof(message) wMessage = message;
    if (message.numDataDetectedInBody > 0) {
        for(PEXInTextData * data in message.detectedData){
            TTTAttributedLabelLink * link = [self.TV_body addLinkWithTextCheckingResult:data.match];

            link.linkTapBlock = ^(TTTAttributedLabel *label, TTTAttributedLabelLink *link1) {
                [weakSelf linkTextTTTLabel:label didTapLinkWithData:data withLink:link1 withMessage:wMessage];
            };

            link.linkLongPressBlock = ^(TTTAttributedLabel *label, TTTAttributedLabelLink *link1) {
                [weakSelf linkTextTTTLabel:label didLongTapLinkWithData:data withLink:link1 withMessage:wMessage];
            };
        }
    }

    [super setMessage:message];
}

- (void)clearMessage
{
    self.TV_body.text = @"...";
    [super clearMessage];
}

- (void) layoutTextBody
{
    [PEXGVU setWidth:self.V_bodyContainer to:self.frame.size.width - (2 * PEX_PARGIN)];
    [PEXGVU scaleHorizontally:self.TV_body];

    self.TV_body.numberOfLines = 0;
    [self.TV_body sizeToFit];

    [PEXGVU setWidth:self.V_bodyContainer to:self.TV_body.frame.size.width];
    [PEXGVU setHeight:self.V_bodyContainer to:self.TV_body.frame.size.height];
}

- (void)layoutSubviews
{
    [self layoutTextBody];
    [super layoutSubviews];
}

- (void) linkTextTTTLabel:(TTTAttributedLabel *) label
       didTapLinkWithData:(PEXInTextData *)data
                 withLink:(TTTAttributedLabelLink *) link
              withMessage:(const PEXMessageModel * const) message
{
    DDLogVerbose(@"click: data: %@, link: %@, msg: %@", data, link, message);
    if (self.linkClickDelegate == nil){
        return;
    }

    if ([self.linkClickDelegate respondsToSelector:@selector(userClickedMessage:withData:withView:)]) {
        [self.linkClickDelegate userClickedMessage:message withData:data withView:self];
    }

    if ([data isKindOfClass:[PEXInTextDataLink class]]){
        if ([self.linkClickDelegate respondsToSelector:@selector(userClickedMessage:onURL:withData:withView:)]){
            PEXInTextDataLink * aux = (PEXInTextDataLink *) data;
            [self.linkClickDelegate userClickedMessage:message onURL:aux.url withData:aux withView:self];
        }
    }

    if ([data isKindOfClass:[PEXInTextDataPhoneNumber class]]){
        if ([self.linkClickDelegate respondsToSelector:@selector(userClickedMessage:onPhone:withData:withView:)]){
            PEXInTextDataPhoneNumber * aux = (PEXInTextDataPhoneNumber *) data;
            [self.linkClickDelegate userClickedMessage:message onPhone:aux.phoneNumber withData:aux withView:self];
        }
    }
}

- (void) linkTextTTTLabel:(TTTAttributedLabel *) label
   didLongTapLinkWithData:(PEXInTextData *)data
                 withLink:(TTTAttributedLabelLink *) link
              withMessage:(const PEXMessageModel * const) message
{
    DDLogVerbose(@"long-click: data: %@, link: %@, msg: %@", data, link, message);
    if (self.linkClickDelegate == nil){
        return;
    }

    if ([self.linkClickDelegate respondsToSelector:@selector(userLongClickedMessage:withData:withView:)]) {
        [self.linkClickDelegate userLongClickedMessage:message withData:data withView:self];
    }

    if ([data isKindOfClass:[PEXInTextDataLink class]]){
        if ([self.linkClickDelegate respondsToSelector:@selector(userLongClickedMessage:onURL:withData:withView:)]){
            PEXInTextDataLink * aux = (PEXInTextDataLink *) data;
            [self.linkClickDelegate userLongClickedMessage:message onURL:aux.url withData:aux withView:self];
        }
    }

    if ([data isKindOfClass:[PEXInTextDataPhoneNumber class]]){
        if ([self.linkClickDelegate respondsToSelector:@selector(userLongClickedMessage:onPhone:withData:withView:)]){
            PEXInTextDataPhoneNumber * aux = (PEXInTextDataPhoneNumber *) data;
            [self.linkClickDelegate userLongClickedMessage:message onPhone:aux.phoneNumber withData:aux withView:self];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([self.TV_body containslinkAtPoint:[touch locationInView:self.TV_body]])
        return FALSE;
    else
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}

- (void)setLongClickAction:(dispatch_block_t)action {
    [super setLongClickAction:action];

    // Text data recognizer need to take precedence.
    if (self.longClickRecognizer != nil){
        self.longClickRecognizer.cancelsTouchesInView = YES;
        [self.longClickRecognizer requireGestureRecognizerToFail:self.TV_body.longPressGestureRecognizer];
    }
}

- (void)setClickAction:(dispatch_block_t)action {
    [super setClickAction:action];

    // Text data recognizer need to take precedence.
    if (self.clickRecognizer != nil){
        self.clickRecognizer.cancelsTouchesInView = YES;
        [self.clickRecognizer requireGestureRecognizerToFail:self.TV_body.longPressGestureRecognizer];
    }
}

@end
