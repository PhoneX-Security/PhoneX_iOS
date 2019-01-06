//
// Created by Matej Oravec on 07/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsNotifiedTabView.h"


@implementation PEXGuiContactsNotifiedTabView {

}

- (void) registerCounter
{
    [[PEXGNFC instance] registerToContactNotificationsAndSet:self.counter];
}

- (void) unregisterCounter
{
    [[PEXGNFC instance] unregisterForContactNotifications:self.counter];
}

@end