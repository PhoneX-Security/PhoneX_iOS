//
//  PEXPjSignDefs.h
//  Phonex
//
//  Created by Dusan Klinec on 07.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef Phonex_PEXPjSignDefs____FILEEXTENSION___
#define Phonex_PEXPjSignDefs____FILEEXTENSION___

#import "../pexpj.h"
#import <pj/config_site.h>
#import <pjsua-lib/pjsua.h>

#define EESIGN_HDR "EE-Sign"
#define EESIGN_DESC_HDR "EE-Sign-Desc"
#define EESIGN_FLAG_DROP_PACKET 1024

typedef struct hashReturn_t_ {
    pj_status_t retStatus;
    int         errCode;
    pj_str_t    hash;
    pj_str_t    desc;
} hashReturn_t;

// all data required to compute signatures
typedef struct esignInfo_t_{
    pj_pool_t * pool;
    pj_bool_t isRequest;

    int cseqInt;
    pj_str_t method;
    int resp_status;

    pj_str_t cseqStr;
    pj_str_t reqUriStr;
    pj_str_t fromUriStr;
    pj_str_t toUriStr;
    pj_str_t bodyStr;
    pj_str_t bodySha256Str;
    pj_str_t accumStr;
    pj_str_t accumSha256Str;
    pj_str_t ip;
} esignInfo_t;

/**
* This enumeration represents packet processing result;
*/
typedef enum esign_process_state_e_
{
    ESIGN_PROCESS_STATE_NULL=0,	/**< Module didn't process this message.   */
            ESIGN_PROCESS_STATE_ERROR,	/**< Some critical error during processing.   */
            ESIGN_PROCESS_STATE_PROCESSED/**< Packet was processed .*/
} esign_process_state_e;

typedef enum esign_sign_err_e
{
    ESIGN_SIGN_ERR_SUCCESS = 0,	             /**< No error.   */
            ESIGN_SIGN_ERR_GENERIC,                  /**< Generic, unspecified error. */
            ESIGN_SIGN_ERR_VERSION_UNKNOWN,          /**< Unknown version in signature descriptor. */
            ESIGN_SIGN_ERR_LOCAL_USER_UNKNOWN,       /**< Local user not known (destination). */
            ESIGN_SIGN_ERR_REMOTE_USER_UNKNOWN,      /**< Remote user not found (source) */
            ESIGN_SIGN_ERR_REMOTE_USER_CERT_MISSING, /**< No certificate for remote user. */
            ESIGN_SIGN_ERR_REMOTE_USER_CERT_ERR,     /**< Certificate error for remote user. */
            ESIGN_SIGN_ERR_SIGNATURE_INVALID,        /**< Signature verification failed. */
            ESIGN_SIGN_ERR_MAX                       /**< Opaque value, maximum value (for int). */
}esign_sign_err_e;

typedef struct esign_process_info
{
    /*
     * State
     */
    esign_process_state_e process_state;    /**< State of processing of this packet */
    pj_bool_t             signature_present;/**< Is signature present in this packet ? */
    pj_int16_t            callback_return;  /**<Value returned by callback checking signature */
    esign_sign_err_e      verify_err;
    pj_bool_t             signature_valid;
    pj_bool_t             packet_dropped;

    /*
     * Information for high level application
     */
    pj_bool_t              is_request;
    pj_str_t               method;
    pj_int32_t             cseq_int;
    pj_str_t               cseq_str;
    pj_str_t               req_uri_str;
    pj_str_t               from_uri_str;
    pj_str_t               to_uri_str;
    pj_str_t               body_sha_256_str;
    pj_str_t               accum_sha_256_str;

    /*
     * State and status.
     */
    int				       status_code;    /**< Last status code seen. */
    //pj_str_t			   status_text;	   /**< Last reason phrase.    */

    /*
     * Signature info
     */
    pj_str_t               sign;
    pj_str_t               sign_desc;
} esign_process_info;

/**
* This structure describes SIP signature verification. Inspiration taken from
* sip_transaction.h structure
*/
typedef struct esign_descriptor
{
    /*
     * Administrivia
     */
    pj_pool_t              *pool;           /**< Pool owned by the descriptor. Points to the RX data pool */
    pjsip_module           *mod;	        /**< Transaction user.	    */
    pjsip_endpoint         *endpt;          /**< Endpoint instance.     */

    esign_process_info      sign_info;      /**< Signature verification info */

    /** Module specific data. */
    void		       *mod_data[PJSIP_MAX_MODULE];
} esign_descriptor;

/** EESign header. */
typedef pjsip_generic_string_hdr pjsip_eesign_hdr;

/** Create EESign header. */
#define pjsip_eesign_hdr_create pjsip_generic_string_hdr_create

// for header searching
typedef enum EE_extra_hdr_t_{
    EE_SIGN_ID = 0,
    EE_SIGN_DESC_ID
} EE_extra_hdr_t;

/**
* SignCallback method.
*/
struct SignCallback
{
    /**
    * Function call to sign data.
    *
    * @param sdata	Data being signed.
    * @param hash   Computed hash.
    * @return		Module should return PJ_SUCCESS to indicate success.
    */
    pj_status_t (*sign)(const esignInfo_t * sdata, hashReturn_t * hash);

    /**
    * Function call to verify signature.
    *
    * @param sdata       Data being signed.
    * @param signature   Computed hash.
    * @param desc
    * @return		     Module should return PJ_SUCCESS to indicate success.
    */
    int (*verifySign)(const esignInfo_t * sdata, const char * signature, const char * desc);
};

typedef struct SignCallback PEXSignCallback;

#endif
