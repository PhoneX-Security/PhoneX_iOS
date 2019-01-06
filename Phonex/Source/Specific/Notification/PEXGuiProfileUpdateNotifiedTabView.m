//
// Created by Matej Oravec on 11/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiProfileUpdateNotifiedTabView.h"


@implementation PEXGuiProfileUpdateNotifiedTabView {

}

- (void) registerCounter
{
    [[PEXGNFC instance] registerToLicenceUpdateAndSet:self.counter];
    [[PEXGNFC instance] registerToRecoveryMailNotificationsAndSet:self.counter];
}

- (void) unregisterCounter
{
    [[PEXGNFC instance] unregisterForLicenceUpdate:self.counter];
    [[PEXGNFC instance] unregisterForRecoveryMailNotifications:self.counter];
}

@end