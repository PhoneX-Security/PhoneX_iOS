//
// Created by Dusan Klinec on 10.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjToneBusy.h"
#import "PEXPjManager.h"
#import "PEXPjCall.h"

@implementation PEXPjToneBusy {

}

- (unsigned int)tone_cnt {
    return 1;
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    tone[0].freq1 = 480;
    tone[0].freq2 = 62;
    tone[0].on_msec = 500;
    tone[0].off_msec = 500;
}

- (NSString *)tone_name {
    return @"busyTone";
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

    if (disconnected_busy || disconnected_gsm_busy)
    {
        [self tone_start:call_id];
        [self tone_schedule_stop:3500];
    }
}

@end