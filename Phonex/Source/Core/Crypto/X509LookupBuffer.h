#include "openssl/x509_vfy.h"//
//  X509LookupBuffer.h
//  Phonex
//
//  Created by Dusan Klinec on 22.02.15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#ifndef __Phonex__X509LookupBuffer__
#define __Phonex__X509LookupBuffer__

#include <openssl/x509.h>

#ifdef    __cplusplus
extern "C" {
#endif
#define X509_L_BUF_LOAD    1
#define X509_LOOKUP_load_buf(x,name,type) \
        X509_LOOKUP_ctrl((x),X509_L_BUF_LOAD,(name),(long)(type),NULL)
X509_LOOKUP_METHOD *X509_LOOKUP_buffer(void);

int X509_load_cert_buf(X509_LOOKUP *ctx, BIO *in, int type);
int X509_load_crl_buf(X509_LOOKUP *ctx, BIO *in, int type);
int X509_load_cert_crl_buf(X509_LOOKUP *ctx, BIO *in, int type);
#ifdef    __cplusplus
}
#endif

#endif /* defined(__Phonex__X509LookupBuffer__) */
