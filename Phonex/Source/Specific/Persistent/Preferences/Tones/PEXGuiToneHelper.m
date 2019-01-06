//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiToneHelper.h"
#import "PEXResSounds.h"
#import "PEXGuiTone.h"

@interface PEXGuiToneHelper () {}
@property (nonatomic) NSMutableArray * ringTones;
@property (nonatomic) NSMutableArray * notification;
@property (nonatomic) NSMutableDictionary * toneMap;
@end

@implementation PEXGuiToneHelper {

}

+ (PEXGuiToneHelper *) instance
{
    static PEXGuiToneHelper * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiToneHelper alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ringTones = [[NSMutableArray alloc] init];
        self.notification = [[NSMutableArray alloc] init];
        self.toneMap = [[NSMutableDictionary alloc] init];

        [self loadNotifications];
        [self loadRingTones];
    }

    return self;
}

- (void) loadRingTones {
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Original" toneId:PEX_RINGTONE_ORIGINAL]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Ball" toneId:PEX_RINGTONE_BALL]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Ringtone 1" toneId:PEX_RINGTONE_1]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Ringtone 2" toneId:PEX_RINGTONE_2]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Decent" toneId:PEX_RINGTONE_ST]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Epic" toneId:PEX_RINGTONE_EPIC]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Chimming" toneId:PEX_RINGTONE_CHIMMING]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Simple" toneId:PEX_RINGTONE_SIMPLE]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"Guitar" toneId:PEX_RINGTONE_GUITAR]];
    [self.ringTones addObject:[PEXGuiTone toneWithToneName:@"System remix" toneId:PEX_RINGTONE_IPHONE6_DUBSTEP]];

    for(PEXGuiTone * tone in self.ringTones){
        if (tone.toneId){
            self.toneMap[tone.toneId] = tone;
        }
    }
}

- (void) loadNotifications {
    [self.notification addObject:[PEXGuiTone toneWithToneName:@"System" systemCode:1007]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Ding 1" toneId:PEX_NOTIFICATION_DING2] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Ding 2" toneId:PEX_NOTIFICATION_CORRECT] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Notification" toneId:PEX_NOTIFICATION_NOTIF] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Waterdrop" toneId:PEX_NOTIFICATION_WATERDROP] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Bum" toneId:PEX_NOTIFICATION_BUM] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Complete" toneId:PEX_NOTIFICATION_COMPLETED] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Pop" toneId:PEX_NOTIFICATION_POP] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Electro" toneId:PEX_NOTIFICATION_ELECTRO] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Dingaling" toneId:PEX_NOTIFICATION_DINGALING] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Jingle" toneId:PEX_NOTIFICATION_JINGLE] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Vibration" toneId:PEX_NOTIFICATION_VIBRATION] setFShouldVibrate:YES]];
    [self.notification addObject:[[PEXGuiTone toneWithToneName:@"Silent" toneId:PEX_NOTIFICATION_SILENT] setFIsSilent:YES]];

    for(PEXGuiTone * tone in self.notification){
        if (tone.toneId){
            self.toneMap[tone.toneId] = tone;
        }
    }
}

+ (NSArray *) getRingtones {
    PEXGuiToneHelper * helper = [self instance];
    return [NSArray arrayWithArray:helper.ringTones];
}

+ (NSArray *) getNotifications {
    PEXGuiToneHelper * helper = [self instance];
    return [NSArray arrayWithArray:helper.notification];
}

+ (PEXGuiTone *)getToneById:(NSString *)toneId {
    PEXGuiToneHelper * helper = [self instance];
    return helper.toneMap[toneId];
}

+ (PEXGuiTone *)getNotificationToneById:(NSString *)toneId {
    PEXGuiToneHelper * helper = [self instance];
    PEXGuiTone * toReturn = toneId == nil ? nil : helper.toneMap[toneId];
    return toReturn == nil ? helper.notification[0] : toReturn;
}

+ (PEXGuiTone *)getRingToneById:(NSString *)toneId {
    PEXGuiToneHelper * helper = [self instance];
    PEXGuiTone * toReturn = toneId == nil ? nil : helper.toneMap[toneId];
    return toReturn == nil ? helper.ringTones[0] : toReturn;
}


@end