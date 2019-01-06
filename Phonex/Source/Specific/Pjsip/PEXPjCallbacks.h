//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pjsua-lib/pjsua.h"
#import <pjsua-lib/pjsua.h>
#import "pjsua.h"
#import "pjsua-lib/pjsua.h"
#import "pjsip.h"
#import "pjsip/sip_types.h"

/**
* Abstract interface for PjCallback object.
*/
@interface PEXPjCallbacks : NSObject
-(void) on_call_state: (pjsua_call_id) call_id event: (pjsip_event *) e;
-(void) on_incoming_call: (pjsua_acc_id) acc_id call_id: (pjsua_call_id) call_id rdata: (pjsip_rx_data *) rdata;
-(void) on_call_tsx_state: (pjsua_call_id) call_id tsx: (pjsip_transaction *) tsx e: (pjsip_event *) e;
-(void) on_call_media_state: (pjsua_call_id) call_id;
-(void) on_call_sdp_created: (pjsua_call_id) call_id sdp: (pjmedia_sdp_session *) sdp pool: (pj_pool_t *) pool rem_sdp: (const pjmedia_sdp_session *) rem_sdp;
-(void) on_stream_created: (pjsua_call_id) call_id strm: (pjmedia_stream *) strm stream_idx: (unsigned ) stream_idx t: (pjmedia_port**) p_port;
-(void) on_stream_destroyed: (pjsua_call_id) call_id strm: (pjmedia_stream *) strm stream_idx: (unsigned ) stream_idx;
-(void) on_dtmf_digit: (pjsua_call_id) call_id digit: (int ) digit;
-(void) on_call_transfer_request: (pjsua_call_id) call_id dst: (const pj_str_t *) dst code: (pjsip_status_code *) code;
-(void) on_call_transfer_status: (pjsua_call_id) call_id st_code: (int ) st_code st_text: (const pj_str_t *) st_text final_: (pj_bool_t ) final_ p_cont: (pj_bool_t *) p_cont;
-(void) on_call_replace_request: (pjsua_call_id) call_id rdata: (pjsip_rx_data *) rdata st_code: (int *) st_code st_text: (pj_str_t *) st_text;
-(void) on_call_replaced: (pjsua_call_id) old_call_id new_call_id: (pjsua_call_id ) new_call_id;
-(void) on_reg_started: (pjsua_acc_id) acc_id renew: (pj_bool_t) renew;
-(void) on_reg_started2: (pjsua_acc_id)acc_id info: (pjsua_reg_info *)info;
-(void) on_reg_state: (pjsua_acc_id) acc_id;
-(void) on_reg_state2: (pjsua_acc_id) acc_id info: (pjsua_reg_info*) info;
-(void) on_buddy_state: (pjsua_buddy_id) buddy_id;
-(void) on_pager: (pjsua_call_id) call_id from: (const pj_str_t *) from to: (const pj_str_t *) to contact: (const pj_str_t *) contact mime_type: (const pj_str_t *) mime_type body: (const pj_str_t *) body;
-(void) on_pager2: (pjsua_call_id) call_id from: (const pj_str_t *) from to: (const pj_str_t *) to contact: (const pj_str_t *) contact mime_type: (const pj_str_t *) mime_type body: (const pj_str_t *) body rdata: (pjsip_rx_data *) rdata acc_id: (pjsua_acc_id ) acc_id;
-(void) on_pager_status: (pjsua_call_id) call_id to: (const pj_str_t *) to body: (const pj_str_t *) body user_data: (void *) user_data status: (pjsip_status_code ) status reason: (const pj_str_t *) reason;
-(void) on_pager_status2: (pjsua_call_id) call_id to: (const pj_str_t *) to body: (const pj_str_t *) body user_data: (void *) user_data status: (pjsip_status_code ) status reason: (const pj_str_t *) reason tdata: (pjsip_tx_data *) tdata rdata: (pjsip_rx_data *) rdata acc_id: (pjsua_acc_id ) acc_id;
-(void) on_typing: (pjsua_call_id) call_id from: (const pj_str_t *) from to: (const pj_str_t *) to contact: (const pj_str_t *) contact is_typing: (pj_bool_t ) is_typing;
-(void) on_typing2: (pjsua_call_id) call_id from: (const pj_str_t *) from to: (const pj_str_t *) to contact: (const pj_str_t *) contact is_typing: (pj_bool_t ) is_typing rdata: (pjsip_rx_data *) rdata acc_id: (pjsua_acc_id ) acc_id;
-(void) on_nat_detect: (const pj_stun_nat_detect_result *) res;
-(pjsip_redirect_op) on_call_redirected: (pjsua_call_id) call_id target: (const pjsip_uri *) target e: (const pjsip_event *) e;
-(void) on_mwi_info: (pjsua_acc_id) acc_id mwi_info: (pjsua_mwi_info *) mwi_info;
-(pj_status_t) on_validate_audio_clock_rate: (int) clock_rate;
-(void) on_setup_audio: (pj_bool_t) before_init;
-(void) on_teardown_audio;
-(int) on_set_micro_source;
-(pj_status_t) on_call_media_transport_state: (pjsua_call_id) call_id info: (const pjsua_med_tp_state_info *) info;
-(void) on_transport_state: (pjsip_transport *) tp state: (pjsip_transport_state) state info: (const pjsip_transport_state_info *) info;
-(void) on_ice_transport_error: (int) index op: (pj_ice_strans_op) op status: (pj_status_t) status param: (void *) param;
-(void) on_call_media_event: (pjsua_call_id) call_id med_idx: (unsigned) med_idx event: (pjmedia_event *) event;
-(pjmedia_transport*) on_transport_created: (pjsua_call_id) call_id media_idx: (unsigned) media_idx base_tp: (pjmedia_transport *) base_tp flags: (unsigned) flags;
-(void) on_transport_srtp_created: (pjsua_call_id) call_id media_idx: (unsigned) media_idx settings:(pjmedia_srtp_setting*)settings;
-(pj_status_t) on_snd_dev_operation:(int) operation;
-(void) on_acc_find_for_incoming: (const pjsip_rx_data *) rdata accId:(pjsua_acc_id*) acc_id;
-(void) on_stun_resolved: (const pj_stun_resolve_result *)result;
-(void) on_reregistration_compute_backoff:(pjsua_acc_id) acc_id attempt_cnt: (unsigned *) attempt_cnt delay: (pj_time_val *)delay;
@end