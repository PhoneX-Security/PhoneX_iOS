//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjWrapper.h"
#import "PEXPjManager.h"
#import "PEXPjManager+Threads.h"


pjsua_callback wrapper_callback_struct = {
    &on_call_state,
    &on_incoming_call,
    &on_call_tsx_state,
    &on_call_media_state,
    &on_call_sdp_created,
    &on_stream_created,
    &on_stream_destroyed,
    &on_dtmf_digit,
    &on_call_transfer_request,
    NULL, //on_call_transfer_request2
    &on_call_transfer_status,
    &on_call_replace_request,
    NULL, //on_call_replace_request2
    &on_call_replaced,
    NULL, // on_call_rx_offer
    NULL, // on_call_tx_offer
    &on_reg_started,
    &on_reg_started2,
    &on_reg_state,
    &on_reg_state2,
    NULL, // incoming subscribe &on_incoming_subscribe,
    NULL, // srv_subscribe state &on_srv_subscribe_state,
    &on_buddy_state,
    NULL, // on_buddy_evsub_state
    &on_pager,
    &on_pager2,
    &on_pager_status,
    &on_pager_status2,
    &on_typing,
    &on_typing2, //Typing 2
    &on_nat_detect,
    &on_call_redirected,
    NULL, //on_mwi_state
    &on_mwi_info,
    &on_transport_state,
    &on_call_media_transport_state,
    &on_ice_transport_error,
    &on_snd_dev_operation, //on_snd_dev_operation
    &on_call_media_event, //on_call_media_event
    &on_transport_created, //on_create_media_transport
    &on_transport_srtp_created, //on_create_media_transport_srtp
    &on_acc_find_for_incoming,
    &on_stun_resolved,
    &on_reregistration_compute_backoff,
};

@implementation PEXPjWrapper {

}
@end


void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    [[PEXPjManager instance] on_call_state:call_id event:e];
}

void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    [[PEXPjManager instance] on_incoming_call:acc_id call_id:call_id rdata:rdata];
}

void on_call_media_state(pjsua_call_id call_id) {
    [[PEXPjManager instance] on_call_media_state:call_id];
}

void on_call_tsx_state(pjsua_call_id call_id, pjsip_transaction *tsx, pjsip_event *e) {
    [[PEXPjManager instance] on_call_tsx_state:call_id tsx:tsx e:e];
}

void on_call_sdp_created(pjsua_call_id call_id, pjmedia_sdp_session *sdp, pj_pool_t *pool, const pjmedia_sdp_session *rem_sdp) {
    [[PEXPjManager instance] on_call_sdp_created:call_id sdp:sdp pool:pool rem_sdp:rem_sdp];
}

void on_stream_created(pjsua_call_id call_id, pjmedia_stream *strm, unsigned stream_idx, pjmedia_port **p_port) {
    [[PEXPjManager instance] on_stream_created:call_id strm:strm stream_idx:stream_idx t:p_port];
}

void on_stream_destroyed(pjsua_call_id call_id, pjmedia_stream *strm, unsigned stream_idx) {
    [[PEXPjManager instance] on_stream_destroyed:call_id strm:strm stream_idx:stream_idx];
}

void on_dtmf_digit(pjsua_call_id call_id, int digit) {
    [[PEXPjManager instance] on_dtmf_digit:call_id digit:digit];
}

void on_call_transfer_request(pjsua_call_id call_id, const pj_str_t *dst, pjsip_status_code *code) {
    [[PEXPjManager instance] on_call_transfer_request:call_id dst:dst code:code];
}

void on_call_transfer_status(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final_, pj_bool_t *p_cont) {
    [[PEXPjManager instance] on_call_transfer_status:call_id st_code:st_code st_text:st_text final_:final_ p_cont:p_cont];
}

void on_call_replace_request(pjsua_call_id call_id, pjsip_rx_data *rdata, int *st_code, pj_str_t *st_text) {
    [[PEXPjManager instance] on_call_replace_request:call_id rdata:rdata st_code:st_code st_text:st_text];
}

void on_call_replaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id) {
    [[PEXPjManager instance] on_call_replaced:old_call_id new_call_id:new_call_id];
}

void on_reg_started(pjsua_acc_id acc_id, pj_bool_t renew) {
    [[PEXPjManager instance] on_reg_started:acc_id renew:renew];
}

void on_reg_started2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    [[PEXPjManager instance] on_reg_started2:acc_id info:info];
}

void on_reg_state(pjsua_acc_id acc_id) {
    [[PEXPjManager instance] on_reg_state:acc_id];
}

void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    [[PEXPjManager instance] on_reg_state2:acc_id info:info];
}

void on_buddy_state(pjsua_buddy_id buddy_id) {
    [[PEXPjManager instance] on_buddy_state:buddy_id];
}

void on_pager(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact,
        const pj_str_t *mime_type, const pj_str_t *body) {
    [[PEXPjManager instance] on_pager:call_id from:from to:to contact:contact mime_type:mime_type body:body];
}

void on_pager2(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact,
        const pj_str_t *mime_type, const pj_str_t *body, pjsip_rx_data *rdata, pjsua_acc_id acc_id) {
    [[PEXPjManager instance] on_pager2:call_id from:from to:to contact:contact mime_type:mime_type body:body rdata:rdata acc_id:acc_id];
}

void on_pager_status(pjsua_call_id call_id, const pj_str_t *to, const pj_str_t *body, void *user_data, pjsip_status_code status, const pj_str_t *reason) {
    [[PEXPjManager instance] on_pager_status:call_id to:to body:body user_data:user_data status:status reason:reason];
}

void on_pager_status2(pjsua_call_id call_id, const pj_str_t *to, const pj_str_t *body, void *user_data, pjsip_status_code status,
        const pj_str_t *reason, pjsip_tx_data *tdata, pjsip_rx_data *rdata, pjsua_acc_id acc_id) {
    [[PEXPjManager instance] on_pager_status2:call_id to:to body:body user_data:user_data status:status reason:reason tdata:tdata rdata:rdata acc_id:acc_id];
}

void on_typing(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact, pj_bool_t is_typing) {
    [[PEXPjManager instance] on_typing:call_id from:from to:to contact:contact is_typing:is_typing];
}

void on_typing2(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact, pj_bool_t is_typing, pjsip_rx_data *rdata, pjsua_acc_id acc_id) {
    [[PEXPjManager instance] on_typing2:call_id from:from to:to contact:contact is_typing:is_typing rdata:rdata acc_id:acc_id];
}

void on_nat_detect(const pj_stun_nat_detect_result *res) {
    [[PEXPjManager instance] on_nat_detect:res];
}

pjsip_redirect_op on_call_redirected(pjsua_call_id call_id, const pjsip_uri *target, const pjsip_event *e) {
    return [[PEXPjManager instance] on_call_redirected:call_id target:target e:e];
}

void on_mwi_info(pjsua_acc_id acc_id, pjsua_mwi_info *mwi_info) {
    [[PEXPjManager instance] on_mwi_info:acc_id mwi_info:mwi_info];
}

pj_status_t on_validate_audio_clock_rate(int clock_rate) {
    return [[PEXPjManager instance] on_validate_audio_clock_rate: clock_rate];
}

void on_setup_audio(pj_bool_t before_init) {
    [[PEXPjManager instance] on_setup_audio:before_init];
}

void on_teardown_audio() {
    [[PEXPjManager instance] on_teardown_audio];
}

int on_set_micro_source() {
    return [[PEXPjManager instance] on_set_micro_source];
}

pjmedia_transport* on_transport_created(pjsua_call_id call_id, unsigned media_idx, pjmedia_transport *base_tp, unsigned flags){
    return [[PEXPjManager instance] on_transport_created:call_id media_idx:media_idx base_tp:base_tp flags:flags];
}

void on_transport_srtp_created(pjsua_call_id call_id, unsigned media_idx, pjmedia_srtp_setting *srtp_opt){
    [[PEXPjManager instance] on_transport_srtp_created:call_id media_idx:media_idx settings:srtp_opt];
}

pj_status_t on_call_media_transport_state(pjsua_call_id call_id, const pjsua_med_tp_state_info *info) {
    return [[PEXPjManager instance] on_call_media_transport_state:call_id info:info];
}

void on_transport_state(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info) {
    [[PEXPjManager instance] on_transport_state:tp state:state info:info];
}

void on_ice_transport_error(int index, pj_ice_strans_op op, pj_status_t status, void *param) {
    [[PEXPjManager instance] on_ice_transport_error:index op:op status:status param:param];
}

pj_status_t on_snd_dev_operation(int operation){
    return [[PEXPjManager instance] on_snd_dev_operation:operation];
}

void on_call_media_event(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event) {
    [[PEXPjManager instance] on_call_media_event:call_id med_idx:med_idx event:event];
}

/**
* Logging callback for PJSIP.
* Logging via CocoaLumberjack.
*/
void pex_pjsip_log_msg(int level, const char *data, int len) {
    [PEXPjManager pjLogWrapper:level data:data len:len];
}

void register_calling_thread(const char * threadName) {
    [[PEXPjManager instance] registerCurrentThreadIfNotRegistered];
}

void on_acc_find_for_incoming(const pjsip_rx_data *rdata, pjsua_acc_id* acc_id){
    [[PEXPjManager instance] on_acc_find_for_incoming:rdata accId:acc_id];
}

void on_stun_resolved(const pj_stun_resolve_result *result){
    [[PEXPjManager instance] on_stun_resolved:result];
}

void on_reregistration_compute_backoff(pjsua_acc_id acc_id, unsigned *attempt_cnt, pj_time_val *delay) {
    [[PEXPjManager instance] on_reregistration_compute_backoff:acc_id attempt_cnt:attempt_cnt delay:delay];
}
