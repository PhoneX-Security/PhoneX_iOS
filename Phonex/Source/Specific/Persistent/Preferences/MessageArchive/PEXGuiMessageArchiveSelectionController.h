//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiMessageArchiveSelectionController : PEXGuiController

- (NSNumber *) getSelectedValue;
+ (NSString *)getTriggerTimeDescriptionFromSeconds: (NSNumber * const)seconds;

@end