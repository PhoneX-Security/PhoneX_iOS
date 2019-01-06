//
// Created by Dusan Klinec on 10.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjToneError.h"
#import "PEXPjManager.h"

@implementation PEXPjToneError {

}

- (unsigned int)tone_cnt {
    return 1;
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    tone[0].freq1 = 425;
    tone[0].freq2 = 0;
    tone[0].on_msec = 250;
    tone[0].off_msec = 250;
}

- (NSString *)tone_name {
    return @"errorTone";
}

- (void)on_call_state:(pjsua_call_id)call_id
                event:(pjsip_event *)e
            call_info: (pjsua_call_info * ) call_info
        call_session: (PEXPjCall *) call_session
{
    pjsua_call_info tmp_call_info;
    if (call_info == NULL){
        pjsua_call_get_info(call_id, &tmp_call_info);
        call_info = &tmp_call_info;
    }

    int call_status_cat = call_info->last_status / 100;
    if (e->type == PJSIP_EVENT_TSX_STATE
            && call_info->last_status != PJSIP_SC_BUSY_HERE
            && call_info->last_status != PJSIP_SC_BUSY_EVERYWHERE
            && call_info->last_status != PJSIP_SC_DECLINE
            && call_info->last_status != PJSIP_SC_GONE
            && call_info->last_status != PJSIP_SC_REQUEST_TERMINATED
            && (call_status_cat == 4 || call_status_cat == 5 || call_status_cat == 6))
    {
        [self tone_start:call_id];

        // Schedule tone shutdown to 3 seconds after.
        [self tone_schedule_stop:3500];
    }

}

@end