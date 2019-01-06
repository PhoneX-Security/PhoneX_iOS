//
// Created by Dusan Klinec on 31.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjToneBye.h"
#import "PEXPjCall.h"
#import "PEXPjManager.h"


@implementation PEXPjToneBye {

}


- (unsigned int)tone_cnt {
    return 3;
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    tone[0].freq1 = 800;
    tone[0].freq2 = 0;
    tone[0].on_msec = 100;
    tone[0].off_msec = 100;

    tone[1].freq1 = 600;
    tone[1].freq2 = 0;
    tone[1].on_msec = 150;
    tone[1].off_msec = 150;

    tone[2].freq1 = 0;
    tone[2].freq2 = 0;
    tone[2].on_msec = 1000;
    tone[2].off_msec = 1000;
}

- (NSString *)tone_name {
    return @"byeTone";
}

- (BOOL)tone_isLoop {
    return NO;
}

- (unsigned long)tone_duration {
    return 550ul;
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

    const BOOL disconnected = call_info->state == PJSIP_INV_STATE_DISCONNECTED;

    const BOOL disconnected_busy = call_info->state == PJSIP_INV_STATE_DISCONNECTED
            && e->type == PJSIP_EVENT_TSX_STATE
            && call_info->role == PJSIP_ROLE_UAC
            && (call_info->last_status == PJSIP_SC_BUSY_HERE
            || call_info->last_status == PJSIP_SC_BUSY_EVERYWHERE
            || call_info->last_status == PJSIP_SC_DECLINE
            || call_info->last_status == PJSIP_SC_GONE);

    const BOOL disconnected_gsm_busy = call_info->state == PJSIP_INV_STATE_DISCONNECTED
            && e->type == PJSIP_EVENT_TSX_STATE
            && call_info->role == PJSIP_ROLE_UAC
            && (call_info->last_status == PJSIP_SC_GSM_BUSY
            || (call_session != nil
            && call_session.byeCauseCode != nil
            && [@(PJSIP_SC_GSM_BUSY) isEqualToNumber:call_session.byeCauseCode])
    );

    if (disconnected && !disconnected_busy && !disconnected_gsm_busy)
    {
        [self tone_start:call_id];
    }
}

@end