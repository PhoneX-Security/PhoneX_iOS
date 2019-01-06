//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiSetNewPasswordExecutor.h"
#import "PEXGuiSetNewPasswordController.h"
#import "PEXGuiFactory.h"
#import "PEXPasswordListener.h"
#import "PEXGuiController.h"

#import "PEXUnmanagedObjectHolder.h"

@interface PEXGuiSetNewPasswordExecutor () {
@private NSString * _newPassword;
}

@property (nonatomic) PEXGuiController * parent;
@property (nonatomic) PEXGuiSetNewPasswordController * passwordController;
@property (nonatomic) id<PEXPasswordListener> listener;

@end

@implementation PEXGuiSetNewPasswordExecutor {

}

- (id) initWithParentController: (PEXGuiController * const)parent
                       listener: (id<PEXPasswordListener>) listener
{
    self = [super init];

    self.parent = parent;
    self.listener = listener;

    return self;
}

- (void)showGetChangePassword
{
    self.passwordController = [[PEXGuiSetNewPasswordController alloc] init];
    self.topController = [self.passwordController showInWindow:self.parent
                                             title:PEXStr(@"L_set_new_password")
                                 withUnaryListener:self];
    [super show];
}

- (void)primaryButtonClicked
{
    // USER self.passwordController setErrorText: to set error text

    // the user clicked OK
    // TODO for Matej if no, then show something ... message or something like that

    // TODO currently a log will be sufficient
    // TODO check if the password is OK or not
    _newPassword = nil;
    NSString * const newPass = [self.passwordController getNewPassword];
    NSString * const newRepeatedPass = [self.passwordController getRepeatedNewPassword];

    // Check for match.
    if (newPass==nil || newRepeatedPass==nil || ![newPass isEqualToString:newRepeatedPass]){
        DDLogWarn(@"Password does not match");
        [self.passwordController setErrorText:PEXStr(@"login_msg_err_pass_does_not_match")];
        return;
    }

    // Password too short?
    if ([newPass length]<8){
        DDLogWarn(@"Password is too short");
        [self.passwordController setErrorText:PEXStr(@"login_msg_err_pass_too_short")];
        return;
    }

    // Everything OK?
    _newPassword = [newPass copy];
    [self dismissDialogAndNotify];
}

- (void) dismissDialogAndNotify
{
    [self dismissWithCompletion:^{[self.listener passwordSet:_newPassword];}];
}


@end