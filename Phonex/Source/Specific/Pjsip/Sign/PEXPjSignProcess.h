//
//  PEXPjSignProcess.h
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef __Phonex__PEXPjSignProcess__
#define __Phonex__PEXPjSignProcess__

#include "PEXPjSignDefs.h"
#include <stdio.h>

#define TIMESTAMP_SEC_LEN 10
#define TIMESTAMP_MSEC_LEN 3

#define POOL_INIT_SIZE	2048
#define POOL_INC_SIZE	256

pj_status_t pexsign_add_timestamp(pj_str_t* line2, pj_time_val ts);

pj_status_t pexsign_add_index(pj_str_t* line1, int value);

pj_status_t pexsign_set_length(char* buf, int len);

pj_status_t pexsign_add_cseq(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_status_code(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_request_uri(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_tx_destination(pj_str_t* line2, pjsip_tx_data *tdata);

pj_status_t pexsign_add_tx_source(pj_str_t* line2, pjsip_tx_data *tdata);

pj_status_t pexsign_add_rx_destination(pj_str_t* line2, pjsip_rx_data *rdata);

pj_status_t pexsign_add_rx_source(pj_str_t* line2, pjsip_rx_data *rdata);

pj_status_t pexsign_get_rx_source(pj_pool_t *pool, pj_str_t *dst, pjsip_rx_data *rdata);

pj_status_t pexsign_add_fromto_url(pj_str_t* line2, const pjsip_fromto_hdr* fromto_hdr);

pj_status_t pexsign_add_fromto_tag(pj_str_t* line2, const pjsip_fromto_hdr* fromto_hdr);

pj_status_t pexsign_add_to_uri(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_to_tag(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_from_uri(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_from_tag(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_add_call_id(pj_str_t* line2, pjsip_msg* msg);

pj_status_t pexsign_get_cseq(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg);

pj_status_t pexsign_get_request_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg);

pj_status_t pexsign_get_fromto_url(pj_pool_t * pool, pj_str_t * dst, const pjsip_fromto_hdr* fromto_hdr);

pj_status_t pexsign_get_to_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg);

pj_status_t pexsign_get_from_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg);

/* Extracts body from message if any */
pj_status_t pexsign_get_body(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg);

void bin_to_strhex(pj_pool_t * pool, unsigned char *bin, unsigned int binsz, pj_str_t * result);

#endif /* defined(__Phonex__PEXPjSignProcess__) */
