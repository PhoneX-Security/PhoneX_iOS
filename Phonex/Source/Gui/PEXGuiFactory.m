//
//  PEXGuiFactory.m
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiFactory.h"

#import "PEXGuiTextController.h"
#import "PEXGuiDialogCloser.h"

#import "PEXGuiDialogUnaryListener.h"
#import "PEXGuiDialogBinaryVisitor.h"
#import "PEXGuiController.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"
#import "PEXGuiDialogBinaryVisitor_Protected.h"

@implementation PEXGuiFactory

// TODO unite
+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
            withText: (NSString * const) text
{
    return [self showTextBox:parent withText:text completion:nil];
}

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                          withText: (NSString * const) text
                        completion: (void (^)(void))completion
{
    PEXGuiTextController * const txtController = [[PEXGuiTextController alloc] initWithText:text];
    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithDialogSubcontroller:txtController
                                                                                        listener:nil];
    PEXGuiController * const result =
            [[[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor] showInWindow:parent];

    visitor.finishPrimaryBlock = ^{[result dismissViewControllerAnimated:true completion:completion];};

    return result;
}

+ (PEXGuiController *) showRestartAppChallenge: (UIViewController * const) parent
{
    return [PEXGuiFactory showInfoTextBox:parent
                                 withText:
                                         [NSString stringWithFormat:@"%@\n\n%@",
                                                         PEXStr(@"txt_restart_to_apply_changes"),
                                                         PEXStr(@"txt_restart_app_detail_description")]
    ];
}

+ (PEXGuiController *) showInfoTextBox: (UIViewController * const) parent
                              withText: (NSString * const) text
                            completion: (void (^)(void))completion
{
    return [self showTextBox:parent text:text title:PEXStrU(@"title_info") completion:completion];
}

+ (PEXGuiController *) showInfoTextBox: (UIViewController * const) parent
                              withText: (NSString * const) text
{
    return [self showTextBox:parent text:text title:PEXStrU(@"title_info")];
}

+ (PEXGuiController *) showErrorTextBox: (UIViewController * const) parent
                               withText: (NSString * const) text
                             completion: (void (^)(void))completion
{
    return [self showTextBox:parent text:text title:PEXStrU(@"title_error") completion:completion];
}

+ (PEXGuiController *) showErrorTextBox: (UIViewController * const) parent
            withText: (NSString * const) text
{
    return [self showTextBox:parent text:text title:PEXStrU(@"title_error")];
}

+ (PEXGuiController *) showWarningTextBox: (UIViewController * const) parent
                 withText: (NSString * const) text
{
    return [self showTextBox:parent text:text title:PEXStrU(@"title_warning")];
}

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                              text: (NSString * const) text
                             title: (NSString * const) title
                        completion: (void (^)(void))completion
{
    PEXGuiTextController * const txtController = [[PEXGuiTextController alloc]
            initWithText:text];

    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithDialogSubcontroller:txtController
                                                                                        listener:nil];
    PEXGuiController * const unaryDialog = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    PEXGuiController * const result = [unaryDialog showInWindow:parent withTitle:title];
    visitor.finishPrimaryBlock = ^{[result dismissViewControllerAnimated:true completion:completion];};

    return result;
}

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                              text: (NSString * const) text
                             title: (NSString * const) title
{
    return [self showTextBox:parent text:text title:title completion:nil];
}

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const)parent
                              withText:(NSString *const)text
                              listener:(id <PEXGuiDialogBinaryListener>)listener
                         primaryAction:(NSString *const)primaryName
                       secondaryAction:(NSString * const) secondaryName
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:text];
    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiDialogBinaryVisitor alloc] initWithDialogSubcontroller:txt
                                                                                                      listener:listener];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    if (secondaryName)
        visitor.secondaryButtomtitle = secondaryName;

    PEXGuiController * const vc = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const)parent
                    withAttributedText:(NSAttributedString *const)text
                              listener:(id <PEXGuiDialogBinaryListener>)listener
                         primaryAction:(NSString *const)primaryName
                       secondaryAction:(NSString * const) secondaryName
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithAttributedText:text];
    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiDialogBinaryVisitor alloc] initWithDialogSubcontroller:txt
                                                                                                      listener:listener];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    if (secondaryName)
        visitor.secondaryButtomtitle = secondaryName;

    PEXGuiController * const vc = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const) parent
                              withText:(NSString *const) text
                     primaryActionName:(NSString *const) primaryName
                   secondaryActionName:(NSString *const) secondaryName
                         primaryAction:(PEXDialogActionListenerBlock) primaryAction
                       secondaryAction:(PEXDialogActionListenerBlock) secondaryAction
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:text];
    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiDialogBinaryVisitor alloc] initWithDialogSubcontroller:txt listener:nil];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    if (secondaryName)
        visitor.secondaryButtomtitle = secondaryName;

    if (primaryAction)
        visitor.onPrimaryActionClick = primaryAction;

    if (secondaryAction)
        visitor.onSecondaryActionClick = secondaryAction;

    PEXGuiController * const vc = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                             withText:(NSString *const)text
                             listener:(id <PEXGuiDialogBinaryListener>)listener
                        primaryAction:(NSString *const)primaryName
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:text];
    PEXGuiDialogUnaryVisitor * const visitor = [[PEXGuiDialogUnaryVisitor alloc] initWithDialogSubcontroller:txt
                                                                                                    listener:listener];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    PEXGuiController * const vc = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                   withAttributedText:(NSAttributedString *const)attributedstring
                             listener:(id <PEXGuiDialogBinaryListener>)listener
                        primaryAction:(NSString *const)primaryName
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithAttributedText:attributedstring];
    PEXGuiDialogUnaryVisitor * const visitor = [[PEXGuiDialogUnaryVisitor alloc] initWithDialogSubcontroller:txt
                                                                                                    listener:listener];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    PEXGuiController * const vc = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                             withText:(NSString *const)text
                    primaryActionName:(NSString *const)primaryName
                        primaryAction:(PEXDialogActionListenerBlock) primaryAction
{
    PEXGuiTextController * const txt = [[PEXGuiTextController alloc] initWithText:text];
    PEXGuiDialogUnaryVisitor * const visitor = [[PEXGuiDialogUnaryVisitor alloc] initWithDialogSubcontroller:txt listener:nil];

    if (primaryName)
        visitor.primaryButtonTitle = primaryName;

    if (primaryAction)
        visitor.onPrimaryActionClick = primaryAction;

    PEXGuiController * const vc = [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    return [vc showInWindow:parent];
}



@end
