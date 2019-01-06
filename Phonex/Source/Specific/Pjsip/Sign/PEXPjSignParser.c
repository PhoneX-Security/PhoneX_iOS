//
//  PEXPjSignParser.c
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#include "PEXPjSignParser.h"
#define THIS_FILE "PEXPjSignParser"

/* Parser constants - taken from sip_parser.c */
#define IS_NEWLINE(c)	((c)=='\r' || (c)=='\n')
#define IS_SPACE(c)	((c)==' ' || (c)=='\t')

static pjsip_parser_const_t pconst =
        {
                { "user", 4},	/* pjsip_USER_STR	*/
                { "method", 6},	/* pjsip_METHOD_STR	*/
                { "transport", 9},	/* pjsip_TRANSPORT_STR	*/
                { "maddr", 5 },	/* pjsip_MADDR_STR	*/
                { "lr", 2 },	/* pjsip_LR_STR		*/
                { "sip", 3 },	/* pjsip_SIP_STR	*/
                { "sips", 4 },	/* pjsip_SIPS_STR	*/
                { "tel", 3 },	/* pjsip_TEL_STR	*/
                { "branch", 6 },	/* pjsip_BRANCH_STR	*/
                { "ttl", 3 },	/* pjsip_TTL_STR	*/
                { "received", 8 },	/* pjsip_RECEIVED_STR	*/
                { "q", 1 },		/* pjsip_Q_STR		*/
                { "expires", 7 },	/* pjsip_EXPIRES_STR	*/
                { "tag", 3 },	/* pjsip_TAG_STR	*/
                { "rport", 5}	/* pjsip_RPORT_STR	*/
        };

/* Character Input Specification buffer. */
static pj_cis_buf_t cis_buf;		// do not care about eclipse error, definitions are in scanner.h included header files

pj_status_t initParser(){
    pj_status_t status;
    pj_cis_buf_init(&cis_buf);

    status = pj_cis_init(&cis_buf, &pconst.pjsip_NOT_NEWLINE);
    PJ_ASSERT_RETURN(status == PJ_SUCCESS, status);
    pj_cis_add_str(&pconst.pjsip_NOT_NEWLINE, "\r\n");
    pj_cis_invert(&pconst.pjsip_NOT_NEWLINE);

    PJ_LOG(4, (THIS_FILE, "Parser initialized successfully"));
    return status;
}

static pjsip_hdr* parse_hdr_EE( pjsip_parse_ctx *ctx, EE_extra_hdr_t htype)
{
    pjsip_generic_string_hdr *hdr;
    const char * eeHdrName = htype == EE_SIGN_ID ? EESIGN_HDR : EESIGN_DESC_HDR;
    pj_str_t hname         = {0,0};
    pj_strdup2(ctx->pool, &hname, eeHdrName);

    hdr = pjsip_generic_string_hdr_create(ctx->pool, &hname, NULL);
    parse_generic_string_hdr(hdr, ctx);
    return (pjsip_hdr*)hdr;
}

pjsip_hdr* parse_hdr_EE_SIGN_string( pjsip_parse_ctx *ctx )
{
    return parse_hdr_EE(ctx, EE_SIGN_ID);
}

pjsip_hdr* parse_hdr_EE_DESC_string( pjsip_parse_ctx *ctx )
{
    return parse_hdr_EE(ctx, EE_SIGN_DESC_ID);
}

/* Parse generic string header. */
static void parse_generic_string_hdr( pjsip_generic_string_hdr *hdr,
        pjsip_parse_ctx *ctx)
{
    pj_scanner *scanner = ctx->scanner;
    if (hdr==NULL) {
        PJ_LOG(2, (THIS_FILE, "header is null"));
        return;
    }
    hdr->hvalue.slen = 0;

    /* header may be mangled hence the loop */
    while (pj_cis_match(&pconst.pjsip_NOT_NEWLINE, *scanner->curptr)) {
        pj_str_t next, tmp;

        pj_scan_get( scanner, &pconst.pjsip_NOT_NEWLINE, &hdr->hvalue);

        if (pj_scan_is_eof(scanner) || IS_NEWLINE(*scanner->curptr))
            break;
        /* mangled, get next fraction */
        pj_scan_get( scanner, &pconst.pjsip_NOT_NEWLINE, &next);
        /* concatenate */
        tmp.ptr = (char*)pj_pool_alloc(ctx->pool, hdr->hvalue.slen + next.slen + 2);
        tmp.slen = 0;
        pj_strcpy(&tmp, &hdr->hvalue);
        pj_strcat2(&tmp, " ");
        pj_strcat(&tmp, &next);
        tmp.ptr[tmp.slen] = '\0';

        hdr->hvalue = tmp;
    }

    parse_hdr_end(scanner);
}

/* Parse ending of header. */
static void parse_hdr_end( pj_scanner *scanner )
{
    if (pj_scan_is_eof(scanner)) {
        ;   /* Do nothing. */
    } else if (*scanner->curptr == '&') {
        pj_scan_get_char(scanner);
    } else {
        pj_scan_get_newline(scanner);
    }
}
