//
// Created by Dusan Klinec on 31.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjToneZrtpOk.h"


@implementation PEXPjToneZrtpOk {

}
- (unsigned int)tone_cnt {
    return 2;
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    tone[0].freq1 = 800;
    tone[0].freq2 = 0;
    tone[0].on_msec = 100;
    tone[0].off_msec = 100;

    tone[1].freq1 = 800;
    tone[1].freq2 = 0;
    tone[1].on_msec = 100;
    tone[1].off_msec = 100;
}

- (NSString *)tone_name {
    return @"zrtpToneOK";
}

- (BOOL)tone_isLoop {
    return NO;
}

@end