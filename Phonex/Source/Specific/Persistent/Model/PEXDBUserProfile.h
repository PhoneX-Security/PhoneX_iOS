//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbModelBase.h"
#import "PEXSipUri.h"
#import "PEXDbContentProvider.h"

#define PEX_DBUSR_CRED_CRED_DATA_EXT_AKA 2
#define PEX_DBUSR_CRED_DATA_DIGEST 1
#define PEX_DBUSR_CRED_DATA_PLAIN_PASSWD 0
#define PEX_DBUSR_GOOGLE_STACK 1
#define PEX_DBUSR_INVALID_ID -1L
#define PEX_DBUSR_PJSIP_STACK 0
#define PEX_DBUSR_TRANSPORT_AUTO 0
#define PEX_DBUSR_TRANSPORT_TCP 2
#define PEX_DBUSR_TRANSPORT_TLS 3
#define PEX_DBUSR_TRANSPORT_UDP 1
#define PEX_DBUSR_USER_ID 1LL

FOUNDATION_EXPORT NSString *PEX_DBUSR_CRED_SCHEME_DIGEST;
FOUNDATION_EXPORT NSString *PEX_DBUSR_CRED_SCHEME_PGP;
FOUNDATION_EXPORT NSString *PEX_DBUSR_PROXIES_SEPARATOR;
FOUNDATION_EXPORT NSString *PEX_DBUSR_ACCOUNTS_TABLE_NAME;
FOUNDATION_EXPORT NSString *PEX_DBUSR_ACCOUNTS_STATUS_TABLE_NAME;

/**
* Primary key identifier of the account in the database.
*
* @see Long
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ID;
/**
* Activation state of the account.<br/>
* If false this account will be ignored by the sip stack.
*
* @see Boolean
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ACTIVE;
/**
* The accountManager associated to this account.<br/>
* Used for icon and edit layout view.
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ACCOUNT_MANAGER;
/**
* The display name of the account. <br/>
* This is used in the application interface to show the label representing
* the account.
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_DISPLAY_NAME;
/**
* The priority of the account.<br/>
* This is used in the interface when presenting list of accounts.<br/>
* This can also be used to choose the default account. <br/>
* Higher means highest priority.
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_PRIORITY;
/**
* The full SIP URL for the account. <br/>
* The value can take name address or URL format, and will look something
* like "sip:account@serviceprovider".<br/>
* This field is mandatory.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#ab290b04e8150ed9627335a67e6127b7c"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ACC_ID;

/**
* Data useful for the accountManager internal use.
* The format here is specific to the accountManager and no assumption is made.
* Could be simplestring, json, base64 encoded stuff etc.
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ACCOUNT_MANAGER_DATA;

/**
* This is the URL to be put in the request URI for the registration, and
* will look something like "sip:serviceprovider".<br/>
* This field should be specified if registration is desired. If the value
* is empty, no account registration will be performed.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a08473de6401e966d23f34d3a9a05bdd0"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_REG_URI;
/**
* Subscribe to message waiting indication events (RFC 3842).<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a0158ae24d72872a31a0b33c33450a7ab"
* >Pjsip documentation</a>
*
* @see Boolean
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_MWI_ENABLED;
/**
* If this flag is set, the presence information of this account will be
* PUBLISH-ed to the server where the account belongs.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a0d4128f44963deffda4ea9c15183a787"
* >Pjsip documentation</a>
* 1 for true, 0 for false
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_PUBLISH_ENABLED;
/**
* Optional interval for registration, in seconds. <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a2c097b9ae855783bfbb00056055dd96c"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_REG_TIMEOUT;
/**
* Specify the number of seconds to refresh the client registration before
* the registration expires.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a52a35fdf8c17263b2a27d2b17111c040"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_REG_DELAY_BEFORE_REFRESH;
/**
* Set the interval for periodic keep-alive transmission for this account. <br/>
* If this value is zero, keep-alive will be disabled for this account.<br/>
* The keep-alive transmission will be sent to the registrar's address,
* after successful registration.<br/>
* Note that this value is not applied anymore in flavor to
* {@link PhonexConfig#KEEP_ALIVE_INTERVAL_MOBILE} and
* {@link PhonexConfig#KEEP_ALIVE_INTERVAL_WIFI} <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a98722b6464d16b5a76aec81f2d2a0694"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_KA_INTERVAL;
/**
* Optional PIDF tuple ID for outgoing PUBLISH and NOTIFY. <br/>
* If this value is not specified, a random string will be used. <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#aa603989566022840b4671f0171b6cba1"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_PIDF_TUPLE_ID;
/**
* Optional URI to be put as Contact for this account.<br/>
* It is recommended that this field is left empty, so that the value will
* be calculated automatically based on the transport address.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a5dfdfba40038e33af95819fbe2b896f9"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_FORCE_CONTACT;

/**
* This option is used to update the transport address and the Contact
* header of REGISTER request.<br/>
* When this option is enabled, the library will keep track of the public IP
* address from the response of REGISTER request. <br/>
* Once it detects that the address has changed, it will unregister current
* Contact, update the Contact with transport address learned from Via
* header, and register a new Contact to the registrar.<br/>
* This will also update the public name of UDP transport if STUN is
* configured.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a22961bb72ea75f7ca7008464f081ca06"
* >Pjsip documentation</a>
*
* @see Boolean
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ALLOW_CONTACT_REWRITE;
/**
* Specify how Contact update will be done with the registration, if
* allow_contact_rewrite is enabled.<br/>
* <ul>
* <li>If set to 1, the Contact update will be done by sending
* unregistration to the currently registered Contact, while simultaneously
* sending new registration (with different Call-ID) for the updated
* Contact.</li>
* <li>If set to 2, the Contact update will be done in a single, current
* registration session, by removing the current binding (by setting its
* Contact's expires parameter to zero) and adding a new Contact binding,
* all done in a single request.</li>
* </ul>
* Value 1 is the legacy behavior.<br/>
* Value 2 is the default behavior.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a73b69a3a8d225147ce386e310e588285"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CONTACT_REWRITE_METHOD;

/**
* Additional parameters that will be appended in the Contact header for
* this account.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#abef88254f9ef2a490503df6d3b297e54"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CONTACT_PARAMS;
/**
* Additional URI parameters that will be appended in the Contact URI for
* this account.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#aced70341308928ae951525093bf47562"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CONTACT_URI_PARAMS;
/**
* Transport to use for this account.<br/>
*
* @see #TRANSPORT_AUTO
* @see #TRANSPORT_UDP
* @see #TRANSPORT_TCP
* @see #TRANSPORT_TLS
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TRANSPORT;
/**
* Default scheme to automatically add for this account when calling without uri scheme.<br/>
*
* This is free field but should be one of :
* sip, sips, tel
* If invalid (or empty) will automatically fallback to sip
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_DEFAULT_URI_SCHEME;
/**
* Way the application should use SRTP. <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a34b00edb1851924a99efd8fedab917ba"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_USE_SRTP;
/**
* Way the application should use SRTP. <br/>
* 0 means disabled for this account <br/>
* 1 means enabled for this account
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_USE_ZRTP;

/**
* Optional URI of the proxies to be visited for all outgoing requests that
* are using this account (REGISTER, INVITE, etc).<br/>
* If multiple separate it by {@link #PROXIES_SEPARATOR}. <br/>
* Warning, for now api doesn't allow multiple credentials so if you have
* one credential per proxy may not work.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a93ad0699020c17ddad5eb98dea69f699"
* >Pjsip documentation</a>
*
* @see String
* @see #PROXIES_SEPARATOR
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_PROXY;
/**
* Specify how the registration uses the outbound and account proxy
* settings. <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#ad932bbb3c2c256f801c775319e645717"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_REG_USE_PROXY;

// For now, assume unique credential
/**
* Realm to filter on for credentials.<br/>
* Put star "*" char if you want it to match all requests.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsip__cred__info.htm#a96eee6bdc2b0e7e3b7eea9b4e1c15674"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_REALM;
/**
* Scheme (e.g. "digest").<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsip__cred__info.htm#ae31c9ec1c99fb1ffa20be5954ee995a7"
* >Pjsip documentation</a>
*
* @see String
* @see #CRED_SCHEME_DIGEST
* @see #CRED_SCHEME_PGP
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_SCHEME;
/**
* Credential username.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsip__cred__info.htm#a3e1f72a171886985c6dfcd57d4bc4f17"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_USERNAME;
/**
* Type of the data for credentials.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsip__cred__info.htm#a8b1e563c814bdf8012f0bdf966d0ad9d"
* >Pjsip documentation</a>
*
* @see Integer
* @see #CRED_DATA_PLAIN_PASSWD
* @see #CRED_DATA_DIGEST
* @see #CRED_CRED_DATA_EXT_AKA
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_DATATYPE;
/**
* The data, which can be a plaintext password or a hashed digest.<br/>
* This is available on in read only for third party application for obvious
* security reason.<br/>
* If you update the content provider without passing this parameter it will
* not override it. <br/>
* If in a third party app you want to store the password to allow user to
* see it, you have to manage this by your own. <br/>
* However, it's highly recommanded to not store it by your own, and keep it
* stored only in app.<br/>
* It available for write/overwrite. <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsip__cred__info.htm#ab3947a7800c51d28a1b25f4fdaea78bd"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_PASSWORD;

/**
* If this flag is set, the authentication client framework will send an empty Authorization header in each initial request. Default is no.
*  <a target="_blank" href=
* "http://www.pjsip.org/docs/latest/pjsip/docs/html/structpjsip__auth__clt__pref.htm#ac3487e53d8d6b3ea392315b08e2aac4a"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_AUTH_INITIAL_AUTH;

/**
* If this flag is set, the authentication client framework will send an empty Authorization header in each initial request. Default is no.
*  <a target="_blank" href=
* "http://www.pjsip.org/docs/latest/pjsip/docs/html/structpjsip__auth__clt__pref.htm#ac3487e53d8d6b3ea392315b08e2aac4a"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_AUTH_ALGO;

// Android stuff
/**
* The backend sip stack to use for this account.<br/>
* For now only pjsip backend is supported.
*
* @see Integer
* @see #PJSIP_STACK
* @see #GOOGLE_STACK
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_SIP_STACK;
/**
* Sip contact to call if user want to consult his voice mail.<br/>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_VOICE_MAIL_NBR;
/**
* Associated contact group for buddy list of this account.<br/>
* Users of this group will be considered as part of the buddy list of this
* account and will automatically try to subscribe presence if activated.<br/>
* Warning : not implemented for now.
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ANDROID_GROUP;

// Sip outbound
/**
* Control the use of SIP outbound feature. <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a306e4641988606f1ef0993e398ff98e7"
* >Pjsip documentation</a>
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_USE_RFC5626;
/**
* Specify SIP outbound (RFC 5626) instance ID to be used by this
* application.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#ae025bf4538d1f9f9506b45015a46a8f6"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RFC5626_INSTANCE_ID;
/**
* Specify SIP outbound (RFC 5626) registration ID.<br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm#a71376e1f32e35401fc6c2c3bcb2087d8"
* >Pjsip documentation</a>
*
* @see String
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RFC5626_REG_ID;

// Video config
/**
* Auto show video of the remote party.<br/>
* TODO : complete when pjsip-2.x stable documentation out
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_VID_IN_AUTO_SHOW;
/**
* Auto transmit video of our party.<br/>
* TODO : complete when pjsip-2.x stable documentation out
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_VID_OUT_AUTO_TRANSMIT;

// RTP config
/**
* Begin RTP port for the media of this account.<br/>
* By default it will use {@link PhonexConfig#PJ_RTP_PORT}
*
* @see Integer
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RTP_PORT;
/**
* Public address to announce in SDP as self media address.<br/>
* Only use if you have static and known public ip on your device regarding
* the sip server. <br/>
* May be helpful in VPN configurations.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RTP_PUBLIC_ADDR;
/**
* Address to bound from client to enforce on interface to be used. <br/>
* By default the application bind all addresses. (0.0.0.0).<br/>
* This is only useful if you want to avoid one interface to be bound, but
* is useless to get audio path correctly working use
* {@link #FIELD_RTP_PUBLIC_ADDR}
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RTP_BOUND_ADDR;
/**
* Should the QoS be enabled on this account.<br/>
* By default it will use {@link PhonexConfig#ENABLE_QOS}.<br/>
* Default value is -1 to use global setting. 0 means disabled, 1 means
* enabled.<br/>
*
* @see Integer
* @see PhonexConfig#ENABLE_QOS
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RTP_ENABLE_QOS;
/**
* The value of DSCP.<br/>
*
* @see Integer
* @see PhonexConfig#DSCP_VAL
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RTP_QOS_DSCP;

/**
* Should the application try to clean registration of all sip clients if no
* registration found.<br/>
* This is useful if the sip server manage limited serveral concurrent
* registrations.<br/>
* Since in this case the registrations may leak in case of failing
* unregisters, this option will unregister all mockContacts previously
* registred.
*
* @see Boolean
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TRY_CLEAN_REGISTERS;
/**
* This option is used to overwrite the "sent-by" field of the Via header
* for outgoing messages with the same interface address as the one in
* the REGISTER request, as long as the request uses the same transport
* instance as the previous REGISTER request. <br/>
*
* Default: true <br/>
* <a target="_blank" href=
* "http://www.pjsip.org/pjsip/docs/html/structpjsua__acc__config.htm"
* >Pjsip documentation</a>
*
* @see Boolean
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ALLOW_VIA_REWRITE;

/**
* Control the use of STUN for the SIP signaling.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_SIP_STUN_USE;

/**
* Control the use of STUN for the transports.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_MEDIA_STUN_USE;

/**
* Control the use of ICE in the account.
* By default, the settings in the pjsua_media_config will be used.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ICE_CFG_USE;

/**
* Enable ICE.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_ICE_CFG_ENABLE;

/**
* Control the use of TURN in the account.
* By default, the settings in the pjsua_media_config will be used.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TURN_CFG_USE;

/**
*  Enable TURN.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TURN_CFG_ENABLE;

/**
*  TURN server.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TURN_CFG_SERVER;

/**
*  TURN username.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TURN_CFG_USER;

/**
*  TURN password.
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_TURN_CFG_PASSWORD;

/**
* Should media use ipv6?
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_IPV6_MEDIA_USE;

/**
* Certificate path in file system.
* Not used in one user setup.
*
* @author ph4r05
* @date 02-03-2013
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CERT_PATH;

/**
* Certificate not before date (when became valid/created).
* @author ph4r05
* @date 02-03-2013
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CERT_NOT_BEFORE;

/**
* Certificate hash.
* @author ph4r05
* @date 02-03-2013
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_CERT_HASH;

/**
* XMPP server name to use.
* @author ph4r05
* @date 25-05-2014
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_XMPP_SERVER;

/**
* XMPP service to connect on the server
* @author ph4r05
* @date 25-05-2014
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_XMPP_SERVICE;

/**
* XMPP user name for login to use.
* @author ph4r05
* @date 25-05-2014
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_XMPP_USER_NAME;

/**
* XMPP password to use for login.
* @author ph4r05
* @date 25-05-2014
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_XMPP_PASSWORD;

/**
* Password recovery email
* @author ph4r05
* @date 18-01-2016
*/
FOUNDATION_EXPORT NSString *PEX_DBUSR_FIELD_RECOVERY_EMAIL;

extern NSString * const PEX_DBUSR_FIELD_LICENSE_TYPE;
extern NSString * const PEX_DBUSR_FIELD_LICENSE_ISSUED_ON;
extern NSString * const PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON;
extern NSString * const PEX_DBUSR_FIELD_LICENSE_EXPIRED;


@interface PEXDbUserProfile : PEXDbModelBase { }
@property (nonatomic) NSNumber * primaryKey; // jint
@property (nonatomic) NSNumber * id; // jlong
@property (nonatomic) NSString * display_name;
@property (nonatomic) NSString * accountManager;
@property (nonatomic) NSNumber * transport;
@property (nonatomic) NSString * default_uri_scheme;
@property (nonatomic) BOOL active; // jboolean
@property (nonatomic) NSNumber * priority; // jint
@property (nonatomic) NSString * acc_id;
@property (nonatomic) NSString * reg_uri;
@property (nonatomic) NSNumber * publish_enabled; // jint
@property (nonatomic) NSNumber * reg_timeout; // jint
@property (nonatomic) NSNumber * ka_interval; // jint
@property (nonatomic) NSString * pidf_tuple_id;
@property (nonatomic) NSString * force_contact;
@property (nonatomic) BOOL allow_contact_rewrite; // jboolean
@property (nonatomic) NSNumber * contact_rewrite_method; // jint
@property (nonatomic) BOOL allow_via_rewrite; // jboolean
@property (nonatomic) NSMutableArray * proxies;
@property (nonatomic) NSString * realm;
@property (nonatomic) NSString * username;
@property (nonatomic) NSString * scheme;
@property (nonatomic) NSNumber * datatype; // jint
@property (nonatomic) NSString * data;
@property (nonatomic) BOOL initial_auth; // jboolean
@property (nonatomic) NSString * auth_algo;
@property (nonatomic) NSNumber * use_srtp; // jint
@property (nonatomic) NSNumber * use_zrtp; // jint
@property (nonatomic) NSNumber * reg_use_proxy; // jint
@property (nonatomic) NSNumber * sip_stack; // jint
@property (nonatomic) NSString * vm_nbr;
@property (nonatomic) NSNumber * reg_delay_before_refresh; // jint
@property (nonatomic) NSNumber * try_clean_registers; // jint
@property (nonatomic) NSArray  * icon;
@property (nonatomic) BOOL use_rfc5626; // jboolean
@property (nonatomic) NSString * rfc5626_instance_id;
@property (nonatomic) NSString * rfc5626_reg_id;
@property (nonatomic) NSNumber * vid_in_auto_show; // jint
@property (nonatomic) NSNumber * vid_out_auto_transmit; // jint
@property (nonatomic) NSNumber * rtp_port; // jint
@property (nonatomic) NSString * rtp_public_addr;
@property (nonatomic) NSString * rtp_bound_addr;
@property (nonatomic) NSNumber * rtp_enable_qos; // jint
@property (nonatomic) NSNumber * rtp_qos_dscp; // jint
@property (nonatomic) NSString * android_group;
@property (nonatomic) BOOL mwi_enabled; // jboolean
@property (nonatomic) NSNumber * sip_stun_use; // jint
@property (nonatomic) NSNumber * media_stun_use; // jint
@property (nonatomic) NSNumber * ice_cfg_use; // jint
@property (nonatomic) NSNumber * ice_cfg_enable; // jint
@property (nonatomic) NSNumber * turn_cfg_use; // jint
@property (nonatomic) NSNumber * turn_cfg_enable; // jint
@property (nonatomic) NSString * turn_cfg_server;
@property (nonatomic) NSString * turn_cfg_user;
@property (nonatomic) NSString * turn_cfg_password;
@property (nonatomic) NSNumber * ipv6_media_use; // jint
@property (nonatomic) NSString * wizard_data;
@property (nonatomic) NSString * cert_path;
@property (nonatomic) NSDate * cert_not_before;
@property (nonatomic) NSString * cert_hash;
@property (nonatomic) NSString * xmpp_server;
@property (nonatomic) NSString * xmpp_service;
@property (nonatomic) NSString * xmpp_user;
@property (nonatomic) NSString * xmpp_password;
@property (nonatomic) NSString * recovery_email;

@property (nonatomic) NSString * licenseType;
@property (nonatomic) NSDate * licenseIssuedOn;
@property (nonatomic) NSDate * licenseExpiresOn;
@property (nonatomic, assign) BOOL licenseExpired;

- (instancetype)init;
- (void)copyAllFieldsTo:(PEXDbUserProfile *)other;
+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getAccProjection;
+(NSArray *) getListableProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;

/**
* Loads array of stored user profiles from database.
* If some parameter is null, it is set to a default value.
* Null projection results in a full projection.
*/
+(NSArray * ) loadFromDatabase: (PEXDbContentProvider *) cr selection: (NSString *) selection
                 selectionArgs: (NSArray *) selectionArs projection: (NSArray *) projection
                     sortOrder: (NSString * ) sortOrder;

/**
* Loads specific user profile with given ID.
* If non-existent profile is queried, nil is returned.
*/
+(PEXDbUserProfile *) getProfileFromDbId: (PEXDbContentProvider *) cr id: (NSNumber *) id projection: (NSArray *) projection;

/**
* Loads specifis user profile with given user name.
* If non-existent profile is queried, nil is returned.
*/
+ (PEXDbUserProfile *)getProfileWithName: (NSString *) name cr: (PEXDbContentProvider *)cr projection:(NSArray *)projection;

/**
* Takes pre-set user profile and sets another user details.
*/
+(void) setDefaultValues: (PEXDbUserProfile *) account;

/**
* Get the default domain for this account
*
* @return the default domain for this account
*/
-(NSString *) getDefaultDomain;

/**
* Gets the display name of the user.
*
* @return the caller id for this account
*/
-(NSString *) getDisplayName;

/**
* Gets the network address of the server outbound proxy.
*
* @return the first proxy server if any else empty string
*/
-(NSString *) getProxyAddress;

/**
* Gets the SIP domain when acc_id is username@domain.
*
* @return the sip domain for this account
*/
-(NSString *) getSipDomain;
/**
* Gets the username when acc_id is username@domain. WARNING : this is
* different from username of SipProfile which is the authentication name
* cause of pjsip naming
*
* @return the username of the account sip id. <br/>
*         Example if acc_id is "Display Name" &lt;sip:user@domain.com&gt;, it
*         will return user.
*/
-(NSString *) getSipUserName;


@end