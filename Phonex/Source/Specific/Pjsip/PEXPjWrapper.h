//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef PEX_PJ_WRAPPER_H
#define PEX_PJ_WRAPPER_H

#import <Foundation/Foundation.h>
#import "pexpj.h"

void register_calling_thread(const char * threadName);
void on_call_state (pjsua_call_id call_id, pjsip_event *e);
void on_incoming_call (pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
void on_call_tsx_state (pjsua_call_id call_id, pjsip_transaction *tsx, pjsip_event *e);
void on_call_media_state (pjsua_call_id call_id);
void on_call_sdp_created (pjsua_call_id call_id, pjmedia_sdp_session *sdp, pj_pool_t *pool, const pjmedia_sdp_session *rem_sdp);
void on_stream_created (pjsua_call_id call_id, pjmedia_stream *strm, unsigned stream_idx, pjmedia_port **p_port);
void on_stream_destroyed (pjsua_call_id call_id, pjmedia_stream *strm, unsigned stream_idx);
void on_dtmf_digit (pjsua_call_id call_id, int digit);
void on_call_transfer_request (pjsua_call_id call_id, const pj_str_t *dst, pjsip_status_code *code);
void on_call_transfer_status (pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final_, pj_bool_t *p_cont);
void on_call_replace_request (pjsua_call_id call_id, pjsip_rx_data *rdata, int *st_code, pj_str_t *st_text);
void on_call_replaced (pjsua_call_id old_call_id, pjsua_call_id new_call_id);
void on_reg_started(pjsua_acc_id acc_id, pj_bool_t renew);
void on_reg_started2(pjsua_acc_id acc_id, pjsua_reg_info *info);
void on_reg_state (pjsua_acc_id acc_id);
void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info);
void on_buddy_state (pjsua_buddy_id buddy_id);
void on_pager (pjsua_call_id call_id, const pj_str_t *from,const pj_str_t *to, const pj_str_t *contact,
        const pj_str_t *mime_type, const pj_str_t *body);
void on_pager2 (pjsua_call_id call_id, const pj_str_t *from,
        const pj_str_t *to, const pj_str_t *contact,
        const pj_str_t *mime_type, const pj_str_t *body,
        pjsip_rx_data *rdata,
        pjsua_acc_id acc_id);
void on_pager_status (pjsua_call_id call_id,
        const pj_str_t *to,
        const pj_str_t *body,
        void *user_data,
        pjsip_status_code status,
        const pj_str_t *reason);
void on_pager_status2 (pjsua_call_id call_id,
        const pj_str_t *to,
        const pj_str_t *body,
        void *user_data,
        pjsip_status_code status,
        const pj_str_t *reason,
        pjsip_tx_data *tdata,
        pjsip_rx_data *rdata,
        pjsua_acc_id acc_id);
void on_typing (pjsua_call_id call_id, const pj_str_t *from,
        const pj_str_t *to, const pj_str_t *contact,
        pj_bool_t is_typing);
void on_typing2 (pjsua_call_id call_id, const pj_str_t *from,
        const pj_str_t *to, const pj_str_t *contact,
        pj_bool_t is_typing,
        pjsip_rx_data *rdata,
        pjsua_acc_id acc_id);
void on_nat_detect (const pj_stun_nat_detect_result *res);
pjsip_redirect_op on_call_redirected (pjsua_call_id call_id, const pjsip_uri *target, const pjsip_event *e);
void on_mwi_info (pjsua_acc_id acc_id, pjsua_mwi_info *mwi_info);
pj_status_t on_call_media_transport_state(pjsua_call_id call_id, const pjsua_med_tp_state_info *info);
void on_transport_state(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info);
void on_ice_transport_error(int index, pj_ice_strans_op op, pj_status_t status, void *param);
pj_status_t on_snd_dev_operation(int operation);
void on_call_media_event(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event);
pj_status_t on_validate_audio_clock_rate (int clock_rate);
void on_setup_audio (pj_bool_t before_init);
void on_teardown_audio ();
int on_set_micro_source ();
pjmedia_transport* on_transport_created(pjsua_call_id call_id, unsigned media_idx, pjmedia_transport *base_tp, unsigned flags);
void on_transport_srtp_created(pjsua_call_id call_id, unsigned media_idx, pjmedia_srtp_setting *srtp_opt);
void on_acc_find_for_incoming(const pjsip_rx_data *rdata, pjsua_acc_id* acc_id);
void on_stun_resolved(const pj_stun_resolve_result *result);
void on_reregistration_compute_backoff(pjsua_acc_id acc_id, unsigned	*attempt_cnt, pj_time_val *delay);
struct pjsua_callback wrapper_callback_struct;

@interface PEXPjWrapper : NSObject



@end

#endif