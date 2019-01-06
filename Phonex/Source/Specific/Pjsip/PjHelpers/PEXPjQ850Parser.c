//
//  PEXPjQ850Parser.c
//  Phonex
//
//  Created by Dusan Klinec on 12.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#include "PEXPjQ850Parser.h"

/**
* Utility from freeswitch to extract code from q.850 cause
*/
int lookup_q850_cause(const char *cause) {
    // Taken from http://wiki.freeswitch.org/wiki/Hangup_causes
    if (pj_ansi_stricmp(cause, "cause=1") == 0) {
        return 404;
    } else if (pj_ansi_stricmp(cause, "cause=2") == 0) {
        return 404;
    } else if (pj_ansi_stricmp(cause, "cause=3") == 0) {
        return 404;
    } else if (pj_ansi_stricmp(cause, "cause=17") == 0) {
        return 486;
    } else if (pj_ansi_stricmp(cause, "cause=18") == 0) {
        return 408;
    } else if (pj_ansi_stricmp(cause, "cause=19") == 0) {
        return 480;
    } else if (pj_ansi_stricmp(cause, "cause=20") == 0) {
        return 480;
    } else if (pj_ansi_stricmp(cause, "cause=21") == 0) {
        return 603;
    } else if (pj_ansi_stricmp(cause, "cause=22") == 0) {
        return 410;
    } else if (pj_ansi_stricmp(cause, "cause=23") == 0) {
        return 410;
    } else if (pj_ansi_stricmp(cause, "cause=25") == 0) {
        return 483;
    } else if (pj_ansi_stricmp(cause, "cause=27") == 0) {
        return 502;
    } else if (pj_ansi_stricmp(cause, "cause=28") == 0) {
        return 484;
    } else if (pj_ansi_stricmp(cause, "cause=29") == 0) {
        return 501;
    } else if (pj_ansi_stricmp(cause, "cause=31") == 0) {
        return 480;
    } else if (pj_ansi_stricmp(cause, "cause=34") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=38") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=41") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=42") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=44") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=52") == 0) {
        return 403;
    } else if (pj_ansi_stricmp(cause, "cause=54") == 0) {
        return 403;
    } else if (pj_ansi_stricmp(cause, "cause=57") == 0) {
        return 403;
    } else if (pj_ansi_stricmp(cause, "cause=58") == 0) {
        return 503;
    } else if (pj_ansi_stricmp(cause, "cause=65") == 0) {
        return 488;
    } else if (pj_ansi_stricmp(cause, "cause=69") == 0) {
        return 501;
    } else if (pj_ansi_stricmp(cause, "cause=79") == 0) {
        return 501;
    } else if (pj_ansi_stricmp(cause, "cause=88") == 0) {
        return 488;
    } else if (pj_ansi_stricmp(cause, "cause=102") == 0) {
        return 504;
    } else if (pj_ansi_stricmp(cause, "cause=487") == 0) {
        return 487;
    } else {
        return 0;
    }
}

/**
* Get Q.850 reason code from pjsip_event
*/
int get_q850_reason_code(pjsip_event *e) {
    int cause = 0;
    const pj_str_t HDR = { "Reason", 6 };
    pj_bool_t is_q850 = PJ_FALSE;

    if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG) {

        pjsip_generic_string_hdr *hdr =
                (pjsip_generic_string_hdr*) pjsip_msg_find_hdr_by_name(
                        e->body.tsx_state.src.rdata->msg_info.msg, &HDR, NULL);

        // TODO : check if the header should not be parsed here? -- I don't see how it could work without parsing.

        if (hdr) {
            char *token = strtok(hdr->hvalue.ptr, ";");
            while (token != NULL) {
                if (!is_q850 && pj_ansi_stricmp(token, "Q.850") == 0) {
                    is_q850 = PJ_TRUE;
                } else if (cause == 0) {
                    cause = lookup_q850_cause(token);
                }
                token = strtok(NULL, ";");
            }
        }
    }

    return (is_q850) ? cause : 0;
}
