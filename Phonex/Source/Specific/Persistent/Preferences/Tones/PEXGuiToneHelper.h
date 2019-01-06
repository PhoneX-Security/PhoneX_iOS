//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiTone;


@interface PEXGuiToneHelper : NSObject
+ (PEXGuiToneHelper *) instance;
+ (NSArray *) getRingtones;
+ (NSArray *) getNotifications;
+ (PEXGuiTone *) getToneById: (NSString *) toneId;
+ (PEXGuiTone *) getRingToneById: (NSString *) toneId;
+ (PEXGuiTone *) getNotificationToneById: (NSString *) toneId;
@end