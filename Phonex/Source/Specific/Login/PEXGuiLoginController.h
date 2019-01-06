//
//  PEXViewController.h
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiController.h"

#import "PEXTaskListener.h"

#import "PEXLoginTaskResultDescription.h"

#import "PEXGuiCheckBox.h"
#import "PEXCreateAccountExecutor.h"

@class PEXGuiLoginController;
@class PEXCredentials;

@interface PEXGuiLoginController : PEXGuiController<PEXNewAccountCreatedListener, UITextViewDelegate>

// TODO move to some stack manager
@property (nonatomic) UIViewController * landingController;
@property (nonatomic, assign) bool preserveCredentials;

/*
 - (void) addLandingController: (UIViewController * const) controller;
 - (void) popLandingController;
 */

- (void) showBusier;
- (void) hideBusier;

+ (PEXGuiLoginController *) instance;
- (void) cleanTracesForce;
- (void) cleanTraces;

- (void) performLogout;
- (void) performLogoutWithMessage: (NSString * const) message;
- (void) performLogoutWithAftermath: (void (^)(void)) afterLogoutBlock;
- (void)performLogoutWithAftermath: (void (^)(void)) afterLogoutBlock
             willLoginImmediatelly: (const bool) willLoginImmediatelly;

- (void) startLoggingIn: (const PEXCredentials * const) credentials;

- (void) autoLoginFailedWithCredentials: (const PEXCredentials * const) credentials;

- (void) setPostLaunchShield;
- (void) removePostLaunchShield;

- (void) autologinFailedStateOff;
- (void) recoveryCodePassed: (NSString *) code;
- (void)storeCredentialsAfterPasswordChange: (const PEXCredentials * const) credentials;
@end
