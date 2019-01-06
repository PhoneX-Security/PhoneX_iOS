//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbUserProfile.h"
#import "PEXUtils.h"
#import "PEXDbUri.h"
#import "PEXDbContentProvider.h"
#import "PEXModelHelper.h"

NSString * PEX_DBUSR_CRED_SCHEME_DIGEST = @"Digest";
NSString * PEX_DBUSR_CRED_SCHEME_PGP = @"PGP";
NSString * PEX_DBUSR_PROXIES_SEPARATOR = @"|";
NSString * PEX_DBUSR_ACCOUNTS_TABLE_NAME = @"accounts";
NSString * PEX_DBUSR_ACCOUNTS_STATUS_TABLE_NAME = @"accounts_status";

NSString * PEX_DBUSR_FIELD_ID = @"id";
NSString * PEX_DBUSR_FIELD_ACTIVE = @"active";
NSString * PEX_DBUSR_FIELD_ACCOUNT_MANAGER = @"wizard";
NSString * PEX_DBUSR_FIELD_DISPLAY_NAME = @"display_name";
NSString * PEX_DBUSR_FIELD_PRIORITY = @"priority";
NSString * PEX_DBUSR_FIELD_ACC_ID = @"acc_id";
NSString * PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA = @"wizard_data";
NSString * PEX_DBUSR_FIELD_REG_URI = @"reg_uri";
NSString * PEX_DBUSR_FIELD_MWI_ENABLED = @"mwi_enabled";
NSString * PEX_DBUSR_FIELD_PUBLISH_ENABLED = @"publish_enabled";
NSString * PEX_DBUSR_FIELD_REG_TIMEOUT = @"reg_timeout";
NSString * PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH = @"reg_dbr";
NSString * PEX_DBUSR_FIELD_KA_INTERVAL = @"ka_interval";
NSString * PEX_DBUSR_FIELD_PIDF_TUPLE_ID = @"pidf_tuple_id";
NSString * PEX_DBUSR_FIELD_FORCE_CONTACT = @"force_contact";
NSString * PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE = @"allow_contact_rewrite";
NSString * PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD = @"contact_rewrite_method";
NSString * PEX_DBUSR_FIELD_CONTACT_PARAMS = @"contact_params";
NSString * PEX_DBUSR_FIELD_CONTACT_URI_PARAMS = @"contact_uri_params";
NSString * PEX_DBUSR_FIELD_TRANSPORT = @"transport";
NSString * PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME = @"default_uri_scheme";
NSString * PEX_DBUSR_FIELD_USE_SRTP = @"use_srtp";
NSString * PEX_DBUSR_FIELD_USE_ZRTP = @"use_zrtp";
NSString * PEX_DBUSR_FIELD_PROXY = @"proxy";
NSString * PEX_DBUSR_FIELD_REG_USE_PROXY = @"reg_use_proxy";
NSString * PEX_DBUSR_FIELD_REALM = @"realm";
NSString * PEX_DBUSR_FIELD_SCHEME = @"scheme";
NSString * PEX_DBUSR_FIELD_USERNAME = @"username";
NSString * PEX_DBUSR_FIELD_DATATYPE = @"datatype";
NSString * PEX_DBUSR_FIELD_PASSWORD = @"data";
NSString * PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH = @"initial_auth";
NSString * PEX_DBUSR_FIELD_AUTH_ALGO = @"auth_algo";
NSString * PEX_DBUSR_FIELD_SIP_STACK = @"sip_stack";
NSString * PEX_DBUSR_FIELD_VOICE_MAIL_NBR = @"vm_nbr";
NSString * PEX_DBUSR_FIELD_ANDROID_GROUP = @"android_group";
NSString * PEX_DBUSR_FIELD_USE_RFC5626 = @"use_rfc5626";
NSString * PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID = @"rfc5626_instance_id";
NSString * PEX_DBUSR_FIELD_RFC5626_REG_ID = @"rfc5626_reg_id";
NSString * PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW = @"vid_in_auto_show";
NSString * PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT = @"vid_out_auto_transmit";
NSString * PEX_DBUSR_FIELD_RTP_PORT = @"rtp_port";
NSString * PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR = @"rtp_public_addr";
NSString * PEX_DBUSR_FIELD_RTP_BOUND_ADDR = @"rtp_bound_addr";
NSString * PEX_DBUSR_FIELD_RTP_ENABLE_QOS = @"rtp_enable_qos";
NSString * PEX_DBUSR_FIELD_RTP_QOS_DSCP = @"rtp_qos_dscp";
NSString * PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS = @"try_clean_reg";
NSString * PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE = @"allow_via_rewrite";
NSString * PEX_DBUSR_FIELD_SIP_STUN_USE = @"sip_stun_use";
NSString * PEX_DBUSR_FIELD_MEDIA_STUN_USE = @"media_stun_use";
NSString * PEX_DBUSR_FIELD_ICE_CFG_USE = @"ice_cfg_use";
NSString * PEX_DBUSR_FIELD_ICE_CFG_ENABLE = @"ice_cfg_enable";
NSString * PEX_DBUSR_FIELD_TURN_CFG_USE = @"turn_cfg_use";
NSString * PEX_DBUSR_FIELD_TURN_CFG_ENABLE = @"turn_cfg_enable";
NSString * PEX_DBUSR_FIELD_TURN_CFG_SERVER = @"turn_cfg_server";
NSString * PEX_DBUSR_FIELD_TURN_CFG_USER = @"turn_cfg_user";
NSString * PEX_DBUSR_FIELD_TURN_CFG_PASSWORD = @"turn_cfg_pwd";
NSString * PEX_DBUSR_FIELD_IPV6_MEDIA_USE = @"ipv6_media_use";
NSString * PEX_DBUSR_FIELD_CERT_PATH = @"cert_path";
NSString * PEX_DBUSR_FIELD_CERT_NOT_BEFORE = @"cert_not_before";
NSString * PEX_DBUSR_FIELD_CERT_HASH = @"cert_hash";
NSString * PEX_DBUSR_FIELD_XMPP_SERVER = @"xmpp_server";
NSString * PEX_DBUSR_FIELD_XMPP_SERVICE = @"xmpp_service";
NSString * PEX_DBUSR_FIELD_XMPP_USER_NAME = @"xmpp_user_name";
NSString * PEX_DBUSR_FIELD_XMPP_PASSWORD = @"xmpp_password";
NSString * PEX_DBUSR_FIELD_RECOVERY_EMAIL = @"recovery_email";

NSString * const PEX_DBUSR_FIELD_LICENSE_TYPE = @"license_type";
NSString * const PEX_DBUSR_FIELD_LICENSE_ISSUED_ON = @"license_issued_on";
NSString * const PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON = @"license_expires_on";
NSString * const PEX_DBUSR_FIELD_LICENSE_EXPIRED = @"license_expired";

NSString * PEX_DBUSR_DATE_FORMAT = @"YYYY-MM-DD HH:MM:SS.SSS";

@implementation PEXDbUserProfile {

}

+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString * createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
            "  %@  INTEGER PRIMARY KEY AUTOINCREMENT,"//  				 PEX_DBUSR_FIELD_ID
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_ACTIVE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_ACCOUNT_MANAGER
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_DISPLAY_NAME
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_PRIORITY
            "  %@  TEXT NOT NULL,"//  			 PEX_DBUSR_FIELD_ACC_ID
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_REG_URI
            "  %@  BOOLEAN,"//  				 PEX_DBUSR_FIELD_MWI_ENABLED
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_PUBLISH_ENABLED
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_REG_TIMEOUT
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_KA_INTERVAL
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_PIDF_TUPLE_ID
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_FORCE_CONTACT
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_CONTACT_PARAMS
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_CONTACT_URI_PARAMS
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_TRANSPORT
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_USE_SRTP
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_USE_ZRTP
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_PROXY
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_REG_USE_PROXY
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_REALM
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_SCHEME
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_USERNAME
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_DATATYPE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_PASSWORD
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_AUTH_ALGO
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_SIP_STACK
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_VOICE_MAIL_NBR
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH
            "  %@  INTEGER,"//  				 PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS
            "  %@  INTEGER DEFAULT 1,"//  		 PEX_DBUSR_FIELD_USE_RFC5626
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_RFC5626_REG_ID
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_RTP_PORT
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_RTP_ENABLE_QOS
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_RTP_QOS_DSCP
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_RTP_BOUND_ADDR
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_ANDROID_GROUP
            "  %@  INTEGER DEFAULT 0,"//  		 PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_SIP_STUN_USE
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_MEDIA_STUN_USE
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_ICE_CFG_USE
            "  %@  INTEGER DEFAULT 0,"//  		 PEX_DBUSR_FIELD_ICE_CFG_ENABLE
            "  %@  INTEGER DEFAULT -1,"//  		 PEX_DBUSR_FIELD_TURN_CFG_USE
            "  %@  INTEGER DEFAULT 0,"//  		 PEX_DBUSR_FIELD_TURN_CFG_ENABLE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_TURN_CFG_SERVER
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_TURN_CFG_USER
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_TURN_CFG_PASSWORD
            "  %@  INTEGER DEFAULT 0,"//  		 PEX_DBUSR_FIELD_IPV6_MEDIA_USE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_CERT_PATH
            "  %@  NUMERIC DEFAULT 0,"//  		 PEX_DBUSR_FIELD_CERT_NOT_BEFORE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_CERT_HASH
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_XMPP_SERVER
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_XMPP_SERVICE
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_XMPP_USER_NAME
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_XMPP_PASSWORD
            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_RECOVERY_EMAIL

            "  %@  TEXT,"//  				     PEX_DBUSR_FIELD_LICENSE_TYPE
            "  %@  NUMERIC DEFAULT 0,"//  		 PEX_DBUSR_FIELD_LICENSE_ISSUED_ON
            "  %@  NUMERIC DEFAULT 0,"//  		 PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON
            "  %@  INTEGER DEFAULT 0"//  		 PEX_DBUSR_FIELD_LICENSE_EXPIRED
            ");", PEX_DBUSR_ACCOUNTS_TABLE_NAME,
                    PEX_DBUSR_FIELD_ID,
                    PEX_DBUSR_FIELD_ACTIVE,
                    PEX_DBUSR_FIELD_ACCOUNT_MANAGER,
                    PEX_DBUSR_FIELD_DISPLAY_NAME,
                    PEX_DBUSR_FIELD_PRIORITY,
                    PEX_DBUSR_FIELD_ACC_ID,
                    PEX_DBUSR_FIELD_REG_URI,
                    PEX_DBUSR_FIELD_MWI_ENABLED,
                    PEX_DBUSR_FIELD_PUBLISH_ENABLED,
                    PEX_DBUSR_FIELD_REG_TIMEOUT,
                    PEX_DBUSR_FIELD_KA_INTERVAL,
                    PEX_DBUSR_FIELD_PIDF_TUPLE_ID,
                    PEX_DBUSR_FIELD_FORCE_CONTACT,
                    PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE,
                    PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD,
                    PEX_DBUSR_FIELD_CONTACT_PARAMS,
                    PEX_DBUSR_FIELD_CONTACT_URI_PARAMS,
                    PEX_DBUSR_FIELD_TRANSPORT,
                    PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME,
                    PEX_DBUSR_FIELD_USE_SRTP,
                    PEX_DBUSR_FIELD_USE_ZRTP,
                    PEX_DBUSR_FIELD_PROXY,
                    PEX_DBUSR_FIELD_REG_USE_PROXY,
                    PEX_DBUSR_FIELD_REALM,
                    PEX_DBUSR_FIELD_SCHEME,
                    PEX_DBUSR_FIELD_USERNAME,
                    PEX_DBUSR_FIELD_DATATYPE,
                    PEX_DBUSR_FIELD_PASSWORD,
                    PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH,
                    PEX_DBUSR_FIELD_AUTH_ALGO,
                    PEX_DBUSR_FIELD_SIP_STACK,
                    PEX_DBUSR_FIELD_VOICE_MAIL_NBR,
                    PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH,
                    PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS,
                    PEX_DBUSR_FIELD_USE_RFC5626,
                    PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID,
                    PEX_DBUSR_FIELD_RFC5626_REG_ID,
                    PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW,
                    PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT,
                    PEX_DBUSR_FIELD_RTP_PORT,
                    PEX_DBUSR_FIELD_RTP_ENABLE_QOS,
                    PEX_DBUSR_FIELD_RTP_QOS_DSCP,
                    PEX_DBUSR_FIELD_RTP_BOUND_ADDR,
                    PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR,
                    PEX_DBUSR_FIELD_ANDROID_GROUP,
                    PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE,
                    PEX_DBUSR_FIELD_SIP_STUN_USE,
                    PEX_DBUSR_FIELD_MEDIA_STUN_USE,
                    PEX_DBUSR_FIELD_ICE_CFG_USE,
                    PEX_DBUSR_FIELD_ICE_CFG_ENABLE,
                    PEX_DBUSR_FIELD_TURN_CFG_USE,
                    PEX_DBUSR_FIELD_TURN_CFG_ENABLE,
                    PEX_DBUSR_FIELD_TURN_CFG_SERVER,
                    PEX_DBUSR_FIELD_TURN_CFG_USER,
                    PEX_DBUSR_FIELD_TURN_CFG_PASSWORD,
                    PEX_DBUSR_FIELD_IPV6_MEDIA_USE,
                    PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA,
                    PEX_DBUSR_FIELD_CERT_PATH,
                    PEX_DBUSR_FIELD_CERT_NOT_BEFORE,
                    PEX_DBUSR_FIELD_CERT_HASH,
                    PEX_DBUSR_FIELD_XMPP_SERVER,
                    PEX_DBUSR_FIELD_XMPP_SERVICE,
                    PEX_DBUSR_FIELD_XMPP_USER_NAME,
                    PEX_DBUSR_FIELD_XMPP_PASSWORD,
                    PEX_DBUSR_FIELD_RECOVERY_EMAIL,

                    PEX_DBUSR_FIELD_LICENSE_TYPE,
                    PEX_DBUSR_FIELD_LICENSE_ISSUED_ON,
                    PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON,
                    PEX_DBUSR_FIELD_LICENSE_EXPIRED
        ];
    });
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[PEX_DBUSR_FIELD_ID,
                // Application relative fields
                PEX_DBUSR_FIELD_ACTIVE, PEX_DBUSR_FIELD_ACCOUNT_MANAGER, PEX_DBUSR_FIELD_DISPLAY_NAME,
                PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA,

                // pjsua_acc_config fields
                PEX_DBUSR_FIELD_PRIORITY, PEX_DBUSR_FIELD_ACC_ID, PEX_DBUSR_FIELD_REG_URI,
                PEX_DBUSR_FIELD_MWI_ENABLED, PEX_DBUSR_FIELD_PUBLISH_ENABLED, PEX_DBUSR_FIELD_REG_TIMEOUT, PEX_DBUSR_FIELD_KA_INTERVAL,
                PEX_DBUSR_FIELD_PIDF_TUPLE_ID,
                PEX_DBUSR_FIELD_FORCE_CONTACT, PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE, PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD,
                PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE,
                PEX_DBUSR_FIELD_CONTACT_PARAMS, PEX_DBUSR_FIELD_CONTACT_URI_PARAMS,
                PEX_DBUSR_FIELD_TRANSPORT, PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME, PEX_DBUSR_FIELD_USE_SRTP, PEX_DBUSR_FIELD_USE_ZRTP,
                PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH,

                // RTP config
                PEX_DBUSR_FIELD_RTP_PORT, PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR, PEX_DBUSR_FIELD_RTP_BOUND_ADDR,
                PEX_DBUSR_FIELD_RTP_ENABLE_QOS, PEX_DBUSR_FIELD_RTP_QOS_DSCP,

                // Proxy infos
                PEX_DBUSR_FIELD_PROXY, PEX_DBUSR_FIELD_REG_USE_PROXY,

                // Credentials.
                PEX_DBUSR_FIELD_REALM, PEX_DBUSR_FIELD_SCHEME, PEX_DBUSR_FIELD_USERNAME, PEX_DBUSR_FIELD_DATATYPE,
                PEX_DBUSR_FIELD_PASSWORD,

                PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH, PEX_DBUSR_FIELD_AUTH_ALGO,

                // Stack options.
                PEX_DBUSR_FIELD_SIP_STACK, PEX_DBUSR_FIELD_VOICE_MAIL_NBR,
                PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS, PEX_DBUSR_FIELD_ANDROID_GROUP,

                // RFC 5626
                PEX_DBUSR_FIELD_USE_RFC5626, PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID, PEX_DBUSR_FIELD_RFC5626_REG_ID,

                // Video
                PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW, PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT,

                // STUN, ICE, TURN
                PEX_DBUSR_FIELD_SIP_STUN_USE, PEX_DBUSR_FIELD_MEDIA_STUN_USE,
                PEX_DBUSR_FIELD_ICE_CFG_USE, PEX_DBUSR_FIELD_ICE_CFG_ENABLE,
                PEX_DBUSR_FIELD_TURN_CFG_USE, PEX_DBUSR_FIELD_TURN_CFG_ENABLE, PEX_DBUSR_FIELD_TURN_CFG_SERVER, PEX_DBUSR_FIELD_TURN_CFG_USER, PEX_DBUSR_FIELD_TURN_CFG_PASSWORD,

                PEX_DBUSR_FIELD_IPV6_MEDIA_USE,

                // Certificate for the user
                PEX_DBUSR_FIELD_CERT_PATH, PEX_DBUSR_FIELD_CERT_NOT_BEFORE, PEX_DBUSR_FIELD_CERT_HASH,

                // XMPP related
                PEX_DBUSR_FIELD_XMPP_SERVER, PEX_DBUSR_FIELD_XMPP_SERVICE,
                PEX_DBUSR_FIELD_XMPP_USER_NAME, PEX_DBUSR_FIELD_XMPP_PASSWORD,

                // Recovery email
                PEX_DBUSR_FIELD_RECOVERY_EMAIL,

                // Licence related
                PEX_DBUSR_FIELD_LICENSE_TYPE, PEX_DBUSR_FIELD_LICENSE_ISSUED_ON,
                PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON, PEX_DBUSR_FIELD_LICENSE_EXPIRED


        ];
    });
    return fullProjection;
}

+(NSArray *) getAccProjection {
    static dispatch_once_t once;
    static NSArray * accProjection;
    dispatch_once(&once, ^{
        accProjection = @[PEX_DBUSR_FIELD_ID,
                PEX_DBUSR_FIELD_ACC_ID, // Needed for default domain
                PEX_DBUSR_FIELD_REG_URI, // Needed for default domain
                PEX_DBUSR_FIELD_PROXY, // Needed for default domain
                PEX_DBUSR_FIELD_TRANSPORT, // Needed for default scheme
                PEX_DBUSR_FIELD_DISPLAY_NAME,
                PEX_DBUSR_FIELD_ACCOUNT_MANAGER,
                PEX_DBUSR_FIELD_PUBLISH_ENABLED];
    });
    return accProjection;
}

+(NSArray *) getListableProjection {
    static dispatch_once_t once;
    static NSArray * listableProjection;
    dispatch_once(&once, ^{
        listableProjection = @[PEX_DBUSR_FIELD_ID,
                PEX_DBUSR_FIELD_ACC_ID,
                PEX_DBUSR_FIELD_ACTIVE,
                PEX_DBUSR_FIELD_DISPLAY_NAME,
                PEX_DBUSR_FIELD_ACCOUNT_MANAGER,
                PEX_DBUSR_FIELD_PRIORITY,
                PEX_DBUSR_FIELD_REG_URI];
    });
    return listableProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBUSR_ACCOUNTS_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBUSR_ACCOUNTS_TABLE_NAME isBase:YES];
    });
    return uriBase;
}

+ (NSArray *)loadFromDatabase:(PEXDbContentProvider *)cr selection:(NSString *)selection selectionArgs:(NSArray *)selectionArs projection:(NSArray *)projection sortOrder:(NSString *)sortOrder {
    PEXDbCursor * c = [cr query: [self getURI]
                     projection: projection == nil || projection.count == 0 ? [self getFullProjection] : projection
                      selection: selection == nil ? @"" : selection
                  selectionArgs: selectionArs == nil ? @[] : selectionArs
                      sortOrder: sortOrder == nil ? @"" : sortOrder];
    if (c==nil){
        return @[];
    }

    int num = c.getCount;
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:num];
    for(int i=0; i<num && [c moveToNext]; i++){
        PEXDbUserProfile * curProfile = [[self alloc] init];
        [curProfile createFromCursor:c];
        [arr addObject:curProfile];
    }

    return arr;
}

+ (PEXDbUserProfile *)getProfileFromDbId:(PEXDbContentProvider *)cr id:(NSNumber *)id1 projection:(NSArray *)projection {
    PEXDbCursor * c = [cr query: [self getURI]
                     projection: projection == nil || projection.count == 0 ? [self getFullProjection] : projection
                      selection: [NSString stringWithFormat:@" WHERE %@=?", PEX_DBUSR_FIELD_ID]
                  selectionArgs: @[[NSString stringWithFormat:@"%lld", [id1 longLongValue]]]
                      sortOrder: @""];

    if (c==nil || c.getCount == 0 || !c.moveToFirst){
        return nil;
    }

    PEXDbUserProfile * curProfile = [[self alloc] init];
    [curProfile createFromCursor:c];
    return curProfile;
}

+ (PEXDbUserProfile *)getProfileWithName: (NSString *) name cr: (PEXDbContentProvider *)cr projection:(NSArray *)projection {
    PEXDbCursor * c = [cr query: [self getURI]
                     projection: projection == nil || projection.count == 0 ? [self getFullProjection] : projection
                      selection: [NSString stringWithFormat:@" WHERE %@=?", PEX_DBUSR_FIELD_USERNAME]
                  selectionArgs: @[name]
                      sortOrder: @""];

    if (c==nil || c.getCount == 0 || ![c moveToFirst]){
        return nil;
    }

    PEXDbUserProfile * curProfile = [[self alloc] init];
    [curProfile createFromCursor:c];
    return curProfile;
}

+ (void)setDefaultValues:(PEXDbUserProfile *)account {
    account.use_srtp = @(0);
    account.use_zrtp = @(1);
    account.transport = @(3); // TLS. TODO: add to static presets.
    account.acc_id = [NSString stringWithFormat:@"%@%@%@>",
                    account.display_name,
                    ([account.transport isEqualToNumber:@(3)] ? @" <sips:" : @"<sip:"),
                    account.username];

    // Default URI is important for calling and messaging.
    // If contact has empty scheme (no sip:, sips:), this scheme
    // is automatically prepended.
    account.default_uri_scheme = [account.transport isEqualToNumber:@(3)] ? @"sips" : @"sip";

    account.publish_enabled = @(0);
    account.ice_cfg_use = @(1);
    account.ice_cfg_enable = @(1);
    account.media_stun_use = @(1);
    account.sip_stun_use = @(1);
    account.turn_cfg_enable = @(1);
    account.turn_cfg_use = @(1);

    // TODO: add to static presets
    NSArray * nameParts = [account.username componentsSeparatedByString:@"@"];
    NSString * domain = nameParts[1];

    // Turn server
    account.turn_cfg_server = [NSString stringWithFormat:@"turn.%@", domain];

    //
    // Static values here
    //

    // Just 5 minutes for SIP REGISTER, long registration causes problems
    // problems in case of connection drops - blind registrations
    account.reg_timeout = @(300);
    account.proxies = nil;
    account.try_clean_registers = @(1);
    account.scheme = PEX_DBUSR_CRED_SCHEME_DIGEST;
    account.datatype = @(PEX_DBUSR_CRED_DATA_PLAIN_PASSWD);
    account.realm = domain;

    // reg uri depends on port choosen
    if ([account.transport isEqualToNumber:@(3)]){
        account.reg_uri = [NSString stringWithFormat: @"sips:%@:5061", domain];
    } else {
        account.reg_uri = [NSString stringWithFormat: @"sip:%@:5060", domain];
    }
}


- (instancetype)init {
    if (self = [super init]) {
        self.primaryKey = nil;
        self.id = @(PEX_DBUSR_INVALID_ID);
        self.display_name = @"";
        self.accountManager = nil;
        self.transport = @(0);
        self.default_uri_scheme = @"sip";
        self.active = YES;
        self.priority = @(100);
        self.acc_id = nil;
        self.reg_uri = nil;
        self.publish_enabled = @(0);
        self.reg_timeout = @(900);
        self.ka_interval = @(0);
        self.pidf_tuple_id = nil;
        self.force_contact = nil;
        self.allow_contact_rewrite = YES;
        self.contact_rewrite_method = @(2);
        self.allow_via_rewrite = NO;
        self.proxies = nil;
        self.realm = nil;
        self.username = nil;
        self.scheme = nil;
        self.datatype = @(0);
        self.data = nil;
        self.initial_auth = NO;
        self.auth_algo = @"";
        self.use_srtp = @(-1);
        self.use_zrtp = @(-1);
        self.reg_use_proxy = @(3);
        self.sip_stack = @(PEX_DBUSR_PJSIP_STACK);
        self.vm_nbr = nil;
        self.reg_delay_before_refresh = @(-1);
        self.try_clean_registers = @(1);
        self.icon = nil;
        self.use_rfc5626 = YES;
        self.rfc5626_instance_id = @"";
        self.rfc5626_reg_id = @"";
        self.vid_in_auto_show = @(-1);
        self.vid_out_auto_transmit = @(-1);
        self.rtp_port = @(-1);
        self.rtp_public_addr = @"";
        self.rtp_bound_addr = @"";
        self.rtp_enable_qos = @(-1);
        self.rtp_qos_dscp = @(-1);
        self.android_group = @"";
        self.mwi_enabled = YES;
        self.sip_stun_use = @(-1);
        self.media_stun_use = @(-1);
        self.ice_cfg_use = @(-1);
        self.ice_cfg_enable = @(0);
        self.turn_cfg_use = @(-1);
        self.turn_cfg_enable = @(0);
        self.turn_cfg_server = @"";
        self.turn_cfg_user = @"";
        self.turn_cfg_password = @"";
        self.ipv6_media_use = @(0);
        self.wizard_data = @"";
        self.cert_path = @"";
        self.cert_not_before = [NSDate dateWithTimeIntervalSince1970:0.0];
        self.cert_hash = @"";
    }
    return self;
}

- (void)copyAllFieldsTo:(PEXDbUserProfile *)other {
    //[super copyAllFieldsTo:other];
    other.acc_id = self.acc_id;
    other.accountManager = self.accountManager;
    other.active = self.active;
    other.allow_contact_rewrite = self.allow_contact_rewrite;
    other.allow_via_rewrite = self.allow_via_rewrite;
    other.android_group = self.android_group;
    other.auth_algo = self.auth_algo;
    other.cert_hash = self.cert_hash;
    other.cert_not_before = self.cert_not_before;
    other.cert_path = self.cert_path;
    other.contact_rewrite_method = self.contact_rewrite_method;
    other.data = self.data;
    other.datatype = self.datatype;
    other.default_uri_scheme = self.default_uri_scheme;
    other.display_name = self.display_name;
    other.force_contact = self.force_contact;
    other.ice_cfg_enable = self.ice_cfg_enable;
    other.ice_cfg_use = self.ice_cfg_use;
    other.icon = self.icon;
    other.id = self.id;
    other.initial_auth = self.initial_auth;
    other.ipv6_media_use = self.ipv6_media_use;
    other.ka_interval = self.ka_interval;
    other.media_stun_use = self.media_stun_use;
    other.mwi_enabled = self.mwi_enabled;
    other.pidf_tuple_id = self.pidf_tuple_id;
    other.primaryKey = self.primaryKey;
    other.priority = self.priority;
    other.proxies = self.proxies;
    other.publish_enabled = self.publish_enabled;
    other.realm = self.realm;
    other.reg_delay_before_refresh = self.reg_delay_before_refresh;
    other.reg_timeout = self.reg_timeout;
    other.reg_uri = self.reg_uri;
    other.reg_use_proxy = self.reg_use_proxy;
    other.rfc5626_instance_id = self.rfc5626_instance_id;
    other.rfc5626_reg_id = self.rfc5626_reg_id;
    other.rtp_bound_addr = self.rtp_bound_addr;
    other.rtp_enable_qos = self.rtp_enable_qos;
    other.rtp_port = self.rtp_port;
    other.rtp_public_addr = self.rtp_public_addr;
    other.rtp_qos_dscp = self.rtp_qos_dscp;
    other.scheme = self.scheme;
    other.sip_stack = self.sip_stack;
    other.sip_stun_use = self.sip_stun_use;
    other.transport = self.transport;
    other.try_clean_registers = self.try_clean_registers;
    other.turn_cfg_enable = self.turn_cfg_enable;
    other.turn_cfg_password = self.turn_cfg_password;
    other.turn_cfg_server = self.turn_cfg_server;
    other.turn_cfg_use = self.turn_cfg_use;
    other.turn_cfg_user = self.turn_cfg_user;
    other.use_rfc5626 = self.use_rfc5626;
    other.use_srtp = self.use_srtp;
    other.use_zrtp = self.use_zrtp;
    other.username = self.username;
    other.vid_in_auto_show = self.vid_in_auto_show;
    other.vid_out_auto_transmit = self.vid_out_auto_transmit;
    other.vm_nbr = self.vm_nbr;
    other.wizard_data = self.wizard_data;
    other.xmpp_password = self.xmpp_password;
    other.xmpp_server = self.xmpp_server;
    other.xmpp_service = self.xmpp_service;
    other.xmpp_user = self.xmpp_user;

    other.licenseType = self.licenseType;
    other.licenseIssuedOn = self.licenseIssuedOn;
    other.licenseExpiresOn = self.licenseExpiresOn;
    other.licenseExpired = self.licenseExpired;
}

/**
* Transform pjsua_acc_config into ContentValues that can be insert into
* database. <br/>
* Take care that if your SipProfile is incomplete this content value may
* also be incomplete and lead to override unwanted values of the existing
* database. <br/>
* So if updating, take care on what you actually want to update instead of
* using this utility method.
*
* @return Complete content values from the current wrapper around sip
*         profile.
*/
-(PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];

    if (_id!=nil && [_id longLongValue] != PEX_DBUSR_INVALID_ID) {
        [args put:PEX_DBUSR_FIELD_ID NSNumberAsLongLong:_id];
    }

    [args put:PEX_DBUSR_FIELD_ACTIVE NSNumberAsInt: @(_active ? 1 : 0)];
    if (_accountManager != nil)
         [args put:PEX_DBUSR_FIELD_ACCOUNT_MANAGER string: _accountManager];
    if (_display_name != nil)
         [args put:PEX_DBUSR_FIELD_DISPLAY_NAME string: _display_name];
    if (_transport != nil)
         [args put:PEX_DBUSR_FIELD_TRANSPORT NSNumberAsInt: _transport];
    if (_default_uri_scheme != nil)
         [args put:PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME string: _default_uri_scheme];
    if (_wizard_data != nil)
         [args put:PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA string: _wizard_data];

    if (_priority != nil)
         [args put:PEX_DBUSR_FIELD_PRIORITY NSNumberAsInt: _priority];
    if (_acc_id != nil)
         [args put:PEX_DBUSR_FIELD_ACC_ID string: _acc_id];
    if (_reg_uri != nil)
         [args put:PEX_DBUSR_FIELD_REG_URI string: _reg_uri];

    if (_publish_enabled != nil)
         [args put:PEX_DBUSR_FIELD_PUBLISH_ENABLED NSNumberAsInt: _publish_enabled];
    if (_reg_timeout != nil)
         [args put:PEX_DBUSR_FIELD_REG_TIMEOUT NSNumberAsInt: _reg_timeout];
    if (_ka_interval != nil)
         [args put:PEX_DBUSR_FIELD_KA_INTERVAL NSNumberAsInt: _ka_interval];
    if (_pidf_tuple_id != nil)
         [args put:PEX_DBUSR_FIELD_PIDF_TUPLE_ID string: _pidf_tuple_id];
    if (_force_contact != nil)
         [args put:PEX_DBUSR_FIELD_FORCE_CONTACT string: _force_contact];
    [args put:PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE NSNumberAsInt: @(_allow_contact_rewrite ? 1 : 0)];
    [args put:PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE NSNumberAsInt: @(_allow_via_rewrite ? 1 : 0)];
    if (_contact_rewrite_method != nil)
         [args put:PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD NSNumberAsInt: _contact_rewrite_method];
    if (_use_srtp != nil)
         [args put:PEX_DBUSR_FIELD_USE_SRTP NSNumberAsInt: _use_srtp];
    if (_use_zrtp != nil)
         [args put:PEX_DBUSR_FIELD_USE_ZRTP NSNumberAsInt: _use_zrtp];

    if (_proxies!=nil && [_proxies count]>0) {
        [args put: PEX_DBUSR_FIELD_PROXY string: [_proxies componentsJoinedByString:PEX_DBUSR_PROXIES_SEPARATOR]];
    }

    if (_reg_use_proxy != nil)
         [args put:PEX_DBUSR_FIELD_REG_USE_PROXY NSNumberAsInt: _reg_use_proxy];

    // Assume we have an unique credential
    if (_realm != nil)
         [args put:PEX_DBUSR_FIELD_REALM string: _realm];
    if (_scheme != nil)
         [args put:PEX_DBUSR_FIELD_SCHEME string: _scheme];
    if (_username != nil)
         [args put:PEX_DBUSR_FIELD_USERNAME string: _username];
    if (_datatype != nil)
         [args put:PEX_DBUSR_FIELD_DATATYPE NSNumberAsInt: _datatype];
        if (_data!=nil && [_data length]>0) {
            [args put:PEX_DBUSR_FIELD_PASSWORD string: _data];
    }

    [args put:PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH object: @(_initial_auth ? 1 : 0)];

    if(_auth_algo!=nil && [_auth_algo length]>0) {
        [args put:PEX_DBUSR_FIELD_AUTH_ALGO string: _auth_algo];
    }

    if (_sip_stack != nil)
         [args put:PEX_DBUSR_FIELD_SIP_STACK NSNumberAsInt: _sip_stack];

    [args put:PEX_DBUSR_FIELD_MWI_ENABLED NSNumberAsInt: @(_mwi_enabled ? 1 : 0)];

    if (_vm_nbr != nil)
         [args put:PEX_DBUSR_FIELD_VOICE_MAIL_NBR string: _vm_nbr];
    if (_reg_delay_before_refresh != nil)
         [args put:PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH NSNumberAsInt: _reg_delay_before_refresh];
    if (_try_clean_registers != nil)
         [args put:PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS NSNumberAsInt: _try_clean_registers];

    if (_rtp_bound_addr != nil)
         [args put:PEX_DBUSR_FIELD_RTP_BOUND_ADDR string: _rtp_bound_addr];
    if (_rtp_enable_qos != nil)
         [args put:PEX_DBUSR_FIELD_RTP_ENABLE_QOS NSNumberAsInt: _rtp_enable_qos];
    if (_rtp_port != nil)
         [args put:PEX_DBUSR_FIELD_RTP_PORT NSNumberAsInt: _rtp_port];
    if (_rtp_public_addr != nil)
         [args put:PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR string: _rtp_public_addr];
    if (_rtp_qos_dscp != nil)
         [args put:PEX_DBUSR_FIELD_RTP_QOS_DSCP NSNumberAsInt: _rtp_qos_dscp];

    if (_vid_in_auto_show != nil)
         [args put:PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW NSNumberAsInt: _vid_in_auto_show];
    if (_vid_out_auto_transmit != nil)
         [args put:PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT NSNumberAsInt: _vid_out_auto_transmit];

    if (_rfc5626_instance_id != nil)
         [args put:PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID string: _rfc5626_instance_id];
    if (_rfc5626_reg_id != nil)
         [args put:PEX_DBUSR_FIELD_RFC5626_REG_ID string: _rfc5626_reg_id];
        [args put:PEX_DBUSR_FIELD_USE_RFC5626 NSNumberAsInt: @(_use_rfc5626 ? 1 : 0)];
    if (_android_group != nil)
         [args put:PEX_DBUSR_FIELD_ANDROID_GROUP string: _android_group];

    if (_sip_stun_use != nil)
         [args put:PEX_DBUSR_FIELD_SIP_STUN_USE NSNumberAsInt: _sip_stun_use];
    if (_media_stun_use != nil)
         [args put:PEX_DBUSR_FIELD_MEDIA_STUN_USE NSNumberAsInt: _media_stun_use];
    if (_ice_cfg_use != nil)
         [args put:PEX_DBUSR_FIELD_ICE_CFG_USE NSNumberAsInt: _ice_cfg_use];
    if (_ice_cfg_enable != nil)
         [args put:PEX_DBUSR_FIELD_ICE_CFG_ENABLE NSNumberAsInt: _ice_cfg_enable];
    if (_turn_cfg_use != nil)
         [args put:PEX_DBUSR_FIELD_TURN_CFG_USE NSNumberAsInt: _turn_cfg_use];
    if (_turn_cfg_enable != nil)
         [args put:PEX_DBUSR_FIELD_TURN_CFG_ENABLE NSNumberAsInt: _turn_cfg_enable];
    if (_turn_cfg_server != nil)
         [args put:PEX_DBUSR_FIELD_TURN_CFG_SERVER string: _turn_cfg_server];
    if (_turn_cfg_user != nil)
         [args put:PEX_DBUSR_FIELD_TURN_CFG_USER string: _turn_cfg_user];
    if (_turn_cfg_password != nil)
         [args put:PEX_DBUSR_FIELD_TURN_CFG_PASSWORD string: _turn_cfg_password];

    if (_ipv6_media_use != nil)
         [args put:PEX_DBUSR_FIELD_IPV6_MEDIA_USE NSNumberAsInt: _ipv6_media_use];

    if (_cert_path != nil)
        [args put:PEX_DBUSR_FIELD_CERT_PATH string: _cert_path];
    if (_cert_not_before != nil)
        [args put:PEX_DBUSR_FIELD_CERT_NOT_BEFORE date:_cert_not_before];
    if (_cert_hash != nil)
        [args put:PEX_DBUSR_FIELD_CERT_HASH string: _cert_hash];
    if (_xmpp_server != nil)
        [args put:PEX_DBUSR_FIELD_XMPP_SERVER string: _xmpp_server];
    if (_xmpp_service != nil)
        [args put:PEX_DBUSR_FIELD_XMPP_SERVICE string: _xmpp_service];
    if (_xmpp_user != nil)
        [args put:PEX_DBUSR_FIELD_XMPP_USER_NAME string: _xmpp_user];
    if (_xmpp_password != nil)
        [args put:PEX_DBUSR_FIELD_XMPP_PASSWORD string: _xmpp_password];
    if (_recovery_email != nil)
        [args put:PEX_DBUSR_FIELD_RECOVERY_EMAIL string: _recovery_email];

    [args putIfNotNil:PEX_DBUSR_FIELD_LICENSE_TYPE string:_licenseType];
    [args putIfNotNil:PEX_DBUSR_FIELD_LICENSE_ISSUED_ON date:_licenseIssuedOn];
    [args putIfNotNil:PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON date:_licenseExpiresOn];
    [args put:PEX_DBUSR_FIELD_LICENSE_EXPIRED NSNumberAsInt: @(_licenseExpired ? 1 : 0)];

    return args;
}


/**
* Create account wrapper with content values pairs.
*
* @param args the content value to unpack.
*/
-(void) createFromCursor: (PEXDbCursor *) c {
    int colCount = [c getColumnCount];
    for(int i=0; i<colCount; i++) {

        const PEXModelHelper * const helper = [[PEXModelHelper alloc] initWithCursor:c index:i];
        NSString *colname = [c getColumnName:i];

        if ([PEX_DBUSR_FIELD_ID isEqualToString: colname]){
            _id = [c getInt64:i];
        } else if ([PEX_DBUSR_FIELD_DISPLAY_NAME isEqualToString:colname]) {
            _display_name = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_ACCOUNT_MANAGER isEqualToString:colname]) {
            _accountManager = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_TRANSPORT isEqualToString: colname]){
            _transport = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME isEqualToString:colname]) {
            _default_uri_scheme = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_ACTIVE isEqualToString: colname]){
            _active = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_ANDROID_GROUP isEqualToString:colname]) {
            _android_group = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA isEqualToString:colname]) {
            _wizard_data = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_PRIORITY isEqualToString: colname]){
            _priority = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_ACC_ID isEqualToString:colname]) {
            _acc_id = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_REG_URI isEqualToString:colname]) {
            _reg_uri = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_PUBLISH_ENABLED isEqualToString: colname]){
            _publish_enabled = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_REG_TIMEOUT isEqualToString: colname]){
            _reg_timeout = [c getInt64: i];
        } else if ([PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH isEqualToString: colname]){
            _reg_delay_before_refresh = [c getInt64: i];
        } else if ([PEX_DBUSR_FIELD_KA_INTERVAL isEqualToString: colname]){
            _ka_interval = [c getInt64: i];
        } else if ([PEX_DBUSR_FIELD_PIDF_TUPLE_ID isEqualToString:colname]) {
            _pidf_tuple_id = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_FORCE_CONTACT isEqualToString:colname]) {
            _force_contact = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE isEqualToString: colname]){
            _allow_contact_rewrite = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD isEqualToString: colname]){
            _contact_rewrite_method = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_CONTACT_PARAMS isEqualToString: colname]){
            // Ignored.
        } else if ([PEX_DBUSR_FIELD_CONTACT_URI_PARAMS isEqualToString: colname]){
            // Ignored.
        } else if ([PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE isEqualToString: colname]){
            _allow_via_rewrite = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_USE_SRTP isEqualToString: colname]){
            _use_srtp = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_USE_ZRTP isEqualToString: colname]){
            _use_zrtp = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_PROXY isEqualToString:colname]) {
            _proxies = [[[c getString:i] componentsSeparatedByString:PEX_DBUSR_PROXIES_SEPARATOR] mutableCopy];
        } else if ([PEX_DBUSR_FIELD_REG_USE_PROXY isEqualToString: colname]){
            _reg_use_proxy = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_REALM isEqualToString:colname]) {
            _realm = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_SCHEME isEqualToString:colname]) {
            _scheme = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_USERNAME isEqualToString:colname]) {
            _username = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_DATATYPE isEqualToString: colname]){
            _datatype = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_PASSWORD isEqualToString:colname]) {
            _data = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH isEqualToString: colname]){
            _initial_auth = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_AUTH_ALGO isEqualToString:colname]) {
            _auth_algo = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_SIP_STACK isEqualToString: colname]){
            _sip_stack = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_MWI_ENABLED isEqualToString: colname]){
            _mwi_enabled = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_VOICE_MAIL_NBR isEqualToString:colname]) {
            _vm_nbr = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS isEqualToString: colname]){
            _try_clean_registers = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_USE_RFC5626 isEqualToString: colname]){
            _use_rfc5626 = [[c getInt: i] integerValue]==1;
        } else if ([PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID isEqualToString:colname]) {
            _rfc5626_instance_id = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_RFC5626_REG_ID isEqualToString:colname]) {
            _rfc5626_reg_id = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW isEqualToString: colname]){
            _vid_in_auto_show = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT isEqualToString: colname]){
            _vid_out_auto_transmit = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_RTP_PORT isEqualToString: colname]){
            _rtp_port = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR isEqualToString:colname]) {
            _rtp_public_addr = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_RTP_BOUND_ADDR isEqualToString:colname]) {
            _rtp_bound_addr = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_RTP_ENABLE_QOS isEqualToString: colname]){
            _rtp_enable_qos = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_RTP_QOS_DSCP isEqualToString: colname]){
            _rtp_qos_dscp = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_SIP_STUN_USE isEqualToString: colname]){
            _sip_stun_use = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_MEDIA_STUN_USE isEqualToString: colname]){
            _media_stun_use = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_ICE_CFG_USE isEqualToString: colname]){
            _ice_cfg_use = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_ICE_CFG_ENABLE isEqualToString: colname]){
            _ice_cfg_enable = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_TURN_CFG_USE isEqualToString: colname]){
            _turn_cfg_use = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_TURN_CFG_ENABLE isEqualToString: colname]){
            _turn_cfg_enable = [c getInt: i];
        } else if ([PEX_DBUSR_FIELD_TURN_CFG_SERVER isEqualToString:colname]) {
            _turn_cfg_server = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_TURN_CFG_USER isEqualToString:colname]) {
            _turn_cfg_user = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_TURN_CFG_PASSWORD isEqualToString:colname]) {
            _turn_cfg_password = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_IPV6_MEDIA_USE isEqualToString: colname]) {
            _ipv6_media_use = [c getInt:i];
        } else if ([PEX_DBUSR_FIELD_CERT_PATH isEqualToString:colname]) {
            _cert_path = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_CERT_NOT_BEFORE isEqualToString:colname]) {
            _cert_not_before = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBUSR_FIELD_CERT_HASH isEqualToString:colname]) {
            _cert_hash = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_XMPP_SERVER isEqualToString:colname]) {
            _xmpp_server = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_XMPP_SERVICE isEqualToString:colname]) {
            _xmpp_service = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_XMPP_USER_NAME isEqualToString:colname]) {
            _xmpp_user = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_XMPP_PASSWORD isEqualToString:colname]) {
            _xmpp_password = [c getString:i];
        } else if ([PEX_DBUSR_FIELD_RECOVERY_EMAIL isEqualToString:colname]) {
            _recovery_email = [c getString:i];
        }

        else if ([helper assignStringTo:&_licenseType ifMatchesColumn:PEX_DBUSR_FIELD_LICENSE_TYPE]) {}
        else if ([helper assignDateTo:&_licenseIssuedOn ifMatchesColumn:PEX_DBUSR_FIELD_LICENSE_ISSUED_ON]) {}
        else if ([helper assignDateTo:&_licenseExpiresOn ifMatchesColumn:PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON]) {}
        else if ([helper assignBoolTo:&_licenseExpired ifMatchesColumn:PEX_DBUSR_FIELD_LICENSE_EXPIRED]) {}


        else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.primaryKey = [coder decodeObjectForKey:@"self.primaryKey"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.display_name = [coder decodeObjectForKey:@"self.display_name"];
        self.accountManager = [coder decodeObjectForKey:@"self.accountManager"];
        self.transport = [coder decodeObjectForKey:@"self.transport"];
        self.default_uri_scheme = [coder decodeObjectForKey:@"self.default_uri_scheme"];
        self.active = [coder decodeBoolForKey:@"self.active"];
        self.priority = [coder decodeObjectForKey:@"self.priority"];
        self.acc_id = [coder decodeObjectForKey:@"self.acc_id"];
        self.reg_uri = [coder decodeObjectForKey:@"self.reg_uri"];
        self.publish_enabled = [coder decodeObjectForKey:@"self.publish_enabled"];
        self.reg_timeout = [coder decodeObjectForKey:@"self.reg_timeout"];
        self.ka_interval = [coder decodeObjectForKey:@"self.ka_interval"];
        self.pidf_tuple_id = [coder decodeObjectForKey:@"self.pidf_tuple_id"];
        self.force_contact = [coder decodeObjectForKey:@"self.force_contact"];
        self.allow_contact_rewrite = [coder decodeBoolForKey:@"self.allow_contact_rewrite"];
        self.contact_rewrite_method = [coder decodeObjectForKey:@"self.contact_rewrite_method"];
        self.allow_via_rewrite = [coder decodeBoolForKey:@"self.allow_via_rewrite"];
        self.proxies = [coder decodeObjectForKey:@"self.proxies"];
        self.realm = [coder decodeObjectForKey:@"self.realm"];
        self.username = [coder decodeObjectForKey:@"self.username"];
        self.scheme = [coder decodeObjectForKey:@"self.scheme"];
        self.datatype = [coder decodeObjectForKey:@"self.datatype"];
        self.data = [coder decodeObjectForKey:@"self.data"];
        self.initial_auth = [coder decodeBoolForKey:@"self.initial_auth"];
        self.auth_algo = [coder decodeObjectForKey:@"self.auth_algo"];
        self.use_srtp = [coder decodeObjectForKey:@"self.use_srtp"];
        self.use_zrtp = [coder decodeObjectForKey:@"self.use_zrtp"];
        self.reg_use_proxy = [coder decodeObjectForKey:@"self.reg_use_proxy"];
        self.sip_stack = [coder decodeObjectForKey:@"self.sip_stack"];
        self.vm_nbr = [coder decodeObjectForKey:@"self.vm_nbr"];
        self.reg_delay_before_refresh = [coder decodeObjectForKey:@"self.reg_delay_before_refresh"];
        self.try_clean_registers = [coder decodeObjectForKey:@"self.try_clean_registers"];
        self.icon = [coder decodeObjectForKey:@"self.icon"];
        self.use_rfc5626 = [coder decodeBoolForKey:@"self.use_rfc5626"];
        self.rfc5626_instance_id = [coder decodeObjectForKey:@"self.rfc5626_instance_id"];
        self.rfc5626_reg_id = [coder decodeObjectForKey:@"self.rfc5626_reg_id"];
        self.vid_in_auto_show = [coder decodeObjectForKey:@"self.vid_in_auto_show"];
        self.vid_out_auto_transmit = [coder decodeObjectForKey:@"self.vid_out_auto_transmit"];
        self.rtp_port = [coder decodeObjectForKey:@"self.rtp_port"];
        self.rtp_public_addr = [coder decodeObjectForKey:@"self.rtp_public_addr"];
        self.rtp_bound_addr = [coder decodeObjectForKey:@"self.rtp_bound_addr"];
        self.rtp_enable_qos = [coder decodeObjectForKey:@"self.rtp_enable_qos"];
        self.rtp_qos_dscp = [coder decodeObjectForKey:@"self.rtp_qos_dscp"];
        self.android_group = [coder decodeObjectForKey:@"self.android_group"];
        self.mwi_enabled = [coder decodeBoolForKey:@"self.mwi_enabled"];
        self.sip_stun_use = [coder decodeObjectForKey:@"self.sip_stun_use"];
        self.media_stun_use = [coder decodeObjectForKey:@"self.media_stun_use"];
        self.ice_cfg_use = [coder decodeObjectForKey:@"self.ice_cfg_use"];
        self.ice_cfg_enable = [coder decodeObjectForKey:@"self.ice_cfg_enable"];
        self.turn_cfg_use = [coder decodeObjectForKey:@"self.turn_cfg_use"];
        self.turn_cfg_enable = [coder decodeObjectForKey:@"self.turn_cfg_enable"];
        self.turn_cfg_server = [coder decodeObjectForKey:@"self.turn_cfg_server"];
        self.turn_cfg_user = [coder decodeObjectForKey:@"self.turn_cfg_user"];
        self.turn_cfg_password = [coder decodeObjectForKey:@"self.turn_cfg_password"];
        self.ipv6_media_use = [coder decodeObjectForKey:@"self.ipv6_media_use"];
        self.wizard_data = [coder decodeObjectForKey:@"self.wizard_data"];
        self.cert_path = [coder decodeObjectForKey:@"self.cert_path"];
        self.cert_not_before = [coder decodeObjectForKey:@"self.cert_not_before"];
        self.cert_hash = [coder decodeObjectForKey:@"self.cert_hash"];
        self.xmpp_server = [coder decodeObjectForKey:@"self.xmpp_server"];
        self.xmpp_service = [coder decodeObjectForKey:@"self.xmpp_service"];
        self.xmpp_user = [coder decodeObjectForKey:@"self.xmpp_user"];
        self.xmpp_password = [coder decodeObjectForKey:@"self.xmpp_password"];

        self.licenseType = [coder decodeObjectForKey:@"self.licenseType"];
        self.licenseIssuedOn = [coder decodeObjectForKey:@"self.licenseIssuedOn"];
        self.licenseExpiresOn = [coder decodeObjectForKey:@"self.licenseExpiresOn"];
        self.licenseExpired = [coder decodeBoolForKey:@"self.licenseExpired"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.primaryKey forKey:@"self.primaryKey"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.display_name forKey:@"self.display_name"];
    [coder encodeObject:self.accountManager forKey:@"self.accountManager"];
    [coder encodeObject:self.transport forKey:@"self.transport"];
    [coder encodeObject:self.default_uri_scheme forKey:@"self.default_uri_scheme"];
    [coder encodeBool:self.active forKey:@"self.active"];
    [coder encodeObject:self.priority forKey:@"self.priority"];
    [coder encodeObject:self.acc_id forKey:@"self.acc_id"];
    [coder encodeObject:self.reg_uri forKey:@"self.reg_uri"];
    [coder encodeObject:self.publish_enabled forKey:@"self.publish_enabled"];
    [coder encodeObject:self.reg_timeout forKey:@"self.reg_timeout"];
    [coder encodeObject:self.ka_interval forKey:@"self.ka_interval"];
    [coder encodeObject:self.pidf_tuple_id forKey:@"self.pidf_tuple_id"];
    [coder encodeObject:self.force_contact forKey:@"self.force_contact"];
    [coder encodeBool:self.allow_contact_rewrite forKey:@"self.allow_contact_rewrite"];
    [coder encodeObject:self.contact_rewrite_method forKey:@"self.contact_rewrite_method"];
    [coder encodeBool:self.allow_via_rewrite forKey:@"self.allow_via_rewrite"];
    [coder encodeObject:self.proxies forKey:@"self.proxies"];
    [coder encodeObject:self.realm forKey:@"self.realm"];
    [coder encodeObject:self.username forKey:@"self.username"];
    [coder encodeObject:self.scheme forKey:@"self.scheme"];
    [coder encodeObject:self.datatype forKey:@"self.datatype"];
    [coder encodeObject:self.data forKey:@"self.data"];
    [coder encodeBool:self.initial_auth forKey:@"self.initial_auth"];
    [coder encodeObject:self.auth_algo forKey:@"self.auth_algo"];
    [coder encodeObject:self.use_srtp forKey:@"self.use_srtp"];
    [coder encodeObject:self.use_zrtp forKey:@"self.use_zrtp"];
    [coder encodeObject:self.reg_use_proxy forKey:@"self.reg_use_proxy"];
    [coder encodeObject:self.sip_stack forKey:@"self.sip_stack"];
    [coder encodeObject:self.vm_nbr forKey:@"self.vm_nbr"];
    [coder encodeObject:self.reg_delay_before_refresh forKey:@"self.reg_delay_before_refresh"];
    [coder encodeObject:self.try_clean_registers forKey:@"self.try_clean_registers"];
    [coder encodeObject:self.icon forKey:@"self.icon"];
    [coder encodeBool:self.use_rfc5626 forKey:@"self.use_rfc5626"];
    [coder encodeObject:self.rfc5626_instance_id forKey:@"self.rfc5626_instance_id"];
    [coder encodeObject:self.rfc5626_reg_id forKey:@"self.rfc5626_reg_id"];
    [coder encodeObject:self.vid_in_auto_show forKey:@"self.vid_in_auto_show"];
    [coder encodeObject:self.vid_out_auto_transmit forKey:@"self.vid_out_auto_transmit"];
    [coder encodeObject:self.rtp_port forKey:@"self.rtp_port"];
    [coder encodeObject:self.rtp_public_addr forKey:@"self.rtp_public_addr"];
    [coder encodeObject:self.rtp_bound_addr forKey:@"self.rtp_bound_addr"];
    [coder encodeObject:self.rtp_enable_qos forKey:@"self.rtp_enable_qos"];
    [coder encodeObject:self.rtp_qos_dscp forKey:@"self.rtp_qos_dscp"];
    [coder encodeObject:self.android_group forKey:@"self.android_group"];
    [coder encodeBool:self.mwi_enabled forKey:@"self.mwi_enabled"];
    [coder encodeObject:self.sip_stun_use forKey:@"self.sip_stun_use"];
    [coder encodeObject:self.media_stun_use forKey:@"self.media_stun_use"];
    [coder encodeObject:self.ice_cfg_use forKey:@"self.ice_cfg_use"];
    [coder encodeObject:self.ice_cfg_enable forKey:@"self.ice_cfg_enable"];
    [coder encodeObject:self.turn_cfg_use forKey:@"self.turn_cfg_use"];
    [coder encodeObject:self.turn_cfg_enable forKey:@"self.turn_cfg_enable"];
    [coder encodeObject:self.turn_cfg_server forKey:@"self.turn_cfg_server"];
    [coder encodeObject:self.turn_cfg_user forKey:@"self.turn_cfg_user"];
    [coder encodeObject:self.turn_cfg_password forKey:@"self.turn_cfg_password"];
    [coder encodeObject:self.ipv6_media_use forKey:@"self.ipv6_media_use"];
    [coder encodeObject:self.wizard_data forKey:@"self.wizard_data"];
    [coder encodeObject:self.cert_path forKey:@"self.cert_path"];
    [coder encodeObject:self.cert_not_before forKey:@"self.cert_not_before"];
    [coder encodeObject:self.cert_hash forKey:@"self.cert_hash"];
    [coder encodeObject:self.xmpp_server forKey:@"self.xmpp_server"];
    [coder encodeObject:self.xmpp_service forKey:@"self.xmpp_service"];
    [coder encodeObject:self.xmpp_user forKey:@"self.xmpp_user"];
    [coder encodeObject:self.xmpp_password forKey:@"self.xmpp_password"];

    [coder encodeObject:self.licenseType forKey:@"self.licenseType"];
    [coder encodeObject:self.licenseIssuedOn forKey:@"self.licenseIssuedOn"];
    [coder encodeObject:self.licenseExpiresOn forKey:@"self.licenseExpiresOn"];
    [coder encodeBool:self.licenseExpired forKey:@"self.licenseExpired"];
}

/**
* Get the default domain for this account
*
* @return the default domain for this account
*/
-(NSString *) getDefaultDomain {
    PEXSIPURIParsedSipUri * parsedInfo = nil;
    if (![PEXUtils isEmpty:_reg_uri]){
        parsedInfo = [PEXSipUri parseSipUri:_reg_uri];
    } else if (_proxies != nil && _proxies.count > 0){
        parsedInfo = [PEXSipUri parseSipUri:_proxies[0]];
    }

    if (parsedInfo == nil) {
        return nil;
    }

    if (![PEXUtils isEmpty:parsedInfo.domain]) {
        if (parsedInfo.port != 5060) {
            [NSString stringWithFormat:@"%@:%d", parsedInfo.domain, parsedInfo.port];
        } else {
            return parsedInfo.domain;
        }
    } else {
        DDLogError(@"Domain not found for this account");
    }
    return nil;
}

/**
* Gets the display name of the user.
*
* @return the caller id for this account
*/
-(NSString *) getDisplayName {
    if (_acc_id == nil){
        return @"";
    }

    PEXSIPURIParsedSipContact * parsed = [PEXSipUri parseSipContact:_acc_id];
    if (parsed!=nil && ![PEXUtils isEmpty:parsed.displayName]) {
        return parsed.displayName;
    }

    return @"";
}

/**
* Gets the network address of the server outbound proxy.
*
* @return the first proxy server if any else empty string
*/
-(NSString *) getProxyAddress {
    if (_proxies != nil && [_proxies count] > 0) {
        return _proxies[0];
    }
    return @"";
}

/**
* Gets the SIP domain when acc_id is username@domain.
*
* @return the sip domain for this account
*/
-(NSString *) getSipDomain {
    if (_acc_id == nil){
        return @"";
    }

    PEXSIPURIParsedSipContact * parsed = [PEXSipUri parseSipContact:_acc_id];
    if (parsed!=nil && ![PEXUtils isEmpty:parsed.domain]) {
        return parsed.domain;
    }

    return @"";
}

/**
* Gets the username when acc_id is username@domain. WARNING : this is
* different from username of SipProfile which is the authentication name
* cause of pjsip naming
*
* @return the username of the account sip id. <br/>
*         Example if acc_id is "Display Name" &lt;sip:user@domain.com&gt;, it
*         will return user.
*/
-(NSString *) getSipUserName {
    if (_acc_id == nil){
        return @"";
    }

    PEXSIPURIParsedSipContact * parsed = [PEXSipUri parseSipContact:_acc_id];
    if (parsed!=nil && ![PEXUtils isEmpty:parsed.userName]) {
        return parsed.userName;
    }

    return @"";
}
//
///**
//* Helper method to retrieve a SipProfile object from its account database
//* id.<br/>
//* You have to specify the projection you want to use for to retrieve infos.<br/>
//* As consequence the wrapper SipProfile object you'll get may be
//* incomplete. So take care if you try to reinject it by updating to not
//* override existing values of the database that you don't get here.
//*
//* @param ctxt Your application context. Mainly useful to get the content provider for the request.
//* @param accountId The sip profile {@link #FIELD_ID} you want to retrieve.
//* @param projection The list of fields you want to retrieve. Must be in FIELD_* of this class.<br/>
//* Reducing your requested fields to minimum will improve speed of the request.
//* @return A wrapper SipProfile object on the request you done. If not found an invalid account with an {@link #id} equals to {@link #INVALID_ID}
//*/
//+ (PEXDBUserProfile *) getProfileFromDbId(Context ctxt, long accountId, String[] projection) {
//    SipProfile account = new SipProfile();
//    if (accountId != INVALID_ID) {
//        Cursor c = ctxt.getContentResolver().query(
//                ContentUris.withAppendedId(ACCOUNT_ID_URI_BASE, accountId),
//                projection, null, null, null);
//
//        if (c != null) {
//            try {
//                if (c.getCount() > 0) {
//                    c.moveToFirst();
//                    account = new SipProfile(c);
//                }
//            } catch (Exception e) {
//                Log.e(THIS_FILE, "Something went wrong while retrieving the account", e);
//            } finally {
//                c.close();
//            }
//        }
//    }
//    return account;
//}
//
///**
//* Get the list of sip profiles available.
//* @param ctxt Your application context. Mainly useful to get the content provider for the request.
//* @param onlyActive Pass it to true if you are only interested in active accounts.
//* @return The list of SipProfiles containings only fields of {@link #LISTABLE_PROJECTION} filled.
//* @see #LISTABLE_PROJECTION
//*/
//+(NSArray *) getAllProfiles(Context ctxt, boolean onlyActive) {
//    return getAllProfiles(ctxt, onlyActive, LISTABLE_PROJECTION);
//}
//
///**
//* Returns profile that matches given sip name from user database.
//* @param ctxt
//* @param sipName
//* @param projection
//* @return
//*/
//+(PEXDBUserProfile *) getProfileFromDbName(Context ctxt, String sipName, boolean onlyActive, String[] projection) {
//    if (sipName==null || sipName.length()==0)
//        return null;
//
//    ArrayList<SipProfile> profList = getAllProfiles(ctxt, onlyActive);
//    if (profList==null || profList.isEmpty())
//        return null;
//
//    final String searchedSip = SipUri.getCanonicalSipContact(sipName, false);
//    for(SipProfile p : profList){
//        final String usrName = p.getSipUserName() + "@" + p.getSipDomain();
//
//        if (usrName!=null && usrName.equalsIgnoreCase(searchedSip))
//            return p;
//        if (p.username != null && p.username.equalsIgnoreCase(searchedSip))
//            return p;
//        if (p.acc_id != null && p.acc_id.equalsIgnoreCase(searchedSip))
//            return p;
//    }
//
//    return null;
//
//}
//
///**
//* Get the list of sip profiles available.
//* @param ctxt Your application context. Mainly useful to get the content provider for the request.
//* @param onlyActive Pass it to true if you are only interested in active accounts.
//* @param projection The projection to use for cursor
//* @return The list of SipProfiles
//*/
//+(NSArray *) getAllProfiles(Context ctxt, boolean onlyActive, String[] projection) {
//    ArrayList<SipProfile> result = new ArrayList<SipProfile>();
//
//    String selection = null;
//    String[] selectionArgs = null;
//    if (onlyActive) {
//        selection = SipProfile.FIELD_ACTIVE + "=?";
//        selectionArgs = new String[] {
//            "1"
//        };
//    }
//    Cursor c = ctxt.getContentResolver().query(ACCOUNT_URI, projection, selection, selectionArgs, null);
//
//    if (c != null) {
//        try {
//            if (c.moveToFirst()) {
//                do {
//                    result.add(new SipProfile(c));
//                } while (c.moveToNext());
//            }
//        } catch (Exception e) {
//            Log.e(THIS_FILE, "Error on looping over sip profiles", e);
//        } finally {
//            c.close();
//        }
//    }
//
//    return result;
//}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbUserProfile *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.primaryKey = self.primaryKey;
        copy.id = self.id;
        copy.display_name = self.display_name;
        copy.accountManager = self.accountManager;
        copy.transport = self.transport;
        copy.default_uri_scheme = self.default_uri_scheme;
        copy.active = self.active;
        copy.priority = self.priority;
        copy.acc_id = self.acc_id;
        copy.reg_uri = self.reg_uri;
        copy.publish_enabled = self.publish_enabled;
        copy.reg_timeout = self.reg_timeout;
        copy.ka_interval = self.ka_interval;
        copy.pidf_tuple_id = self.pidf_tuple_id;
        copy.force_contact = self.force_contact;
        copy.allow_contact_rewrite = self.allow_contact_rewrite;
        copy.contact_rewrite_method = self.contact_rewrite_method;
        copy.allow_via_rewrite = self.allow_via_rewrite;
        copy.proxies = self.proxies;
        copy.realm = self.realm;
        copy.username = self.username;
        copy.scheme = self.scheme;
        copy.datatype = self.datatype;
        copy.data = self.data;
        copy.initial_auth = self.initial_auth;
        copy.auth_algo = self.auth_algo;
        copy.use_srtp = self.use_srtp;
        copy.use_zrtp = self.use_zrtp;
        copy.reg_use_proxy = self.reg_use_proxy;
        copy.sip_stack = self.sip_stack;
        copy.vm_nbr = self.vm_nbr;
        copy.reg_delay_before_refresh = self.reg_delay_before_refresh;
        copy.try_clean_registers = self.try_clean_registers;
        copy.icon = self.icon;
        copy.use_rfc5626 = self.use_rfc5626;
        copy.rfc5626_instance_id = self.rfc5626_instance_id;
        copy.rfc5626_reg_id = self.rfc5626_reg_id;
        copy.vid_in_auto_show = self.vid_in_auto_show;
        copy.vid_out_auto_transmit = self.vid_out_auto_transmit;
        copy.rtp_port = self.rtp_port;
        copy.rtp_public_addr = self.rtp_public_addr;
        copy.rtp_bound_addr = self.rtp_bound_addr;
        copy.rtp_enable_qos = self.rtp_enable_qos;
        copy.rtp_qos_dscp = self.rtp_qos_dscp;
        copy.android_group = self.android_group;
        copy.mwi_enabled = self.mwi_enabled;
        copy.sip_stun_use = self.sip_stun_use;
        copy.media_stun_use = self.media_stun_use;
        copy.ice_cfg_use = self.ice_cfg_use;
        copy.ice_cfg_enable = self.ice_cfg_enable;
        copy.turn_cfg_use = self.turn_cfg_use;
        copy.turn_cfg_enable = self.turn_cfg_enable;
        copy.turn_cfg_server = self.turn_cfg_server;
        copy.turn_cfg_user = self.turn_cfg_user;
        copy.turn_cfg_password = self.turn_cfg_password;
        copy.ipv6_media_use = self.ipv6_media_use;
        copy.wizard_data = self.wizard_data;
        copy.cert_path = self.cert_path;
        copy.cert_not_before = self.cert_not_before;
        copy.cert_hash = self.cert_hash;
        copy.xmpp_server = self.xmpp_server;
        copy.xmpp_service = self.xmpp_service;
        copy.xmpp_user = self.xmpp_user;
        copy.xmpp_password = self.xmpp_password;

        copy.licenseType = self.licenseType;
        copy.licenseIssuedOn = self.licenseIssuedOn;
        copy.licenseExpiresOn = self.licenseExpiresOn;
        copy.licenseExpired = self.licenseExpired;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToProfile:other];
}

- (BOOL)isEqualToProfile:(PEXDbUserProfile *)profile {
    if (self == profile)
        return YES;
    if (profile == nil)
        return NO;
    if (self.id != profile.id && ![self.id isEqualToNumber:profile.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

@end