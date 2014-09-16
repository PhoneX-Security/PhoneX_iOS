//
//  PEXGuiCustomViewController.m
//  Phonex
//
//  Created by Matej Oravec on 28/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiControllerDecorator.h"

#import "PEXGuiViewUtils.h"
#import "PEXResValues.h"
#import "PEXGuiBackgroundView.h"

#define PEXStdKeyboardAnimation @"StdKeyboardAnimation"

@interface PEXGuiController ()

@property (nonatomic, weak) UITextField * activeTextField;

@end

@implementation PEXGuiController

/**
 1. init
 
 2. prepareInView / prepareOnScreen
    2a. postInit
        1aa. initMasterView
        1ab. initGuiComponents
        1ac. initContent
        1ad. initBehavior

    2b. recalculateOnScreen / recalculateInView
        
        // NOTE: There are 2 types: Parent-Maximum-Users and Content-Adaptable
        2ba. setSizeInView / makeFullscreenBackground
        2bb. initLayout
 **/

- (void) prepareOnScreen: (UIViewController * const) parent
{
    [self initMasterViewOnScreen];
    [self postInit];
    [self recalculateOnScreen: parent];
}

- (void) prepareInView: (PEXGuiControllerDecorator * const) parent
{
    [self initMasterViewInView];
    [self postInit];
    [self recalculateInView:parent];
}

- (void) show:(UIViewController * const) parent
{
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    parent.modalPresentationStyle = UIModalPresentationNone;
    [parent presentViewController:self animated:YES completion:nil];
}

- (void) postInit
{
    [self initGuiComponents];
    [self initContent];
    [self initBehavior];
}


- (UIView *) getMainView
{
    return [[PEXGuiBackgroundView alloc] init];
}

- (UIView *) getBackgroundView
{
    return [[PEXGuiBackgroundView alloc] init];
}

- (void) initMasterViewOnScreen
{
    self.mainView = [self getMainView];
    self.view = [self getBackgroundView];
    [self.view addSubview:self.mainView];
}

- (void) initMasterViewInView
{
    self.mainView = [self getMainView];
    self.view = self.mainView;
}

- (void) initGuiComponents {}
- (void) initContent {}
- (void) initLayout {}

- (void) recalculateOnScreen: (UIViewController * const) parent;
{
    [self setSizeOnScreen:parent];
    [self initLayout];
}

- (void) recalculateInView: (PEXGuiControllerDecorator * const) parent
{
    [self setSizeInView:parent];
    [self initLayout];
}

- (void) setSizeOnScreen: (UIViewController * const) parent
{
    [PEXGVU makeFullscreenBackground:self.view];
    [PEXGVU makeMainbackground:self.mainView];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:[parent subviewMaxHeight]];
}

// MAINTENANCE STUFF

- (void) initBehavior
{
    [self.mainView addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(backgroundTapped:)]];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification
     object:nil];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    // TODO place somwewhere in styles
    return UIStatusBarStyleDefault;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction) backgroundTapped:(id)sender
{
    [self.mainView endEditing:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)keyboardWillShow:(NSNotification *)notification {

    CGRect start, end;
    [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&start];
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&end];

    const CGFloat diff = (self.activeTextField.frame.origin.y + self.activeTextField.frame.size.height +
                          PEXVal(@"contentMarginSmall")) -
    (self.mainView.frame.size.height - end.size.height);

    if (diff > 0.0f)
    {
        [self animateSlide:(-diff) accordingTo:notification];
    }
}

- (void) keyboardWillHide:(NSNotification *)notification {

    [self animateSlide:0.0f accordingTo:notification];
}

- (void) animateSlide: (const CGFloat) y
          accordingTo: (const NSNotification * const) notification
{
    [UIView beginAnimations:PEXStdKeyboardAnimation context:nil];
    [UIView setAnimationDuration:[[[notification userInfo]
                                   objectForKey:UIKeyboardAnimationDurationUserInfoKey]
                                  doubleValue]];
    [UIView setAnimationCurve:[[[notification userInfo]
                                objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [PEXGVU set:self.view y:y];
    [UIView commitAnimations];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // TODO possible race condition?
    _activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // TODO possible race condition?
    _activeTextField = nil;
}

@end
