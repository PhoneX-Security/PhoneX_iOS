//
//  PEXGuiNotificationCounterView.h
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCircleView.h"

@interface PEXGuiNotificationCounterView : PEXGuiCircleView<
        PEXGuiMessageNotificationsListener,
        PEXGuiCallLogNotificationsListener,
        PEXGuiLicenceUpdateNotificationsListener,
        PEXGuiAllNotificationsListener,
        PEXGuiContactNotificationsListener,
        PEXGuiRecoveryMailNotificationsListener>

@end
