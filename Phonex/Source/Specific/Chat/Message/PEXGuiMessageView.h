//
// Created by Matej Oravec on 19/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiClickableView.h"

#import "PEXDbMessage.h"

#import "PEXMessageStatus.h"
#import "PEXGuiStaticDimmer.h"

@class PEXMessageModel;
@class PEXInTextData;
@class PEXInTextDataLink;
@class PEXInTextDataPhoneNumber;
@protocol PEXMessageClickDelegate;

@interface PEXGuiMessageView : PEXGuiClickableView<PEXGuiStaticDimmer, UIGestureRecognizerDelegate>
/**
 * Working queue to perform additional operations, e.g., data detection in messages.
 */
@property(nonatomic) NSOperationQueue * workQueue;
@property(nonatomic) id<PEXMessageClickDelegate> linkClickDelegate;

- (void) setLongClickAction: (dispatch_block_t) action;
- (void) setClickAction: (dispatch_block_t) action;
- (void) setContextMenuAction: (dispatch_block_t) action;
- (void) invokeClickAction;

- (void) initGuiStuff;

- (void) setOutgoing;
- (void) setIncomming;

- (void) setMessage: (const PEXMessageModel * const) message;
- (void) clearMessage;

- (void) setSeen: (NSDate *) date;

- (void) prepareForReuse;

+ (bool) message: (const PEXDbMessage * const) m1
     needsUpdate: (const PEXDbMessage * const) m2;

+ (void) updateMessage: (const PEXDbMessage * const) m1
                  with: (const PEXDbMessage * const) m2;

+ (const PEXMessageStatus *) getStatusFromMessage: (const PEXDbMessage *const) message
                                      describeAll: (const bool) showAll;

@end

/**
 The `PEXMessageClickDelegate` protocol defines the messages sent to an attributed label delegate when links are tapped.
 All of the methods of this protocol are optional.
 */
@protocol PEXMessageClickDelegate <NSObject>

///-----------------------------------
/// @name Responding to Link Selection
///-----------------------------------
@optional

/**
 Tells the delegate that the user did select a link to a URL.

 @param label The label whose link was selected.
 @param url The URL for the selected link.
 */
- (void)userClickedMessage:(const PEXMessageModel * const) message
                    withData:(PEXInTextData *) data
                  withView:(PEXGuiMessageView *) messageView;

- (void)userClickedMessage:(const PEXMessageModel * const) message
                     onURL:(NSURL*) url
                  withData:(PEXInTextDataLink *) data
                  withView:(PEXGuiMessageView *) messageView;

- (void)userClickedMessage:(const PEXMessageModel * const) message
                   onPhone:(NSString*) phone
                  withData:(PEXInTextDataPhoneNumber *) data
                  withView:(PEXGuiMessageView *) messageView;


///---------------------------------
/// @name Responding to Long Presses
///---------------------------------

- (void)userLongClickedMessage:(const PEXMessageModel * const) message
                      withData:(PEXInTextData *) data
                      withView:(PEXGuiMessageView *) messageView;

- (void)userLongClickedMessage:(const PEXMessageModel * const) message
                         onURL:(NSURL*) url
                      withData:(PEXInTextDataLink *) data
                      withView:(PEXGuiMessageView *) messageView;

- (void)userLongClickedMessage:(const PEXMessageModel * const) message
                       onPhone:(NSString*) phone
                      withData:(PEXInTextDataPhoneNumber *) data
                      withView:(PEXGuiMessageView *) messageView;

@end