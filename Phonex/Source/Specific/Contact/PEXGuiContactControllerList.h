//
//  PEXGuiContactControllerList.h
//  Phonex
//
//  Created by Matej Oravec on 18/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsController.h"
#import "PEXContactNotificationManager.h"

@interface PEXGuiContactControllerList :
        PEXGuiContactsController<PEXContactNotificationListener, PEXGuiContactNotificationsListener>

@end
