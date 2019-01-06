//
//  PEXGuiProfileController.h
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"
#import "PEXLicenceManager.h"

@interface PEXGuiProfileController : PEXGuiController<
        PEXLicenceListener,
        PEXGuiLicenceUpdateNotificationsListener,
        PEXGuiRecoveryMailNotificationsListener>

@end
