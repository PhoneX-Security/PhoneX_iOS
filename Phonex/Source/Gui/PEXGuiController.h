//
//  PEXGuiCustomViewController.h
//  Phonex
//
//  Created by Matej Oravec on 28/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiTrackingController.h"

@class PEXGuiControllerDecorator;
@protocol PEXGuiDialogUnaryListener;
@protocol PEXGuiDialogBinaryListener;

@interface PEXGuiController : PEXGuiTrackingController<UITextFieldDelegate, UITextViewDelegate>
{
    @protected
    bool _isEditing;
}

- (UIViewController *) fullscreener;

@property (nonatomic, copy) void (^completionEx)(void);

- (PEXGuiController *) showInNavigation: (UIViewController * const) parent title: (NSString * const) title;
- (PEXGuiController *) showInWindow: (UIViewController * const) parent;
- (PEXGuiController *) showInWindow: (UIViewController * const) parent
                                       withTitle: (NSString * const) title;
- (PEXGuiController *) showInLabel: (UIViewController * const) parent title: (NSString * const) title;
- (PEXGuiController *) showInLabel: (UIViewController * const) parent
                             title: (NSString * const) title
                          animated: (const bool) animated;

- (PEXGuiController *) showInWindow: (UIViewController * const) parent
                              title: (NSString * const) title
                  withUnaryListener: (id<PEXGuiDialogUnaryListener>) listener;

- (PEXGuiController *) showInClosingWindow: (UIViewController * const) parent
                                     title: (NSString * const) title
                         withUnaryListener: (id<PEXGuiDialogUnaryListener>) listener;

- (PEXGuiController *) showInWindowWithTitle: (UIViewController * const) parent title: (NSString * const) title
            withBinaryListener: (id<PEXGuiDialogBinaryListener>) listener;

- (void) prepareOnScreen: (PEXGuiController * const) parent;
- (void) prepareInView: (PEXGuiControllerDecorator * const) parent;

- (void) show:(UIViewController * const) parent;
- (void) show:(UIViewController * const) parent animated: (const bool) animated;
- (void) show:(UIViewController * const) parent animated: (const bool) animated completion: (dispatch_block_t) completion;
- (void) show:(UIViewController * const) parent transitionStyle: (const UIModalTransitionStyle) style
  parentStyle: (const UIModalPresentationStyle) parentStyle animated: (const bool) animated;
- (void) show:(UIViewController * const) parent transitionStyle: (const UIModalTransitionStyle) style
  parentStyle: (const UIModalPresentationStyle) parentStyle animated: (const bool) animated completion: (dispatch_block_t) completion;

- (void) dismissWithCompletion:(void (^)(void)) completion
                     animation: (void (^)(void)) animation;

- (void) addSelfAsChildIfNotAdded: (UIViewController * const) parent;
- (void) viewDidReveal;

- (void) reloadOnScreen: (PEXGuiController * const) parent;
- (void) reloadInView: (PEXGuiControllerDecorator * const) parent;
@end
