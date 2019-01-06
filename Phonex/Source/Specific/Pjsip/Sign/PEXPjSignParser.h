//
//  PEXPjSignParser.h
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef __Phonex__PEXPjSignParser__
#define __Phonex__PEXPjSignParser__

#include "PEXPjSignDefs.h"
#include <stdio.h>

pj_status_t initParser();

static pjsip_hdr* parse_hdr_EE( pjsip_parse_ctx *ctx, EE_extra_hdr_t htype);

pjsip_hdr* parse_hdr_EE_SIGN_string( pjsip_parse_ctx *ctx );

pjsip_hdr* parse_hdr_EE_DESC_string( pjsip_parse_ctx *ctx );

/* Parse generic string header. */
static void parse_generic_string_hdr( pjsip_generic_string_hdr *hdr, pjsip_parse_ctx *ctx);

/* Parse ending of header. */
static void parse_hdr_end( pj_scanner *scanner );

#endif /* defined(__Phonex__PEXPjSignParser__) */
