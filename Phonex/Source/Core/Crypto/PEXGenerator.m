//
//  PEXCSRGenerator.m
//  Phonex
//
//  Created by Dusan Klinec on 18.09.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGenerator.h"
#import "PEXMemBIO.h"
#import <openssl/rsa.h>
#import <openssl/bio.h>
#import <openssl/x509.h>
#import <openssl/pem.h>
#import <openssl/dh.h>

@implementation PEXGenerator

+ (int) generateRSAKeyPair:(int)bits andRSA:(RSA **)rsa
{
    int             ret = 0;
    RSA             *r = NULL;
    BIGNUM          *bne = NULL;
    uint64_t   e = RSA_F4;

    // 1. generate rsa key.
    bne = BN_new();
    ret = BN_set_word(bne, (uint)e);
    if(ret != 1){
        goto free_all;
    }

    r = RSA_new();
    ret = RSA_generate_key_ex(r, bits, bne, NULL);
    if(ret != 1){
        goto free_all;
    }

    *rsa = r;
    BN_free(bne);
    return (ret == 1);

    // 2. free.
free_all:
    RSA_free(r);
    BN_free(bne);
    return (ret == 1);
}

+ (int) generateDhKeyPair: (DH *) dh
{
    return DH_generate_key(dh);
}

+ (X509_REQ *) generateCSRWith: (NSString*) CN andPubKey: (RSA*) pubKey
{
    X509_REQ *x509Req;
    EVP_PKEY *pk;
    X509_NAME *name=NULL;

    if ((x509Req=X509_REQ_new()) == NULL) {
        DDLogError(@"generateCSRWith: Cannot allocate new CSR");
        goto dealloc;
    }

    if ((pk=EVP_PKEY_new()) == NULL) {
        DDLogError(@"generateCSRWith: Cannot allocate new PKEY");
        goto dealloc;
    }

    if (!EVP_PKEY_set1_RSA(pk, pubKey)) {
        DDLogError(@"generateCSRWith: Cannot set RSA");
        if (pk!=NULL) {
            EVP_PKEY_free(pk);
            pk=NULL;
        }
        goto dealloc;
    }

    X509_REQ_set_version(x509Req, 1);
    X509_REQ_set_pubkey(x509Req, pk);
    name=X509_REQ_get_subject_name(x509Req);

    // This function creates and adds the entry.
    if (!X509_NAME_add_entry_by_txt(name,"emailAddress",
            MBSTRING_ASC, (unsigned char const *) [CN cStringUsingEncoding:NSASCIIStringEncoding], -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"CN",
            MBSTRING_ASC, (unsigned char const *) [CN cStringUsingEncoding:NSASCIIStringEncoding], -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"OU",
            MBSTRING_ASC, (unsigned char const *) "PhoneX", -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"O",
            MBSTRING_ASC, (unsigned char const *) "PhoneX", -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"L",
            MBSTRING_ASC, (unsigned char const *) "Gibraltar", -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"ST",
            MBSTRING_ASC, (unsigned char const *) "Gibraltar", -1, -1, 0)) goto dealloc;
    if (!X509_NAME_add_entry_by_txt(name,"C",
            MBSTRING_ASC, (unsigned char const *) "GI", -1, -1, 0)) goto dealloc;

    // CSR has to be signed with our private key.
    // Has to be done here, since fields were added.
    X509_REQ_sign(x509Req, pk, EVP_sha1());

    // Free public key set to CSR.
    if (pk!=NULL) {
        EVP_PKEY_free(pk);
        pk=NULL;
    }

    return x509Req;

dealloc:
    // Free X509_REQ object
    if (x509Req != NULL) {
        X509_REQ_free(x509Req);
        x509Req =NULL;
    }

    return nil;
}

@end
