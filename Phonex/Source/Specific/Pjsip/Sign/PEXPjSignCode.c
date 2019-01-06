//
//  PEXPjSignCode.c
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#include "PEXPjSignCode.h"
#include <openssl/sha.h>
#define THIS_FILE "PEXPjSignCode.c"

/* Callback for signature generation/verification. */
static PEXSignCallback * registeredCallbackObject = NULL;

/* The module instance. */
static pjsip_module pjsua_sipsign_mod =
{
        NULL, NULL,                            /* prev, next.      */
        { "mod-sign", 8 },                     /* Name.            */
        -1,                                    /* Id               */
        PJSIP_MOD_PRIORITY_TRANSPORT_LAYER+1,  /* Priority         */
        &mod_sign_load,          /* load()           */
        NULL,                    /* start()          */
        NULL,                    /* stop()           */
        &mod_sign_unload,		 /* unload()         */
        &sign_on_rx_msg,         /* on_rx_request()  */
        &sign_on_rx_msg,         /* on_rx_response() */
        &sign_on_tx_msg,         /* on_tx_request.   */
        &sign_on_tx_msg,         /* on_tx_response() */
        NULL,                    /* on_tsx_state()   */
};

void mod_sign_set_callback(PEXSignCallback* cb){
    registeredCallbackObject = cb;
}

PJ_DEF(pj_status_t) init_sig_desc(struct esign_descriptor * desc){
    if (desc == NULL) return !PJ_SUCCESS;
    memset(desc, 0, sizeof(struct esign_descriptor));
    desc->endpt = NULL;
    desc->mod   = &pjsua_sipsign_mod;
    desc->pool  = NULL;

    return PJ_SUCCESS;
}

PJ_DEF(esign_descriptor *) pjsip_rdata_get_sigdesc( pjsip_rx_data * rdata ){
    if (rdata == NULL) return NULL;
    else               return (esign_descriptor *) rdata->endpt_info.mod_data[pjsua_sipsign_mod.id];
}

PJ_DEF(pj_status_t) pjsip_rdata_set_sigdesc( pjsip_rx_data * rdata, esign_descriptor * desc ){
    if (rdata == NULL) return PJ_EINVAL;
    rdata->endpt_info.mod_data[pjsua_sipsign_mod.id] = desc;
    return PJ_SUCCESS;
}

PJ_DEF(int) pjsip_rdata_get_signature( pjsip_rx_data * rdata, esign_process_info * ret ){
    esign_descriptor * desc = NULL;
    PJ_ASSERT_RETURN(rdata != NULL && ret != NULL, PJ_EINVAL);

    desc = pjsip_rdata_get_sigdesc(rdata);
    pj_bzero(ret, sizeof(*ret));

    pj_memcpy(ret, &(desc->sign_info), sizeof(esign_process_info));

    return PJ_SUCCESS;
}

/* Finds generic string header in message */
static pjsip_generic_string_hdr * sign_get_eehdr(pjsip_msg* msg, EE_extra_hdr_t htype, const void * start){
    pj_assert(msg!=NULL);

    // try to get EESIGN header if present
    pj_str_t hname   = htype==EE_SIGN_ID ? pj_str(EESIGN_HDR) : pj_str(EESIGN_DESC_HDR);
    PJ_LOG(4, (THIS_FILE, "Looking for header [%.*s]", hname.slen, hname.ptr));
    return (pjsip_generic_string_hdr *) pjsip_msg_find_hdr_by_name(msg, &hname, start);
}

/* Sets EE hdr to the message, if does not exist new is added otherwise existing is updated */
static pj_status_t sign_set_eehdr(pjsip_tx_data *tdata, EE_extra_hdr_t htype, const char * hval){
    // at first try to determine whether we saw this message before
    pjsip_generic_string_hdr * eeHdr = sign_get_eehdr(tdata->msg, htype, NULL);
    const char * eeHdrName           = htype == EE_SIGN_ID ? EESIGN_HDR : EESIGN_DESC_HDR;

    // hvalue must be allocated on TX data pool in both cases
    pj_str_t hvalue = {0,0};
    pj_strdup2(tdata->pool, &hvalue, hval);

    if (eeHdr==NULL){
        // not found, add new header
        PJ_LOG(4, (THIS_FILE, "EESIGN_%d was not found; adding new", htype));

        // Create whole message header
        // Warning: allocate from message pool!
        pjsip_generic_string_hdr * my_hdr = PJ_POOL_ZALLOC_T(tdata->pool, pjsip_generic_string_hdr);
        pj_str_t hname  = {0,0};

        pj_strdup2(tdata->pool, &hname, eeHdrName);

        pjsip_generic_string_hdr_init2(my_hdr, &hname, &hvalue);
        pj_list_push_back(&(tdata->msg->hdr), my_hdr);

        pjsip_tx_data_invalidate_msg(tdata);  // invalidate message -> it will be re-printed to buffer from data
    } else {
        // header was found, change its value
        PJ_LOG(4, (THIS_FILE, "EESIGN_%d was found; updating new; previously: [%.*s]", htype, eeHdr->hvalue.slen, eeHdr->hvalue.ptr));
        eeHdr->hvalue.ptr  = hvalue.ptr;
        eeHdr->hvalue.slen = hvalue.slen;

        pjsip_tx_data_invalidate_msg(tdata);  // invalidate message -> it will be re-printed to buffer from data
    }

    return PJ_SUCCESS;
}

static pj_status_t get_eesign_data_from_msg(pj_pool_t * pool, pjsip_msg * msg, esignInfo_t * edat){
    // @deprecated
    //const pjsip_call_info_hdr *call_id = (const pjsip_call_info_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CALL_ID, NULL);
    int totalSize = 0;

    // CSEQ string repr
    const pjsip_cseq_hdr *cseq = NULL;
    char buf[128] = {0};
    char buf_status[24] = {0};

    // message digest
    unsigned char md[SHA256_DIGEST_LENGTH] = {0};

    pj_assert(pool != NULL);
    pj_assert(msg  != NULL && edat != NULL);

    // set pointers & lengths to zero.
    memset(edat, 0, sizeof(esignInfo_t));
    edat->pool = pool;
    edat->isRequest = msg->type == PJSIP_REQUEST_MSG;
    cseq = (const pjsip_cseq_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CSEQ, NULL);
    if (cseq==NULL) return !PJ_SUCCESS;

    // CSEQ string repr
    pj_ansi_snprintf(buf, sizeof(buf), "%d|%.*s", cseq->cseq, (int)cseq->method.name.slen, cseq->method.name.ptr);
    pj_strdup2_with_null(pool, &(edat->cseqStr), buf); // create destination string with exact size allocated from pool
    edat->cseqInt = cseq->cseq;
    pj_strdup_with_null(pool, &(edat->method), &(cseq->method.name));

    // @deprecated, used direct parsing - we are also interested in cseq number & method name separately
    //pexsign_get_cseq(pool, &(edat->cseqStr), msg);
    totalSize+=edat->cseqStr.slen+1;
    // REQ uri - only in case we have request
    if (edat->isRequest==PJ_TRUE){
        pexsign_get_request_uri(pool, &(edat->reqUriStr), msg);
        totalSize+=edat->reqUriStr.slen+1;

        edat->resp_status = 0;
    } else {
        edat->resp_status = msg->line.status.code;
    }
    // FROM uri
    pexsign_get_from_uri(pool, &(edat->fromUriStr), msg);
    totalSize+=edat->fromUriStr.slen+1;
    // TO uri
    pexsign_get_to_uri(pool, &(edat->toUriStr), msg);
    totalSize+=edat->toUriStr.slen+1;
    // BODY
    pexsign_get_body(pool, &(edat->bodyStr), msg);
    totalSize+=edat->bodyStr.slen+1;
    // Status
    totalSize+=sprintf(buf_status, "%05d", edat->resp_status)+1;

    // now build accumulated string that will be hashed and signed afterwards
    edat->accumStr.ptr = (char*) pj_pool_zalloc(pool, sizeof(char) * (totalSize+64)); // allocate with security margin
    if (edat->accumStr.ptr == NULL){
        PJ_LOG(2, (THIS_FILE, "Unable to allocate new memory of size=%d from pool: [%s] capacity=%d", totalSize+64, pool->obj_name, pool->capacity));
        return !PJ_SUCCESS;
    }

    // Update: ReqUri is probably modified by server, excluded from signature.
    // Caused real problems with INVITE.
    pj_strcat2(&(edat->accumStr), edat->isRequest==PJ_TRUE ? "Q":"S");  pj_strcat2(&(edat->accumStr), "|");
    pj_strcat2(&(edat->accumStr), buf_status);                          pj_strcat2(&(edat->accumStr), "|");
    pj_strcat (&(edat->accumStr), &(edat->cseqStr));                    pj_strcat2(&(edat->accumStr), "|");
    //pj_strcat (&(edat->accumStr), &(edat->reqUriStr));                  pj_strcat2(&(edat->accumStr), "|");
    pj_strcat (&(edat->accumStr), &(edat->fromUriStr));                 pj_strcat2(&(edat->accumStr), "|");
    pj_strcat (&(edat->accumStr), &(edat->toUriStr));                   pj_strcat2(&(edat->accumStr), "|");
    pj_strcat (&(edat->accumStr), &(edat->bodyStr));                    pj_strcat2(&(edat->accumStr), "|\0x00");

    // compute SHA256 digest
    SHA256((unsigned char *) edat->accumStr.ptr, edat->accumStr.slen, (unsigned char *) md);
    bin_to_strhex(pool, md, SHA256_DIGEST_LENGTH, &(edat->accumSha256Str));

    // hash body
    SHA256((unsigned char *) edat->bodyStr.ptr, edat->bodyStr.slen, (unsigned char *) md);
    bin_to_strhex(pool, md, SHA256_DIGEST_LENGTH, &(edat->bodySha256Str));

    // not null terminated string format sequence: %.*s
    PJ_LOG(4, (THIS_FILE, "CSEQ str:    [%s]", edat->cseqStr.ptr));
    PJ_LOG(4, (THIS_FILE, "ReqUri str:  [%s]", edat->reqUriStr.ptr));
    PJ_LOG(4, (THIS_FILE, "FromUri str: [%s]", edat->fromUriStr.ptr));
    PJ_LOG(4, (THIS_FILE, "ToUri str:   [%s]", edat->toUriStr.ptr));
    PJ_LOG(4, (THIS_FILE, "Hash256 str: [%s]", edat->accumSha256Str.ptr));
    PJ_LOG(4, (THIS_FILE, "ToHash str:  [%s]", edat->accumStr.ptr));

    return PJ_SUCCESS;
}

static pj_status_t sign_on_rx_msg(pjsip_rx_data *rdata)
{
    pjsip_method_e mthd;
    pj_status_t toReturn = PJ_SUCCESS;

    PJ_LOG(4, (THIS_FILE, "mod_sign_on_rx_msg"));
    if(rdata == NULL || rdata->msg_info.msg == NULL){
        PJ_LOG(1, (THIS_FILE, "rdata or msg is null!"));
        return PJ_SUCCESS;
    }

    mthd = rdata->msg_info.cseq->method.id;
    if (mthd == PJSIP_INVITE_METHOD || mthd==PJSIP_BYE_METHOD){
        pj_bool_t isRequest =  rdata->msg_info.msg->type == PJSIP_REQUEST_MSG;
        pj_pool_t* pool = NULL;

        PJ_LOG(4, (THIS_FILE, "INVITE or BYE method here, req: %d; objName: [%s]", isRequest, rdata->msg_info.info));
        if (isRequest==PJ_FALSE){
            // We are interested in INVITE 200 OK response, since it contains also ZRTP-HASH
            if (mthd != PJSIP_INVITE_METHOD || rdata->msg_info.msg->line.status.code!=200) return PJ_SUCCESS;
        }

        // allocate new memory pool for subsequent memory allocations
        pool = pjsua_pool_create("signPoolRX", POOL_INIT_SIZE, POOL_INC_SIZE);
        if (pool==NULL){
            PJ_LOG(1, (THIS_FILE, "Cannot create new pool! initSize=%d", POOL_INIT_SIZE));
            return PJ_SUCCESS;
        }

        // generate null descriptor
        esign_descriptor * desc = PJ_POOL_ZALLOC_T(rdata->tp_info.pool, esign_descriptor);
        pjsip_rdata_set_sigdesc(rdata, desc);
        init_sig_desc(desc);
        desc->pool = rdata->tp_info.pool;
        desc->sign_info.process_state     = ESIGN_PROCESS_STATE_PROCESSED;
        desc->sign_info.signature_present = PJ_TRUE;

        //
        // Obtain required parts of the message
        //
        esignInfo_t edat;
        get_eesign_data_from_msg(pool, rdata->msg_info.msg, &edat);

        // Obtain IP address of message source
        pexsign_get_rx_source(pool, &(edat.ip), rdata);

        // try to get EESIGN header if present
        pj_str_t eehash = {0,0};
        pj_str_t eedesc = {0,0};
        pjsip_generic_string_hdr * eesignHdr = sign_get_eehdr(rdata->msg_info.msg, EE_SIGN_ID, NULL);
        pjsip_generic_string_hdr * eedescHdr = sign_get_eehdr(rdata->msg_info.msg, EE_SIGN_DESC_ID, NULL);

        // EE-Sign header
        if (eesignHdr==NULL){
            PJ_LOG(4, (THIS_FILE, "EESIGN was not found"));
            desc->sign_info.signature_present = PJ_FALSE;
        } else {
            pj_strdup_with_null(pool, &eehash, &(eesignHdr->hvalue));
            PJ_LOG(4, (THIS_FILE, "EESIGN was found! [%.*s];", eehash.slen, eehash.ptr));
        }

        // EE-Sign-Desc header
        if (eedescHdr==NULL){
            PJ_LOG(4, (THIS_FILE, "EESIGN-DESC was not found"));
            desc->sign_info.signature_present = PJ_FALSE;
        } else {
            pj_strdup_with_null(pool, &eedesc, &(eedescHdr->hvalue));
            PJ_LOG(4, (THIS_FILE, "EESIGN-DESC was found! [%.*s];", eedesc.slen, eedesc.ptr));
        }

        // DEBUG: dumping headers
        //const pjsip_hdr *hdr=rdata->msg_info.msg->hdr.next, *end=&rdata->msg_info.msg->hdr;
        //for (; hdr!=end; hdr = hdr->next) {
        //	PJ_LOG(4, (THIS_FILE, "hdrDump [%.*s];", hdr->name.slen, hdr->name.ptr));
        //}

        // pass analyzed data to callback object to verify signature
        if (registeredCallbackObject!=NULL){
            int errCode = registeredCallbackObject->verifySign(&edat, eehash.ptr, eedesc.ptr);
            int errCodeClean                  = errCode & (~EESIGN_FLAG_DROP_PACKET);
            desc->sign_info.signature_valid   = errCode == 0 ? PJ_TRUE : PJ_FALSE;
            desc->sign_info.callback_return   = errCode;
            desc->sign_info.cseq_int          = edat.cseqInt;
            desc->sign_info.is_request        = edat.isRequest;
            desc->sign_info.status_code       = edat.resp_status;
            desc->sign_info.packet_dropped    = (errCode & EESIGN_FLAG_DROP_PACKET) > 0;
            desc->sign_info.verify_err        = (errCodeClean >=0 && errCodeClean < ESIGN_SIGN_ERR_MAX) ? (esign_sign_err_e) errCodeClean : ESIGN_SIGN_ERR_GENERIC;

            // Copy interesting parts of the signature & hash
            // to RX data, using long term pool.
            pj_strdup_with_null(desc->pool, &(desc->sign_info.body_sha_256_str),  &(edat.bodySha256Str));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.accum_sha_256_str), &(edat.accumSha256Str));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.sign),              &(eehash));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.sign_desc),         &(eedesc));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.method),            &(edat.method));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.from_uri_str),      &(edat.fromUriStr));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.to_uri_str),        &(edat.toUriStr));
            pj_strdup_with_null(desc->pool, &(desc->sign_info.req_uri_str),       &(edat.reqUriStr));

            // if errcode & EESIGN_FLAG_DROP_PACKET => drop packet
            PJ_LOG(4, (THIS_FILE, "Signature verification result: [%d]", errCode));
            if ((errCode & EESIGN_FLAG_DROP_PACKET) > 0) toReturn = PJ_TRUE;
        } else {
            PJ_LOG(2, (THIS_FILE, "No callback object registered"));
        }

        on_error:
        pj_pool_release(pool);
        return toReturn; /* Always return success, otherwise message will not get sent! */
    } else {
        return toReturn ;
    }

    return toReturn;
}

/* Notification on outgoing messages */
static pj_status_t sign_on_tx_msg(pjsip_tx_data *tdata)
{
    pjsip_method_e mthd;
    pj_bool_t isRequest;

    PJ_LOG(4, (THIS_FILE, "mod_sign_on_tx_msg"));
    if(tdata == NULL || tdata->msg == NULL){
        PJ_LOG(1, (THIS_FILE, "tdata or msg is null!"));
        return PJ_SUCCESS;
    }

    // real method can be determined from CSEQ, if it is response -> we have status message and line.req is not valid
    isRequest = tdata->msg->type == PJSIP_REQUEST_MSG;
    if (isRequest){
        mthd = tdata->msg->line.req.method.id;
    } else {
        if (tdata->msg->line.status.code!=200) return PJ_SUCCESS; // time saver - skip not interesting codes
        const pjsip_cseq_hdr *cseq = cseq = (const pjsip_cseq_hdr*) pjsip_msg_find_hdr(tdata->msg, PJSIP_H_CSEQ, NULL);
        if (cseq==NULL) return PJ_SUCCESS;	// CSEQ is missing -> not interesting
        mthd = cseq->method.id;
    }

    // INVITE and BYE methods are interesting
    if (mthd == PJSIP_INVITE_METHOD || mthd==PJSIP_BYE_METHOD){
        pj_pool_t* pool = NULL;
        PJ_LOG(4, (THIS_FILE, "INVITE or BYE method here, req: %d; objName: [%s]", isRequest, tdata->obj_name));
        if (isRequest==PJ_FALSE && mthd != PJSIP_INVITE_METHOD){
            // We are interested in INVITE 200 OK response, since it contains also ZRTP-HASH
            return PJ_SUCCESS;
        }

        // allocate new memory pool for subsequent memory allocations
        pool = pjsua_pool_create("signPoolTX", POOL_INIT_SIZE, POOL_INC_SIZE);
        if (pool==NULL){
            PJ_LOG(1, (THIS_FILE, "Cannot create new pool! initSize=%d", POOL_INIT_SIZE));
            return PJ_SUCCESS;
        }

        //
        // Obtain required parts of the message
        //
        esignInfo_t edat;
        get_eesign_data_from_msg(pool, tdata->msg, &edat);

        // allocate return string hash
        pj_str_t hash2append = {0,0};
        pj_str_t desc2append = {0,0};
        hash2append.ptr = (char*) pj_pool_zalloc(pool, sizeof(char) * 128);
        desc2append.ptr = (char*) pj_pool_zalloc(pool, sizeof(char) * 128);

        if (registeredCallbackObject!=NULL){
            hashReturn_t hret = {0,0,{hash2append.ptr,0},{desc2append.ptr,0}};

            pj_status_t hashStatus = registeredCallbackObject->sign(&edat, &hret);

            // hash should be returned here, null terminated
            PJ_LOG(4, (THIS_FILE, "Returned hash [%d] to append to message (signature): [%s] len=%d", hashStatus, hret.hash.ptr, hret.hash.slen));
            if (hashStatus == PJ_SUCCESS){
                if (hret.hash.ptr != NULL && hret.hash.slen>0){
                    sign_set_eehdr(tdata, EE_SIGN_ID, hret.hash.ptr);
                    PJ_LOG(4, (THIS_FILE, "EESIGN header added to the message [%.*s]", hret.hash.slen, hret.hash.ptr));
                }

                if (hret.desc.ptr != NULL && hret.desc.slen>0){
                    sign_set_eehdr(tdata, EE_SIGN_DESC_ID, hret.desc.ptr);
                    PJ_LOG(4, (THIS_FILE, "EESIGN-DESC header added to the message [%.*s]", hret.desc.slen, hret.desc.ptr));
                }
            }

        } else {
            PJ_LOG(2, (THIS_FILE, "No callback object registered!"));
        }

        on_error:
        pj_pool_release(pool);
        return PJ_SUCCESS; /* Always return success, otherwise message will not get sent! */
    } else {
        return PJ_SUCCESS;
    }
}

/**
* Module load()
*/
static pj_status_t mod_sign_load(pjsip_endpoint *endpt)
{
    // Tell to parser that we can handle EESIGN header now
    // pconst is not fully initialized, init NOT_NEWLINE now
    initParser();

    pj_status_t regSign = pjsip_register_hdr_parser(EESIGN_HDR,      NULL, &parse_hdr_EE_SIGN_string);
    pj_status_t regDesc = pjsip_register_hdr_parser(EESIGN_DESC_HDR, NULL, &parse_hdr_EE_DESC_string);
    if (regSign!=PJ_SUCCESS){
        PJ_LOG(1, (THIS_FILE, "Cannot register parsing function for [%s]", EESIGN_HDR));
    }

    if (regDesc!=PJ_SUCCESS){
        PJ_LOG(1, (THIS_FILE, "Cannot register parsing function for [%s]", EESIGN_DESC_HDR));
    }

    return PJ_SUCCESS;
}

/**
* Module unload()
*/
static pj_status_t mod_sign_unload(void)
{
    // unregister EEsign parser
    //pjsip_unregister_hdr_parser(EESIGN_HDR, NULL, &parse_hdr_generic_string);

    return PJ_SUCCESS;
}

/**
* Module init
*/
PJ_DECL(pj_status_t) mod_sign_init() {
    return pjsip_endpt_register_module(pjsua_get_pjsip_endpt(), &pjsua_sipsign_mod);
}
