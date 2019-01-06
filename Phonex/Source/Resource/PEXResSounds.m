//
// Created by Dusan Klinec on 10.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXResSounds.h"

NSString * PEX_RINGTONE_BALL = @"98948_ball_ringtone.mp3";
NSString * PEX_RINGTONE_1 = @"171324_ringtone.mp3";
NSString * PEX_RINGTONE_ST = @"198618_st_10.mp3";
NSString * PEX_RINGTONE_EPIC = @"235902_epicbuilduploop.mp3";
NSString * PEX_RINGTONE_CHIMMING = @"246390_chiming_out.mp3";
NSString * PEX_RINGTONE_2 = @"254822_ringtone2.mp3";
NSString * PEX_RINGTONE_SIMPLE = @"273540_simple_ringtone.mp3";
NSString * PEX_RINGTONE_ORIGINAL = @"call.mp3";
NSString * PEX_RINGTONE_GUITAR = @"guitar_iphone_5.mp3";
NSString * PEX_RINGTONE_IPHONE6_DUBSTEP = @"iphone_6_dubstep.mp3";

NSString *PEX_NOTIFICATION_DING2 = @"159011_ding2.wav";
NSString *PEX_NOTIFICATION_WATERDROP = @"191678_waterdrop.caf";
NSString *PEX_NOTIFICATION_CORRECT = @"243701_correct.wav";
NSString *PEX_NOTIFICATION_NOTIF = @"315878_notification.wav";

NSString *PEX_NOTIFICATION_BUM = @"74233_bum.wav";
NSString *PEX_NOTIFICATION_COMPLETED = @"277031_completed.caf";
NSString *PEX_NOTIFICATION_POP = @"242502_pop.wav";
NSString *PEX_NOTIFICATION_ELECTRO = @"235911_electro.caf";
NSString *PEX_NOTIFICATION_DINGALING = @"268756_dingaling.mp3";
NSString *PEX_NOTIFICATION_JINGLE = @"234524_jingle.caf";
NSString *PEX_NOTIFICATION_VIBRATION = @"vibration.caf";
NSString *PEX_NOTIFICATION_SILENT = @"silent.wav";

@implementation PEXResSounds {

}

+ (NSString *)getZrtpOkSound {
    return [[NSBundle mainBundle] pathForResource: @"zrtp_ok_beep" ofType: @"wav"];
}

+ (NSURL *)getSoundUrl:(NSString *)soundName {
    NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], soundName];
    return [NSURL fileURLWithPath:path];
}


@end