//
//  PEXGuiFactory.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiDialogUnaryVisitor.h"

@protocol PEXBinarySimpleListener;
@protocol PEXGuiDialogUnaryListener;
@class PEXGuiController;

@interface PEXGuiFactory : NSObject

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
            withText: (NSString * const) text;


+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                          withText: (NSString * const) text
                        completion: (void (^)(void))completion;

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                              text: (NSString * const) text
                             title: (NSString * const) title;

+ (PEXGuiController *) showTextBox: (UIViewController * const) parent
                              text: (NSString * const) text
                             title: (NSString * const) title
                        completion: (void (^)(void))completion;

+ (PEXGuiController *) showRestartAppChallenge: (UIViewController * const) parent;

+ (PEXGuiController *) showInfoTextBox: (UIViewController * const) parent
                               withText: (NSString * const) text;

+ (PEXGuiController *) showInfoTextBox: (UIViewController * const) parent
                              withText: (NSString * const) text
                            completion: (void (^)(void))completion;

+ (PEXGuiController *) showErrorTextBox: (UIViewController * const) parent
                               withText: (NSString * const) text
                             completion: (void (^)(void))completion;

+ (PEXGuiController *) showErrorTextBox: (UIViewController * const) parent
                 withText: (NSString * const) text;

+ (PEXGuiController *) showWarningTextBox: (UIViewController * const) parent
                   withText: (NSString * const) text;

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const)parent
                              withText:(NSString *const)text
                              listener:(id <PEXGuiDialogBinaryListener>)listener
                         primaryAction:(NSString *const)primaryName
                       secondaryAction:(NSString * const) secondaryName;

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const)parent
                    withAttributedText:(NSAttributedString *const)text
                              listener:(id <PEXGuiDialogBinaryListener>)listener
                         primaryAction:(NSString *const)primaryName
                       secondaryAction:(NSString * const) secondaryName;

+ (PEXGuiController *)showBinaryDialog:(UIViewController *const) parent
                              withText:(NSString *const) text
                     primaryActionName:(NSString *const) primaryName
                   secondaryActionName:(NSString *const) secondaryName
                         primaryAction:(PEXDialogActionListenerBlock) primaryAction
                       secondaryAction:(PEXDialogActionListenerBlock) secondaryAction;

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                              withText:(NSString *const)text
                              listener:(id <PEXGuiDialogBinaryListener>)listener
                         primaryAction:(NSString *const)primaryName;

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                   withAttributedText:(NSAttributedString *const)attributedstring
                             listener:(id <PEXGuiDialogBinaryListener>)listener
                        primaryAction:(NSString *const)primaryName;

+ (PEXGuiController *)showUnaryDialog:(UIViewController *const)parent
                             withText:(NSString *const)text
                    primaryActionName:(NSString *const)primaryName
                        primaryAction:(PEXDialogActionListenerBlock) primaryAction;

@end
