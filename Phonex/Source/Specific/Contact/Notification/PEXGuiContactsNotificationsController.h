//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiContentLoaderController.h"
#import "PEXContactNotificationManager.h"


@interface PEXGuiContactsNotificationsController : PEXGuiContentLoaderController
        <PEXContactNotificationListener,
        UICollectionViewDelegate,
        UICollectionViewDataSource>


@end