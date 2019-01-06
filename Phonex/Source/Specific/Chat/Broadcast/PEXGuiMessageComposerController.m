//
//  PEXGuiMessageComposerControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageComposerController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiMessageTextComposerView.h"

@interface PEXGuiMessageComposerController ()

@property (nonatomic) PEXGuiMessageTextComposerView * composerView;

@property (nonatomic) NSNotification * keyboardNotification;

@end

@implementation PEXGuiMessageComposerController

- (void) warningFlash
{
    [self.composerView warningFlash];
}

- (NSString *) getComposedText
{
    return self.composerView.text;
}

- (void) setComposedText: (NSString * const) text
{
    self.composerView.text = text;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"MessageComposer";

    self.composerView = [[PEXGuiMessageTextComposerView alloc] init];
    [self.mainView addSubview:self.composerView];
}

- (void) initContent
{
    [super initContent];

    self.composerView.placeholder = PEXStr(@"txt_message_placeholder");
}

- (void) initBehavior
{
    [super initBehavior];

    [self.composerView setDelegate:self];
}

- (void) keyboard
{
    if (_isEditing)
        [self.composerView resignFirstResponder];
    else
        [self.composerView becomeFirstResponder];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull: self.composerView];
}

- (void) initState
{
    [super initState];

    [self.composerView becomeFirstResponder];
}

// TODO research the animation behavior so as no to duplicate the animation code
// casue: it did not work properly
- (void) animateSlide: (const CGFloat) y
          accordingTo: (const NSNotification * const) notification
{
    [UIView beginAnimations:PEXStdKeyboardAnimation context:nil];
    [UIView setAnimationDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey]
                                  doubleValue]];
    [UIView setAnimationCurve:(UIViewAnimationCurve) [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [PEXGVU setHeight:self.composerView to:self.composerView.frame.size.height + y];

    [UIView commitAnimations];
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    /*
     because of IPH-85 Selecting text in chat view hides the keyboard and breaks the UI
     the sliding logic was moved to youDidEndEditing and the notification details are
     stored in keyboardNotification
     */

    self.keyboardNotification = notification;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardNotification = notification;

    [super keyboardWillShow: notification];
}

- (void)youDidEndEditing
{
    [self slideToHide:self.keyboardNotification];

    [super youDidEndEditing];
}

@end
