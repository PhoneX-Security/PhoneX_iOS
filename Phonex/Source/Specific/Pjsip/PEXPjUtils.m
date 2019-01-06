//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjUtils.h"
#import "pjsip/sip_msg.h"
#import "pjsip/sip_event.h"
#import "pjsip/sip_transport.h"


@implementation PEXPjUtils {

}

+ (NSString *)copyToString:(pj_str_t const *)str {
    if (str == NULL){
        return nil;
    }

    if (str->slen<=0 || str->ptr == NULL){
        return @"";
    }

    return [NSString stringWithFormat:@"%.*s", (int)str->slen, str->ptr];
}

+ (void)assignToPjString:(NSString const *const)str pjstr:(pj_str_t *)pj {
    if (pj == NULL){
        return;
    }

    if (str == nil){
        pj->slen = 0;
        pj->ptr = NULL;
    }

    pj->ptr = [str cStringUsingEncoding:NSUTF8StringEncoding];
    pj->slen = (pj_ssize_t)[str length];
}

+ (NSString *)searchForHeader:(NSString *)hdr inMessage:(pjsip_msg *)msg {
    if (hdr == nil || msg == nil){
        return nil;
    }

    const char * c_hdrStr = [hdr cStringUsingEncoding:NSUTF8StringEncoding];
    const size_t c_hdrStrLen = strlen(c_hdrStr);

    pjsip_generic_string_hdr *s_hdr = NULL;
    const pj_str_t STR_HDR = { c_hdrStr, c_hdrStrLen };

    /* Save ETag value */
    s_hdr = (pjsip_generic_string_hdr*) pjsip_msg_find_hdr_by_name(msg, &STR_HDR, NULL);
    if (s_hdr) {
        return [PEXPjUtils copyToString:&(s_hdr->hvalue)];
    }

    return nil;
}

+ (NSString *)getCallIdFromMessage:(pjsip_msg *)msg {
    if (msg == NULL){
        return nil;
    }

    pjsip_cid_hdr *hdr = (pjsip_cid_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CALL_ID, NULL);
    if (hdr == NULL){
        return nil;
    }

    return [PEXPjUtils copyToString:&(hdr->id)];
}

+ (pjsip_msg *)getMsgFromEvt:(pjsip_event *)e {
    if (e == NULL){
        return NULL;
    }

    if (e->type == PJSIP_EVENT_TSX_STATE){
        if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG
                && e->body.tsx_state.src.rdata != NULL
                && e->body.tsx_state.src.rdata->msg_info.msg != NULL)
        {
            return e->body.tsx_state.src.rdata->msg_info.msg;

        }
        else if (e->body.tsx_state.type == PJSIP_EVENT_TX_MSG
                && e->body.tsx_state.src.tdata != NULL
                && e->body.tsx_state.src.tdata->msg != NULL)
        {
            return e->body.tsx_state.src.tdata->msg;
        }


    } else if (e->type == PJSIP_EVENT_RX_MSG
            && e->body.rx_msg.rdata != NULL
            && e->body.rx_msg.rdata->msg_info.msg != NULL)
    {
        return e->body.rx_msg.rdata->msg_info.msg;

    } else if (e->type == PJSIP_EVENT_TX_MSG
            && e->body.tx_msg.tdata != NULL
            && e->body.tx_msg.tdata->msg != NULL)
    {
        return e->body.tx_msg.tdata->msg;

    } else {
        return NULL;
    }

    return NULL;
}

+ (NSString *)getCallIdFromEvt:(pjsip_event *)e {
    pjsip_msg * msg = [self getMsgFromEvt:e];
    if (msg == NULL){
        return nil;
    }

    return [self getCallIdFromMessage:msg];
}


@end