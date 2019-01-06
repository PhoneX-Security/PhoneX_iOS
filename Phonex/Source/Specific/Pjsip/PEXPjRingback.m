//
// Created by Dusan Klinec on 09.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

/**
* Copyright (C) 2010 Regis Montoya (aka r3gis - www.r3gis.fr)
* This file is part of pjsip_android.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/


//---------------------
// RINGBACK MANAGEMENT-
// --------------------
/* Ringtones		    US	       UK  */
#define RINGBACK_FREQ1	    440	    /* 400 */
#define RINGBACK_FREQ2	    480	    /* 450 */
#define RINGBACK_ON	        2000    /* 400 */
#define RINGBACK_OFF	    4000    /* 200 */
#define RINGBACK_CNT	    1	    /* 2   */
#define RINGBACK_INTERVAL   4000    /* 2000 */

#import "PEXPjRingback.h"
#import "PEXPjConfig.h"
#import "PEXPjTone_protected.h"

@implementation PEXPjRingback {

}

+ (instancetype)ringbackWithConfig:(PEXPjConfig *)config {
    return [[self alloc] initWithConfig:config];
}

- (unsigned int)tone_cnt {
    return RINGBACK_CNT;
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    unsigned int i;
    for (i = 0; i < RINGBACK_CNT; ++i) {
        tone[i].freq1 = RINGBACK_FREQ1;
        tone[i].freq2 = RINGBACK_FREQ2;
        tone[i].on_msec = RINGBACK_ON;
        tone[i].off_msec = RINGBACK_OFF;
    }
    tone[RINGBACK_CNT - 1].off_msec = RINGBACK_INTERVAL;
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

    if (call_info->state == PJSIP_INV_STATE_DISCONNECTED) {
        /* Stop all ringback for this call */
        [self tone_stop:call_id];
        DDLogDebug(@"Call %d is DISCONNECTED [reason=%d (%.*s)]",
                call_id,
                call_info->last_status,
                (int) call_info->last_status_text.slen,
                call_info->last_status_text.ptr);

    } else if (call_info->state == PJSIP_INV_STATE_EARLY) {
        int code;
        pj_str_t reason;
        pjsip_msg *msg;

        /* This can only occur because of TX or RX message */
        pj_assert(e->type == PJSIP_EVENT_TSX_STATE);

        if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG) {
            msg = e->body.tsx_state.src.rdata->msg_info.msg;
        } else {
            msg = e->body.tsx_state.src.tdata->msg;
        }

        code = msg->line.status.code;
        reason = msg->line.status.reason;

        /* Start ringback for 180 for UAC unless there's SDP in 180 */
        if (call_info->role == PJSIP_ROLE_UAC && code == 180
                && msg->body == NULL
                && call_info->media_status == PJSUA_CALL_MEDIA_NONE)
        {
            [self tone_start:call_id];
        }

        DDLogDebug(@"Call %d state changed to %.*s (%d %.*s)", call_id,
                (int)call_info->state_text.slen,
                call_info->state_text.ptr,
                code, (int)reason.slen, reason.ptr);
    } else {
        DDLogDebug(@"Call %d state changed to %.*s", call_id, (int)call_info->state_text.slen, call_info->state_text.ptr);
    }
}

- (void) on_call_media_state:(pjsua_call_id)call_id call_info: (pjsua_call_info *) pjsua_call_info {
    [self tone_stop:call_id];
}

- (NSString *)tone_name {
    return @"ringback";
}

@end