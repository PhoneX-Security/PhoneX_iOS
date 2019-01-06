//
// Created by Dusan Klinec on 10.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * PEX_RINGTONE_BALL;
extern NSString * PEX_RINGTONE_1;
extern NSString * PEX_RINGTONE_ST;
extern NSString * PEX_RINGTONE_EPIC;
extern NSString * PEX_RINGTONE_CHIMMING;
extern NSString * PEX_RINGTONE_2;
extern NSString * PEX_RINGTONE_SIMPLE;
extern NSString * PEX_RINGTONE_ORIGINAL;
extern NSString * PEX_RINGTONE_GUITAR;
extern NSString * PEX_RINGTONE_IPHONE6_DUBSTEP;

extern NSString *PEX_NOTIFICATION_DING2;
extern NSString *PEX_NOTIFICATION_WATERDROP;
extern NSString *PEX_NOTIFICATION_CORRECT;
extern NSString *PEX_NOTIFICATION_NOTIF;

extern NSString *PEX_NOTIFICATION_BUM;
extern NSString *PEX_NOTIFICATION_COMPLETED;
extern NSString *PEX_NOTIFICATION_POP;
extern NSString *PEX_NOTIFICATION_ELECTRO;
extern NSString *PEX_NOTIFICATION_DINGALING;
extern NSString *PEX_NOTIFICATION_JINGLE;
extern NSString *PEX_NOTIFICATION_VIBRATION;
extern NSString *PEX_NOTIFICATION_SILENT;

@interface PEXResSounds : NSObject
+(NSString *) getZrtpOkSound;
+(NSURL *) getSoundUrl: (NSString *) soundName;
@end