//
//  PEXPjSignCode.h
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef __Phonex__PEXPjSignCode__
#define __Phonex__PEXPjSignCode__

#include "PEXPjSignDefs.h"
#include "PEXPjSignParser.h"
#include "PEXPjSignProcess.h"

void mod_sign_set_callback(PEXSignCallback* cb);

PJ_DEF(pj_status_t) init_sig_desc(struct esign_descriptor * desc);

PJ_DEF(esign_descriptor *) pjsip_rdata_get_sigdesc( pjsip_rx_data * rdata );

PJ_DEF(pj_status_t) pjsip_rdata_set_sigdesc( pjsip_rx_data * rdata, esign_descriptor * desc );

PJ_DEF(int) pjsip_rdata_get_signature( pjsip_rx_data * rdata, esign_process_info * ret );

/* Finds generic string header in message */
static pjsip_generic_string_hdr * sign_get_eehdr(pjsip_msg* msg, EE_extra_hdr_t htype, const void * start);

/* Sets EE hdr to the message, if does not exist new is added otherwise existing is updated */
static pj_status_t sign_set_eehdr(pjsip_tx_data *tdata, EE_extra_hdr_t htype, const char * hval);
void bin_to_strhex(pj_pool_t * pool, unsigned char *bin, unsigned int binsz, pj_str_t * result);

static pj_status_t get_eesign_data_from_msg(pj_pool_t * pool, pjsip_msg * msg, esignInfo_t * edat);

static pj_status_t sign_on_rx_msg(pjsip_rx_data *rdata);

/* Notification on outgoing messages */
static pj_status_t sign_on_tx_msg(pjsip_tx_data *tdata);

/**
* Module load()
*/
static pj_status_t mod_sign_load(pjsip_endpoint *endpt);
/**
* Module unload()
*/
static pj_status_t mod_sign_unload(void);

/**
* Module init
*/
PJ_DECL(pj_status_t) mod_sign_init();

#endif /* defined(__Phonex__PEXPjSignCode__) */
