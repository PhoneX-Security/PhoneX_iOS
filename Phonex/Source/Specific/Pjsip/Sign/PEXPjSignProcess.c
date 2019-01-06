//
//  PEXPjSignProcess.c
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#include "PEXPjSignProcess.h"
#define THIS_FILE "PEXPjSignProcess.c"

/* TODO : pass a max len for the line2 buffer */
pj_status_t pexsign_add_timestamp(pj_str_t* line2, pj_time_val ts)
{
    char* line2ptr = line2->ptr;
    line2ptr += line2->slen;

    // sec since epoch
    pj_utoa_pad(ts.sec, line2ptr, TIMESTAMP_SEC_LEN, '0');
    line2->slen += TIMESTAMP_SEC_LEN;
    line2ptr += TIMESTAMP_SEC_LEN;
    // dot
    pj_strcat2(line2, ".");
    line2ptr++;
    // ms
    pj_utoa_pad(ts.msec, line2ptr, TIMESTAMP_MSEC_LEN, '0');
    line2->slen += TIMESTAMP_MSEC_LEN;
    line2ptr += TIMESTAMP_MSEC_LEN;

    return PJ_SUCCESS;
}

pj_status_t pexsign_add_index(pj_str_t* line1, int value)
{
    value += 61; /*the headers index length + \n*/
    pj_val_to_hex_digit( (value & 0xFF00) >> 8, line1->ptr + line1->slen);
    pj_val_to_hex_digit( (value & 0x00FF),      line1->ptr + line1->slen + 2);
    line1->slen += 4;

    return PJ_SUCCESS;
}

pj_status_t pexsign_set_length(char* buf, int len)
{
    pj_val_to_hex_digit( (len & 0xFF0000) >> 16, buf);
    pj_val_to_hex_digit( (len & 0x00FF00) >> 8,  buf + 2);
    pj_val_to_hex_digit( (len & 0x0000FF),       buf + 4);

    return PJ_SUCCESS;
}

pj_status_t pexsign_add_cseq(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_cseq_hdr *cseq;
    char buf[128];
    cseq = (const pjsip_cseq_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CSEQ, NULL);
    pj_ansi_snprintf(buf, sizeof(buf), "%d %.*s", cseq->cseq, (int)cseq->method.name.slen, cseq->method.name.ptr);
    pj_strcat2(line2, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_status_code(pj_str_t* line2, pjsip_msg* msg)
{
    if(msg->type == PJSIP_RESPONSE_MSG) {
        char buf[128];
        pj_ansi_snprintf(buf, sizeof(buf), "%d", msg->line.status.code);
        pj_strcat2(line2, buf);
    } else {
        pj_strcat2(line2, "-");
    }
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_request_uri(pj_str_t* line2, pjsip_msg* msg)
{
    int len = 0;
    if(msg->line.req.uri != NULL ){
        len = pjsip_uri_print(PJSIP_URI_IN_REQ_URI,
                msg->line.req.uri,
                (line2->ptr + line2->slen),
                512);
    }
    line2->slen += len;
    if(len == 0){
        pj_strcat2(line2, "-");
    }
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_tx_destination(pj_str_t* line2, pjsip_tx_data *tdata)
{
    char buf[128];
    pj_ansi_snprintf(buf, sizeof(buf), "%s:%d",
            tdata->tp_info.dst_name,
            tdata->tp_info.dst_port);
    pj_strcat2(line2, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_tx_source(pj_str_t* line2, pjsip_tx_data *tdata)
{
    char buf[128];
    pj_sockaddr_print( &tdata->tp_info.transport->local_addr,
            buf, sizeof(buf),
            1);
    pj_strcat2(line2, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_rx_destination(pj_str_t* line2, pjsip_rx_data *rdata)
{
    char buf[128];
    pj_sockaddr_print( &rdata->tp_info.transport->local_addr,
            buf, sizeof(buf),
            1);
    pj_strcat2(line2, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_rx_source(pj_str_t* line2, pjsip_rx_data *rdata)
{
    char buf[128];
    pj_sockaddr_print( &rdata->pkt_info.src_addr,
            buf, sizeof(buf),
            1);
    pj_strcat2(line2, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_get_rx_source(pj_pool_t *pool, pj_str_t *dst, pjsip_rx_data *rdata){
    char buf[128];
    int len = 0;

    if (rdata==NULL) return PJ_EINVAL;
    pj_sockaddr_print( &rdata->pkt_info.src_addr,
            buf, sizeof(buf),
            1);
    pj_strdup2_with_null(pool, dst, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_fromto_url(pj_str_t* line2, const pjsip_fromto_hdr* fromto_hdr)
{
    int len = 0;
    if(fromto_hdr != NULL) {
        /*Use req uri context that does not add the display name and brackets stuff */
        len = pjsip_uri_print(PJSIP_URI_IN_REQ_URI,
                fromto_hdr->uri,
                (line2->ptr + line2->slen),
                512);
    }
    line2->slen += len;
    if(len == 0) {
        pj_strcat2(line2, "-");
    }
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_fromto_tag(pj_str_t* line2, const pjsip_fromto_hdr* fromto_hdr)
{
    if(fromto_hdr != NULL && fromto_hdr->tag.slen > 0) {
        pj_strcat(line2, &fromto_hdr->tag);
    } else {
        pj_strcat2(line2, "-");
    }
    return PJ_SUCCESS;
}

pj_status_t pexsign_add_to_uri(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_fromto_hdr *to = (const pjsip_fromto_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_TO, NULL);
    return pexsign_add_fromto_url(line2, to);
}

pj_status_t pexsign_add_to_tag(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_to_hdr *to = (const pjsip_to_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_TO, NULL);
    return pexsign_add_fromto_tag(line2, to);
}

pj_status_t pexsign_add_from_uri(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_to_hdr *from = (const pjsip_to_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_FROM, NULL);
    return pexsign_add_fromto_url(line2, from);
}

pj_status_t pexsign_add_from_tag(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_from_hdr *from = (const pjsip_from_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_FROM, NULL);
    return pexsign_add_fromto_tag(line2, from);
}

pj_status_t pexsign_add_call_id(pj_str_t* line2, pjsip_msg* msg)
{
    const pjsip_call_info_hdr *call_id = (const pjsip_call_info_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CALL_ID, NULL);
    if(call_id != NULL && call_id->hvalue.slen > 0) {
        pj_strcat(line2, &call_id->hvalue);
    } else {
        pj_strcat2(line2, "-");
    }
    return PJ_SUCCESS;
}

pj_status_t pexsign_get_cseq(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg)
{
    const pjsip_cseq_hdr *cseq;
    char buf[128];
    int strLen=0;

    pj_assert(pool != NULL && dst!=NULL && msg!=NULL);
    cseq = (const pjsip_cseq_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_CSEQ, NULL);
    if (cseq==NULL) return !PJ_SUCCESS;

    strLen = pj_ansi_snprintf(buf, sizeof(buf), "%d|%.*s", cseq->cseq, (int)cseq->method.name.slen, cseq->method.name.ptr);
    pj_strdup2_with_null(pool, dst, buf); // create destination string with exact size allocated from pool
    return PJ_SUCCESS;
}

pj_status_t pexsign_get_request_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg)
{
    int len = 0;
    char buf[256] = {0};

    pj_assert(pool != NULL && dst!=NULL && msg!=NULL);
    if(msg->line.req.uri != NULL && msg->line.req.uri->vptr != NULL && msg->line.req.uri->vptr->p_print != NULL){
        len = pjsip_uri_print(PJSIP_URI_IN_REQ_URI, msg->line.req.uri, buf, 256);
    }

    pj_strdup2_with_null(pool, dst, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_get_fromto_url(pj_pool_t * pool, pj_str_t * dst, const pjsip_fromto_hdr* fromto_hdr)
{
    int len = 0;
    char buf[256] = {0};

    pj_assert(pool != NULL && dst != NULL);
    if(fromto_hdr != NULL && fromto_hdr->uri != NULL && fromto_hdr->uri->vptr != NULL && fromto_hdr->uri->vptr->p_print != NULL) {
        /*Use req uri context that does not add the display name and brackets stuff */
        len = pjsip_uri_print(PJSIP_URI_IN_REQ_URI, fromto_hdr->uri, buf, 256);
    }

    pj_strdup2_with_null(pool, dst, buf);
    return PJ_SUCCESS;
}

pj_status_t pexsign_get_to_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg)
{
    const pjsip_fromto_hdr *to = (const pjsip_fromto_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_TO, NULL);
    return pexsign_get_fromto_url(pool, dst, to);
}

pj_status_t pexsign_get_from_uri(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg)
{
    const pjsip_fromto_hdr *from = (const pjsip_fromto_hdr*) pjsip_msg_find_hdr(msg, PJSIP_H_FROM, NULL);
    return pexsign_get_fromto_url(pool, dst, from);
}

/* Extracts body from message if any */
pj_status_t pexsign_get_body(pj_pool_t * pool, pj_str_t * dst, pjsip_msg* msg)
{
    int len = 0;
    char buf[4096] = {0};

    pj_assert(pool != NULL && dst!=NULL && msg!=NULL);
    if (msg->body==NULL || msg->body->print_body == NULL) return PJ_SUCCESS;
    msg->body->print_body(msg->body, buf, 4096);

    pj_strdup2_with_null(pool, dst, buf);
    return PJ_SUCCESS;
}

void bin_to_strhex(pj_pool_t * pool, unsigned char *bin, unsigned int binsz, pj_str_t * result){
    char          hex_str[]= "0123456789abcdef";
    unsigned int  i;

    result->slen = 0;
    result->ptr  = (char*) pj_pool_zalloc(pool, sizeof(char) * (binsz * 2 + 1)); // allocate with security margin
    if (result->ptr == NULL){
        PJ_LOG(2, (THIS_FILE, "Unable to allocate new memory of size=%d from pool: [%s] capacity=%d", binsz * 2 + 1, pool->obj_name, pool->capacity));
        return;
    }

    result->ptr[binsz * 2] = 0;
    result->slen = binsz * 2 + 1;

    if (!binsz)
        return;

    for (i = 0; i < binsz; i++){
        (result->ptr)[i * 2 + 0] = hex_str[bin[i] >> 4  ];
        (result->ptr)[i * 2 + 1] = hex_str[bin[i] & 0x0F];
    }
}
