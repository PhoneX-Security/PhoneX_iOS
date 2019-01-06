//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pjsua-lib/pjsua.h"

@class PEXUserPrivate;

#define PEX_PHONEX_SIP_USER_AGENT "PhoneX.iOS"

FOUNDATION_EXPORT const unsigned PEX_PJ_DEF_ACC_KA_INTERVAL;
FOUNDATION_EXPORT const unsigned PEX_PJ_DEF_ACC_REG_DELAY_BEFORE_REFRESH;
FOUNDATION_EXPORT const unsigned PEX_PJ_DEF_ACC_REG_TIMEOUT;
FOUNDATION_EXPORT const pj_uint32_t PEX_PJ_DEF_ACC_REGISTER_TSX_TIMEOUT;

FOUNDATION_EXPORT NSInteger PEX_PJ_DEF_TLS_KA;
FOUNDATION_EXPORT NSInteger PEX_PJ_DEF_TLS_NODELAY;
FOUNDATION_EXPORT NSInteger PEX_PJ_DEF_TLS_KA_IDLE;
FOUNDATION_EXPORT NSInteger PEX_PJ_DEF_TLS_KA_INTERVAL;

typedef struct libFactory {
    /**
    * Path to the shared library
    */
    pj_str_t shared_lib_path;

    /**
    * Name of the factory function to launch to init the codec
    */
    pj_str_t init_factory_name;
} libFactory;

@interface PEXPjConfig : NSObject  {
    pjsua_config _cfg;
    pjsua_logging_config _log_cfg;
    pjsua_media_config _media_cfg;

    // Transport configuration.
    pjsua_transport_config _udpCfg;
    pjsua_transport_config _tcpCfg;
    pjsua_transport_config _tlsCfg;
    pjsua_transport_config _udp6Cfg;
    pjsua_transport_config _tcp6Cfg;
    pjsua_transport_config _tls6Cfg;

    // PJSIP related settings.
    pj_pool_t	    *_pool;	    // Pool for the app used in binder code.

    // TURN
    pj_stun_auth_cred _turn_creds;

    // Audio codecs
    unsigned 		_extra_aud_codecs_cnt;
    libFactory 	    _extra_aud_codecs[64];

    // Video codecs
    unsigned 		_extra_vid_codecs_cnt;
    libFactory 	    _extra_vid_codecs[64];
    libFactory 	    _extra_vid_codecs_destroy[64];

    // About zrtp cfg
    pj_bool_t _default_use_zrtp;
    char _zid_file[512];
}

@property (nonatomic, weak) PEXUserPrivate * privData;

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;
+ (instancetype)configWithPrivData:(PEXUserPrivate *)privData;

-(pj_status_t) preparePool;
-(pj_status_t) releasePool;

/**
* Reset pool, do not release it.
* This is called when pjsua is destroyed. It cleans pool for us.
*/
-(pj_status_t) resetPool;
-(pj_pool_t *) memPool;
-(NSString *) getZrtpFile;

-(void) configureAll;
-(void) configureLogging: (pjsua_logging_config *) cfg;
-(void) configurePjsua: (pjsua_config *) cfg;
-(void) configurePjmedia: (pjsua_media_config *) cfg;
-(void) configureAccount: (pjsua_acc_config *)acc;
-(BOOL) configureAccount: (pjsua_acc_config *)acc withPrivData: (PEXUserPrivate *) privData error:(NSError **) pError;
-(void) configureTransports;

-(NSNumber *) configureLocalTransport:(pjsip_transport_type_e)type port:(int)port cfg: (pjsua_transport_config*) cfg;
-(NSNumber *) configureLocalAccount: (NSNumber *) transportId;
-(NSNumber *) configureLocalTransportAndAccount:(pjsip_transport_type_e)type port:(int)port cfg: (pjsua_transport_config*) cfg;
-(pj_status_t) setTurnCredentials: (NSString *) username password: (NSString *) password realm: (NSString *) realm
                        auth_cred: (pj_stun_auth_cred *) turn_auth_cred;

-(pjsua_config *) getPjsuaConfig;
-(pjsua_logging_config *) getLoggingConfig;
-(pjsua_media_config *) getMediaConfig;

-(BOOL) updateConfigFromServer:(NSDictionary *)settings privData:(PEXUserPrivate *)privData;
@end