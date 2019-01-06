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

#import "PEXGuiBackgroundView.h"

#import "PEXGuiNavigationController.h"
#import "PEXGuiCanvasView.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiDialogUnaryVisitor.h"
#import "PEXGuiDialogUnaryListener.h"
#import "PEXGuiDialogBinaryListener.h"
#import "PEXGuiDialogBinaryVisitor.h"

#import "PEXUnmanagedObjectHolder.h"

#import "PEXGuiKeyboardHolder.h"
#import "PEXMessageManager.h"

#import "PEXGuiDialogCloser.h"
#import "PEXReport.h"
#import "UIViewController+PEXRelayout.h"


@interface PEXGuiController ()
{
    @private
    CGFloat _movedByKeyboard;
    bool _hideKeyboardWasCalledBeforeEndEditing;
}
@property (nonatomic, assign) CGFloat activeEditingViewOriginalAbsoluteBottom;
@property (nonatomic, weak) UIView * activeEditingView;
@property (nonatomic, weak) UIView * hightestOfViews;

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
        2bc. initState
 **/

- (PEXGuiController *) showInNavigation: (UIViewController * const) parent title: (NSString * const) title
{
    PEXGuiNavigationController * a = [[PEXGuiAppNavigationController alloc]
                                      initWithViewController:self
                                      title:title];

    [a prepareOnScreen:parent];
    [a show:parent];

    return a;
}

- (PEXGuiController *) showInWindow: (UIViewController * const) parent
{
    PEXGuiWindowController * a = [[PEXGuiWindowController alloc]
            initWithViewController:self];

    [a prepareOnScreen:parent];
    [a show:parent];
    return a;
}

- (PEXGuiController *) showInWindow: (UIViewController * const) parent
                                       withTitle: (NSString * const) title;
{

    PEXGuiLabelController * a = [[PEXGuiLabelController alloc]
                                 initWithViewController:self
                                 title:title];

    return [a showInWindow:parent];
}

- (PEXGuiController *) showInWindow: (UIViewController * const) parent
                                       title: (NSString * const) title
             withUnaryListener: (id<PEXGuiDialogUnaryListener>) listener
{
    PEXGuiDialogUnaryVisitor * const visitor = [[PEXGuiDialogUnaryVisitor alloc] initWithDialogSubcontroller:self
                                                                                                      listener:listener];
    PEXGuiController * const dialog = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    return [dialog showInWindow:parent withTitle:title];
}

- (PEXGuiController *) showInClosingWindow: (UIViewController * const) parent
                              title: (NSString * const) title
                  withUnaryListener: (id<PEXGuiDialogUnaryListener>) listener
{
    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithDialogSubcontroller:self
                                                                                                    listener:listener];
    PEXGuiController * const dialog = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    PEXGuiController * const result = (title ? [dialog showInWindow:parent withTitle:title] : [dialog showInWindow:parent]);
    visitor.finishPrimaryBlock = ^{[result dismissViewControllerAnimated:true completion:nil];};

    return result;
}

- (PEXGuiController *) showInWindowWithTitle: (UIViewController * const) parent
                                       title: (NSString * const) title
             withBinaryListener: (id<PEXGuiDialogBinaryListener>) listener
{
    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiDialogBinaryVisitor alloc] initWithDialogSubcontroller:self
                                                                                                    listener:listener];
    PEXGuiController * const dialog = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];


    return [dialog showInWindow:parent withTitle:title];
}

- (PEXGuiController *) showInLabel: (UIViewController * const) parent
                             title: (NSString * const) title
{
    return [self showInLabel:parent title:title animated:true];
}

- (PEXGuiController *) showInLabel: (UIViewController * const) parent
                             title: (NSString * const) title
                          animated: (const bool) animated
{
    PEXGuiLabelController * a = [[PEXGuiLabelController alloc]
            initWithViewController:self
                             title:title];

    [a prepareOnScreen:parent];
    [a show:parent animated:animated];
    return a;
}

- (void) prepareOnScreen: (PEXGuiController * const) parent
{
    self.fullscreener = self;

    [self initMasterViewOnScreen];
    [self postInit];
    [self recalculateOnScreen: parent];
    [self initState];
}

- (void) prepareInView: (PEXGuiControllerDecorator * const) parent
{

    self.fullscreener = ([[parent class] isSubclassOfClass:[PEXGuiController class]] ? parent.fullscreener : parent);

    [self initMasterViewInView];
    [self postInit];
    [self recalculateInView:parent];
    [self initState];
}

- (void) show:(UIViewController * const) parent
{
    [self show:parent transitionStyle:UIModalTransitionStyleCoverVertical parentStyle:UIModalPresentationNone animated:true];
}

- (void) show:(UIViewController * const) parent animated: (const bool) animated
{
    [self show:parent transitionStyle:UIModalTransitionStyleCoverVertical parentStyle:UIModalPresentationNone animated:animated];
}

- (void) show:(UIViewController * const) parent animated: (const bool) animated completion: (dispatch_block_t) completion
{
    [self show:parent
            transitionStyle:UIModalTransitionStyleCoverVertical
            parentStyle:UIModalPresentationNone
            animated:animated
            completion:completion
    ];
}

// REMEMBER TO ADD TO LANDING
- (void) show:(UIViewController * const) parent transitionStyle: (const UIModalTransitionStyle) style
  parentStyle: (const UIModalPresentationStyle) parentStyle animated: (const bool) animated
{
    //self.modalTransitionStyle = style;
    parent.modalPresentationStyle = parentStyle;
    [parent presentViewController:self animated:animated completion:nil];

    _shownByModal = true;
}

// REMEMBER TO ADD TO LANDING
- (void) show:(UIViewController * const) parent transitionStyle: (const UIModalTransitionStyle) style
  parentStyle: (const UIModalPresentationStyle) parentStyle animated: (const bool) animated completion: (dispatch_block_t) completion
{
    //self.modalTransitionStyle = style;
    parent.modalPresentationStyle = parentStyle;
    [parent presentViewController:self animated:animated completion:completion];

    _shownByModal = true;
}

- (void) postInit
{
    [self initGuiComponents];
    [self initContent];
    [self initBehavior];
}



// BEcasue the keyboard is always on top
- (void) viewWillAppear:(BOOL)animated
{
    [[PEXGuiKeyboardHolder instance] stopEditing];

    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[PEXGuiKeyboardHolder instance] stopEditing];

    [super viewWillDisappear:animated];
}

- (UIView *) getMainView
{
    return [[PEXGuiBackgroundView alloc] init];
}

- (UIView *)getBackgroundView
{
    return [[PEXGuiBackgroundView alloc] init];
}

- (void) initMasterViewOnScreen
{
    self.view = [self getBackgroundView];

    self.mainView = [self getMainView];
    [self.view addSubview:self.mainView];

    // temporary removed because of glitch
    //self.statusBarView = [self getBackgroundView];
    //[self.view addSubview:self.statusBarView];
}

- (void) initMasterViewInView
{
    self.mainView = [self getMainView];
    self.view = self.mainView;
}

- (void) initGuiComponents { /* abstract */}
- (void) initContent { /* abstract */}
- (void) initLayout { /* abstract */}
- (void) initState { /* abstract */}

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

    // temporary removed because of a glitch
    //[PEXGVU makeStatusBar:self.statusBarView];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:[parent subviewMaxHeight]];
}

// MAINTENANCE STUFF

- (void) initBehavior
{
    _isEditing = false;
    _movedByKeyboard = 0.0f;

    [self.mainView addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(backgroundTapped:)]];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    // TODO place somwewhere in styles
    return [PEXTheme getStatusBarStyle];
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (IBAction) backgroundTapped:(id)sender
{
    [_activeEditingView endEditing:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)keyboardWillShow:(NSNotification *)notification {

    CGRect start, end;
    [[notification userInfo][UIKeyboardFrameBeginUserInfoKey] getValue:&start];
    [[notification userInfo][UIKeyboardFrameEndUserInfoKey] getValue:&end];


    CGFloat diff = 0.0f;

    const CGFloat yKbTrajectory = (end.origin.y - start.origin.y);
    if (yKbTrajectory > 0.0f)
    {
        // going lower
        if (_movedByKeyboard != 0.0f)
        {
            if (_movedByKeyboard < yKbTrajectory)
            {
                // above controller's origin
                diff = yKbTrajectory;
            }
            else
            {
                // below controller's origin
                diff = _movedByKeyboard;
            }
        }
    }
    else if (yKbTrajectory < 0.0f)
    {
        // going higher
        if (_movedByKeyboard != 0.0f)
        {
            // higher than moved before above controller's origin
            diff = end.origin.y - start.origin.y;
        }
        else if (end.origin.y < self.activeEditingViewOriginalAbsoluteBottom + [self getKeyboardOffset])
        {
            // first time above controller's origin
            diff = end.origin.y - (self.activeEditingViewOriginalAbsoluteBottom + [self getKeyboardOffset]);
        }
    }

    if (diff != 0.0f)
    {
        _movedByKeyboard += diff;
        [self animateSlide:diff accordingTo:notification];
    }
}

-(CGFloat) getTopKeyboardPoint
{
    return ([PEXGVU getAbsolutePosition:self.activeEditingView highestView:nil].y +
            self.activeEditingView.frame.size.height);
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    /*
     because of IPH-85 Selecting text in chat view hides the keyboard and breaks the UI
     the sliding logic was moved to youDidEndEditing and the notification details are
     stored in keyboardNotification
     */

    [self slideToHide:notification];
}

- (void) slideToHide: (NSNotification * const)notification
{
    if ((_movedByKeyboard != 0.0f) && notification)
    {
        [self animateSlide: -_movedByKeyboard accordingTo:notification];
        _movedByKeyboard = 0.0f;
    }
}

- (void) animateSlide: (const CGFloat) y
          accordingTo: (const NSNotification * const) notification
{
    [UIView beginAnimations:PEXStdKeyboardAnimation context:nil];
    [UIView setAnimationDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey]
                                  doubleValue]];
    [UIView setAnimationCurve:(UIViewAnimationCurve) [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [PEXGVU moveVertically:

     ([[self.fullscreener class] isSubclassOfClass:[PEXGuiController class]] ? ((PEXGuiController*) self.fullscreener).mainView : self.fullscreener.view)
     by:y];

    [UIView commitAnimations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[PEXGuiKeyboardHolder instance] stopEditing];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self youShouldBeginEditing: textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self youDidEndEditing];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self youShouldBeginEditing: textView];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self youDidEndEditing];
}

- (void) youShouldBeginEditing: (UIView * const) view
{
    _isEditing = true;

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

    // TODO problem, when someone will try to show the keyboard during ending eidting
    // requires redesign
    [[PEXGuiKeyboardHolder instance] setCurrent:self];

    _activeEditingView = view;
    self.activeEditingViewOriginalAbsoluteBottom = [self getTopKeyboardPoint];
}

- (void) youDidEndEditing
{
    [[NSNotificationCenter defaultCenter]
    removeObserver:self
    name:UIKeyboardWillShowNotification
    object:nil];

    [[NSNotificationCenter defaultCenter]
    removeObserver:self
    name:UIKeyboardWillHideNotification
    object:nil];

    [[PEXGuiKeyboardHolder instance] setCurrent:nil];

    _activeEditingView = nil;
    _hightestOfViews = nil;

    _isEditing = false;
}

- (CGFloat) getKeyboardOffset
{
    return 0.0f;
}

- (void) addSelfAsChildIfNotAdded: (PEXGuiController * const) parent
{
    if (!self.parentViewController)
    {
        [parent addChildViewController:self];
    }

    if (!self.view.superview)
    {
            if (self.fullscreener == self)
                [parent.view addSubview:self.view];
            else
            {
                if ([[parent class] isSubclassOfClass:[PEXGuiController class]])
                    [parent.mainView addSubview:self.view];
                else
                    [parent.view addSubview:self.view];
            }
    }

    [parent.view bringSubviewToFront:self.view];
}

// DISMISS CONTROLLER

- (void) dismissWithCompletion:(void (^)(void)) completion
                     animation: (void (^)(void)) animation
{
    [UIView animateWithDuration:PEXVal(@"dur_short")
                     animations:animation
                     completion:^(BOOL finished){
                         [self dismissInternViewControllerAnimated:false completion:completion];
                     }];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismissInternViewControllerAnimated:flag completion:completion];
}

- (void)dismissInternViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // was shown by showModal
    if (/*self.isBeingPresented*/ _shownByModal)
    {
        [super dismissViewControllerAnimated:true // force true
                                  completion:^{
                                      [self dismissCompletion:completion];
                                  }];
    }
    else
    {
        [self dismissCompletion:completion];
    }

    // many executors' lives are hold by the controller they show
    [PEXUnmanagedObjectHolder removeActiveObjectForKey:self];
}

- (void) dismissCompletion:(void (^)(void))completion
{
    for (UIViewController * const child in self.childViewControllers)
        [child dismissViewControllerAnimated:false completion:nil];

    if (completion)
        completion();
    if (self.completionEx)
        self.completionEx();

    [self.view removeFromSuperview];

    // Bottom screen is set as shown when upper view is dismissed.
    if ([self.parentViewController isKindOfClass:[PEXGuiController class]])
    {
        [((PEXGuiController *)self.parentViewController) viewDidReveal];
    }

    [self removeFromParentViewController];
}

- (void) viewDidReveal {
    [PEXReport logScreenName:self.screenName];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)relayout {
    UIViewController * ctl = self.parentViewController;
    DDLogVerbose(@"Would like to relayout %@ parent: %@", self, ctl);
    return YES;
}

- (BOOL)relayoutHierarchy {
    UIViewController * ctl = self.parentViewController;

    BOOL relayouted = NO;
    if (ctl != nil && [ctl respondsToSelector:@selector(relayoutHierarchy)]){
        relayouted = [ctl relayoutHierarchy];
    }

    if (!relayouted){
        [self relayout];
    }

    return YES;
}

- (void) reloadOnScreen: (PEXGuiController * const) parent
{
    self.fullscreener = self;

    // Remove from superview, so it is re-added in the logic later in addSelfAsChildIfNotAdded.
    // Another option is to use existing view, but it needs to be cleared.
    if (self.view.superview && self.view) {
        [self.view removeFromSuperview];
    }

    [self initMasterViewOnScreen];
    [self postInit];
    [self recalculateOnScreen: parent];
    [self initState];
}

- (void) reloadInView: (PEXGuiControllerDecorator * const) parent
{
    self.fullscreener = ([[parent class] isSubclassOfClass:[PEXGuiController class]] ? parent.fullscreener : parent);

    // Remove from superview, so it is re-added in the logic later in addSelfAsChildIfNotAdded.
    // Another option is to use existing view, but it needs to be cleared.
    if (self.view.superview && self.view) {
        [self.view removeFromSuperview];
    }

    [self initMasterViewInView];
    [self postInit];
    [self recalculateInView:parent];
    [self initState];
}

@end
