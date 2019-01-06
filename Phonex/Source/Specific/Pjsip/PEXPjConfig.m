//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjConfig.h"
#import "pjsua-lib/pjsua.h"
#import "PEXPjWrapper.h"
#import "PEXUserPrivate.h"
#import "PEXSipUri.h"
#import "PEXUtils.h"
#import "NSBundle+PEXResCrypto.h"
#import "PEXSecurityCenter.h"
#import "PEXDBUserProfile.h"
#import "PEXDbAppContentProvider.h"
#import "PEXService.h"
#import "PEXPjConfigPrefs.h"
#import "pj/sock.h"
#import "PEXAppVersionUtils.h"
#include <netinet/tcp.h>

const size_t MAX_SIP_ID_LENGTH = 128;
const size_t MAX_SIP_REG_URI_LENGTH = 128;

const unsigned PEX_PJ_DEF_ACC_KA_INTERVAL = 60;
const unsigned PEX_PJ_DEF_ACC_REG_DELAY_BEFORE_REFRESH = 25;
const unsigned PEX_PJ_DEF_ACC_REG_TIMEOUT = 330;
const pj_uint32_t PEX_PJ_DEF_ACC_REGISTER_TSX_TIMEOUT = 23000;

NSInteger PEX_PJ_DEF_TLS_KA = 1;
NSInteger PEX_PJ_DEF_TLS_NODELAY = 1;
NSInteger PEX_PJ_DEF_TLS_KA_IDLE = 30;
NSInteger PEX_PJ_DEF_TLS_KA_INTERVAL = 90;

@implementation PEXPjConfig {

}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}

+ (instancetype)configWithPrivData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithPrivData:privData];
}

- (pj_status_t)preparePool {
    /* Create memory pool for application. */
    if(_pool == NULL){
        @synchronized (self) {
            if (_pool == NULL) {
                _pool = pjsua_pool_create("pjConfig", 1024, 1024);
                DDLogVerbose(@"%@: Pool allocated", THIS_FILE);
            }
        };

        PJ_ASSERT_RETURN(_pool, PJ_ENOMEM);
    }

    return PJ_SUCCESS;
}

- (pj_status_t)releasePool {
    if (_pool) {
        pj_pool_release(_pool);
        _pool = NULL;
    }

    return PJ_SUCCESS;
}

- (pj_status_t)resetPool {
    if (_pool) {
        _pool = NULL;
    }

    return PJ_SUCCESS;
}

- (pj_pool_t *)memPool {
    if (_pool == NULL){
        [self preparePool];
    }
    return _pool;
}

- (NSString *)getZrtpFile {
    return [PEXSecurityCenter getZrtpFile:self.privData.username];
}

- (void)configureAll {
    [self configureLogging:&_log_cfg];
    [self configurePjmedia:&_media_cfg];
    [self configurePjsua:&_cfg];
}

- (void)configureLogging:(pjsua_logging_config *)cfg {
    pjsua_logging_config_default(cfg);
    cfg->cb = pex_pjsip_log_msg;
    cfg->console_level = 5;
    cfg->level = 5;
    cfg->log_filename.ptr = NULL;
    cfg->log_filename.slen = 0;
}

- (void)configurePjsua:(pjsua_config *)cfg {
    pjsua_config_default (cfg);
    cfg->cb = wrapper_callback_struct;

    [self preparePool];
    NSString * userAgent = [NSString stringWithFormat:@"%s.v%@", PEX_PHONEX_SIP_USER_AGENT, [PEXAppVersionUtils fullVersionString]];
    pj_strdup2_with_null(_pool, &cfg->user_agent, [userAgent cStringUsingEncoding:NSUTF8StringEncoding]);

    // This is on purpose. ZRTP starts own SRTP.
    cfg->use_srtp = PJMEDIA_SRTP_DISABLED;
    cfg->nat_type_in_sdp = 0;

    // STUN.
    if (self.privData != nil) {
        PEXSIPURIParsedSipContact *parsed = [PEXSipUri parseSipContact:self.privData.username];
        if (parsed == nil || [PEXUtils isEmpty:parsed.domain]) {
            DDLogWarn(@"Cannot initialize account, empty domain [%@]", self.privData.username);
        } else {
            // IPV6-only network crashes on this.
            // Only IPV4 STUN is supported. Failed STUN transaction breaks the PJSIP.
            //

            cfg->stun_srv_cnt = 1;
            pj_strdup2_with_null(_pool, &cfg->stun_srv[0], [parsed.domain cStringUsingEncoding:NSUTF8StringEncoding]);

            cfg->stun_map_use_stun2 = YES;
            cfg->stun_ignore_failure = YES;

            DDLogInfo(@"STUN server configured");
        }
    }

    // We may consider modifying SIP settings here.
    pjsip_sip_cfg_var;

    // Current system nameservers + default ones are set to the configuration.
    // This enables us to use ASYNC DNS resolver, so the code is not blocked in some parts, especially on
    // stack start.
    [self configureDns:cfg pool:_pool];

    // Configure DNS resolver query parameters.
    // If connectivity is off, set minimal parameters so query fails very fast.
    // If connectivity is on, set parameters so app starts quickly even with 100% packet loss (STUN resolving).
    if ([[PEXService instance] isConnectivityWorking]){
        cfg->resolver_retry = 1;
        cfg->resolver_delay = PJ_DNS_RESOLVER_QUERY_RETRANSMIT_DELAY;
    } else {
        cfg->resolver_retry = 0;
        cfg->resolver_delay = 250;
        DDLogVerbose(@"No connection when configuring, minimal DNS resolver parameters set");
    }
}

/**
 * Current system nameservers + default ones are set to the configuration.
 * This enables us to use ASYNC DNS resolver, so the code is not blocked in some parts, especially on
 * stack start.
 */
- (BOOL) configureDns:(pjsua_config *)cfg pool:(pj_pool_t *) pool {
    NSArray * dnsList = [PEXUtils getDNS:YES wantIpv6:YES];
    const unsigned dnsCnt = [dnsList count];
    if (dnsList == nil || dnsCnt == 0){
        DDLogError(@"DNS list is empty");
        return NO;
    }

    cfg->nameserver_count = dnsCnt >= 4 ? 4u : dnsCnt;
    for(unsigned i = 0; i < dnsCnt && i < 4; i++){
        NSString * curDns = dnsList[i];
        DDLogVerbose(@"Adding DNS server: %@, %u/%u", curDns, i, dnsCnt);
        pj_strdup2_with_null(pool, &cfg->nameserver[i], [curDns cStringUsingEncoding:NSUTF8StringEncoding]);
    }

    return YES;
}

- (void)configurePjmedia:(pjsua_media_config *)cfg {
    pjsua_media_config_default(cfg);
    [self preparePool];

    // Enable ICE by default.
    cfg->enable_ice = YES;
    cfg->channel_count = 1;
    cfg->snd_auto_close_time = 2;
    cfg->ec_tail_len = 200;
    cfg->has_ioqueue = YES;

    // TODO: set echo cancellation type.
    // TODO: set thread count.
    // TODO: set vad option.
    // TODO: set media quality.
    // TODO: set clock ratio.
    // TODO: set audio_frame_ptime.
    // TODO: set media thread count.
    // TODO: set has ioqueue.

    // TURN configuration.
    if (self.privData != nil) {
        PEXSIPURIParsedSipContact *parsed = [PEXSipUri parseSipContact:self.privData.username];

        // Load TURN credentials for given user.
        PEXDbUserProfile * dbUser = [PEXDbUserProfile getProfileFromDbId:[PEXDbAppContentProvider instance]
                                                                      id:self.privData.accountId
                                                              projection:[PEXDbUserProfile getFullProjection]];

        if (parsed == nil || [PEXUtils isEmpty:parsed.domain] || dbUser == nil) {
            DDLogWarn(@"Cannot initialize account, empty domain [%@] / empty user [%@]", self.privData.username, dbUser);

        } else {
            cfg->enable_turn = YES;
            pj_strdup2_with_null(_pool, &cfg->turn_server,
                    [[NSString stringWithFormat:@"turn.%@:3477", parsed.domain] cStringUsingEncoding:NSUTF8StringEncoding]);

            [self setTurnCredentials:dbUser.turn_cfg_user password:dbUser.turn_cfg_password realm:parsed.domain auth_cred:&_turn_creds];
            cfg->turn_auth_cred = _turn_creds;

            DDLogInfo(@"TURN server configured");
        }
    }
}

- (void)configureTransports {
    NSNumber * udpAcc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_UDP port:0 cfg:&_udpCfg];
    if (udpAcc == nil){
        DDLogError(@"Cannot create UDP transport");
        // TODO: destroy.
    }

    NSNumber * tcpAcc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_TCP port:0 cfg:&_tcpCfg];
    if (tcpAcc == nil){
        DDLogError(@"Cannot create TCP transport");
        // TODO: destroy.
    }

    NSNumber * tlsAcc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_TLS port:0 cfg:&_tlsCfg];
    if (tlsAcc == nil){
        DDLogError(@"Cannot create TLS transport");
        // TODO: destroy.
    }

    NSNumber * udp6Acc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_UDP6 port:0 cfg:&_udp6Cfg];
    if (udp6Acc == nil){
        DDLogError(@"Cannot create UDP transport");
        // TODO: destroy.
    }

    NSNumber * tcp6Acc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_TCP6 port:0 cfg:&_tcp6Cfg];
    if (tcp6Acc == nil){
        DDLogError(@"Cannot create TCP transport");
        // TODO: destroy.
    }

    NSNumber * tls6Acc = [self configureLocalTransportAndAccount:PJSIP_TRANSPORT_TLS6 port:0 cfg:&_tls6Cfg];
    if (tls6Acc == nil){
        DDLogError(@"Cannot create TLS transport");
        // TODO: destroy.
    }
}

- (NSNumber *)configureLocalTransport:(pjsip_transport_type_e)type port:(int)port cfg: (pjsua_transport_config*) cfg {
    int transportId = -1;
    int status;
    pjsua_transport_config_default(cfg);
    cfg->port = (unsigned) port;
    [self preparePool];

    if (type == PJSIP_TRANSPORT_TLS || type == PJSIP_TRANSPORT_TLS6) {
        pjsip_tls_setting tlsSetting = cfg->tls_setting;
        pjsip_tls_setting_default(&tlsSetting);

        NSString * caListFile = [[NSBundle mainBundle] pathForCARoots]; //self.privData == nil ? nil : self.privData.pemCAPath;
        if (![PEXUtils isEmpty:caListFile]) {
            DDLogVerbose(@"%@ CA file added: %@", THIS_FILE, caListFile);
            pj_strdup2_with_null(_pool, &tlsSetting.ca_list_file, [caListFile cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        NSString * certFile = self.privData == nil ? nil : self.privData.pemCrtPath;
        if (![PEXUtils isEmpty:certFile]) {
            DDLogVerbose(@"%@ Cert file added: %@", THIS_FILE, certFile);
            pj_strdup2_with_null(_pool, &tlsSetting.cert_file, [certFile cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        NSString * privKey = self.privData == nil ? nil : self.privData.pemKeyPath;
        if (![PEXUtils isEmpty:privKey]) {
            DDLogVerbose(@"%@ PirvKey file added: %@", THIS_FILE, privKey);
            pj_strdup2_with_null(_pool, &tlsSetting.privkey_file, [privKey cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        NSString * pemPass = self.privData == nil ? nil : self.privData.pemPass;
        if (![PEXUtils isEmpty:pemPass]) {
            DDLogVerbose(@"%@ PEM password set", THIS_FILE);
            pj_strdup2_with_null(_pool, &tlsSetting.password, [pemPass cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        tlsSetting.verify_client = YES;
        tlsSetting.verify_server = YES;
        tlsSetting.method = PJSIP_TLSV1_2_METHOD;

        // TODO: set cipher methods.
        // ...

        // TLS socket properties are set in a specific structure - tlsSettings.sockopt_params
        PEXPjConfigPrefs * configPrefs = [PEXPjConfigPrefs prefsFromSettings];
        [self configureSocketOptions:&tlsSetting.sockopt_params pool:_pool
                           keepAlive:configPrefs.tls_ka
                       keepAliveIdle:configPrefs.tls_ka_idle
                      keepAliveIntvl:configPrefs.tls_ka_interval
                             noDelay:configPrefs.tls_noDelay];

        cfg->tls_setting = tlsSetting;
    }

    // Keep alive settings for TCP.
    if (type == PJSIP_TRANSPORT_TLS
            || type == PJSIP_TRANSPORT_TLS6
            || type == PJSIP_TRANSPORT_TCP6
            || type == PJSIP_TRANSPORT_TCP){
        PEXPjConfigPrefs * configPrefs = [PEXPjConfigPrefs prefsFromSettings];
        [self configureSocketOptions:&cfg->sockopt_params pool:_pool
                           keepAlive:configPrefs.tls_ka
                       keepAliveIdle:configPrefs.tls_ka_idle
                      keepAliveIntvl:configPrefs.tls_ka_interval
                             noDelay:configPrefs.tls_noDelay];
    }

    // TODO: QOS ?
    // ...

    status = pjsua_transport_create(type, cfg, &transportId);
    if (status != PJ_SUCCESS) {
        const int bufSize = 512;
        char msgBuff[bufSize];
        pj_str_t errorString = pj_strerror(status, msgBuff, bufSize);

        DDLogError(@"Error in creating a transport, error=[%.*s], code=%d", (int)errorString.slen, errorString.ptr, status);
        if (status == 120098) { /* Already binded */
            DDLogError(@"Another application uses SIP port.");
        }

        DDLogError(@"Cannot create transport, type=%d", type);
        // TODO: notify message error.

        return nil;
    }

    DDLogVerbose(@"Created transport %d, port: %d, id: %d", type, port, transportId);
    return transportId == -1 ? nil : @(transportId);
}

/**
 * Configures socket keep-alive options for PJSIP.
 */
- (void) configureSocketOptions: (pj_sockopt_params *) params pool: (pj_pool_t *) pool
                      keepAlive: (NSNumber *) keepAlive keepAliveIdle: (NSNumber *) keepAliveIdle
                 keepAliveIntvl: (NSNumber *) keepAliveIntvl
                        noDelay: (NSNumber *) noDelay
{
    if (keepAliveIntvl != nil || keepAliveIdle != nil) {
        keepAlive = @(1);
    }

    if (params->cnt != 0){
        DDLogError(@"Error, socket parameters already set: %u", params->cnt);
    }

    const unsigned int cnt = 1 + (unsigned)(keepAlive != nil) + (keepAliveIdle != nil) + (keepAliveIntvl != nil) + (noDelay != nil);
    params->cnt = cnt;

    // Socket options needs pointer to a value, socket options will need the value for some time, it is not applied
    // in this call thus socket options have to be allocated in a pool.
    int * poolMemory = (int*) pj_pool_alloc(pool, sizeof(int) * cnt);
    if (poolMemory == NULL){
        DDLogError(@"Unable to set socket properties, pool memory allocation failed");
        return;
    }

    unsigned optionIdx = 0;
    if (keepAlive != nil && optionIdx < PJ_MAX_SOCKOPT_PARAMS){
        poolMemory[optionIdx] = [keepAlive integerValue];
        params->options[optionIdx].level = SOL_SOCKET;
        params->options[optionIdx].optname = SO_KEEPALIVE;
        params->options[optionIdx].optval = &poolMemory[optionIdx];
        params->options[optionIdx].optlen = sizeof(int);
        DDLogVerbose(@"KeepAliveValue: %d, idx: %u", poolMemory[optionIdx], optionIdx);
        ++optionIdx;
    }

    if (noDelay != nil && optionIdx < PJ_MAX_SOCKOPT_PARAMS){
        poolMemory[optionIdx] = [noDelay integerValue];
        params->options[optionIdx].level = IPPROTO_TCP;
        params->options[optionIdx].optname = PJ_TCP_NODELAY;
        params->options[optionIdx].optval = &poolMemory[optionIdx];
        params->options[optionIdx].optlen = sizeof(int);
        DDLogVerbose(@"NoDelay: %d, idx: %u", poolMemory[optionIdx], optionIdx);
        ++optionIdx;
    }

    //Idle time used when SO_KEEPALIVE is enabled. Sets how long connection must be idle before keepalive is sent
    if (keepAliveIdle != nil && optionIdx < PJ_MAX_SOCKOPT_PARAMS){
        poolMemory[optionIdx] = [keepAliveIdle integerValue];
        params->options[optionIdx].level = IPPROTO_TCP;
        params->options[optionIdx].optname = TCP_KEEPALIVE;
        params->options[optionIdx].optval = &poolMemory[optionIdx];
        params->options[optionIdx].optlen = sizeof(int);
        DDLogVerbose(@"KeepAliveIdle: %d, idx: %u", poolMemory[optionIdx], optionIdx);
        ++optionIdx;
    }

    //Interval between keepalives when there is no reply. Not same as idle time
    if (keepAliveIntvl != nil && optionIdx < PJ_MAX_SOCKOPT_PARAMS){
        poolMemory[optionIdx] = [keepAliveIntvl integerValue];
        params->options[optionIdx].level = IPPROTO_TCP;
        params->options[optionIdx].optname = TCP_KEEPINTVL;
        params->options[optionIdx].optval = &poolMemory[optionIdx];
        params->options[optionIdx].optlen = sizeof(int);
        DDLogVerbose(@"KeepAliveInterval: %d, idx: %u", poolMemory[optionIdx], optionIdx);
        ++optionIdx;
    }

    if (optionIdx < PJ_MAX_SOCKOPT_PARAMS){
        poolMemory[optionIdx] = 1;
        params->options[optionIdx].level = SOL_SOCKET;
        params->options[optionIdx].optname = SO_REUSEADDR;
        params->options[optionIdx].optval = &poolMemory[optionIdx];
        params->options[optionIdx].optlen = sizeof(int);
        DDLogVerbose(@"ReuseAddr: %d, idx: %u", poolMemory[optionIdx], optionIdx);
        ++optionIdx;
    }
}

- (NSNumber *)configureLocalAccount:(NSNumber *)transportId {
    if (transportId == nil){
        return nil;
    }

    int accId = -1;
    pjsua_acc_add_local((int)[transportId integerValue], NO, &accId);
    return @(accId);
}

- (NSNumber *)configureLocalTransportAndAccount:(pjsip_transport_type_e)type port:(int)port cfg: (pjsua_transport_config*) cfg {
    NSNumber * transportId = [self configureLocalTransport:type port:port cfg:cfg];
    return [self configureLocalAccount:transportId];
}

-(pj_status_t) setTurnCredentials: (NSString *) username password: (NSString *) password realm: (NSString *) realm
                        auth_cred: (pj_stun_auth_cred *) turn_auth_cred
{
    PJ_ASSERT_RETURN(turn_auth_cred, PJ_EINVAL);
    PJ_ASSERT_RETURN([self preparePool] == PJ_SUCCESS, PJ_ENOMEM);

    if (![PEXUtils isEmpty:username]) {
        turn_auth_cred->type = PJ_STUN_AUTH_CRED_STATIC;
        pj_strdup2_with_null(_pool,
                &turn_auth_cred->data.static_cred.username,
                [username cStringUsingEncoding:NSUTF8StringEncoding]);
    } else {
        turn_auth_cred->data.static_cred.username.slen = 0;
    }

    if(![PEXUtils isEmpty:password]) {
        turn_auth_cred->data.static_cred.data_type = PJ_STUN_PASSWD_PLAIN;
        pj_strdup2_with_null(_pool,
                &turn_auth_cred->data.static_cred.data,
                [password cStringUsingEncoding:NSUTF8StringEncoding]);
    } else {
        turn_auth_cred->data.static_cred.data.slen = 0;
    }

    if(![PEXUtils isEmpty:realm]) {
        pj_strdup2_with_null(_pool,
                &turn_auth_cred->data.static_cred.realm,
                [realm cStringUsingEncoding:NSUTF8StringEncoding]);
    } else {
        turn_auth_cred->data.static_cred.realm = pj_str("*");
    }

    return PJ_SUCCESS;
}

- (void)configureAccount:(pjsua_acc_config *)acc {
    pjsua_acc_config_default(acc);
    if (self.privData != nil){
        [self configureAccount:acc withPrivData:self.privData error:nil];
    }
}

- (BOOL)configureAccount:(pjsua_acc_config *)acc withPrivData:(PEXUserPrivate *)privData error:(NSError **) pError{
    pjsua_acc_config_default(acc);

    PEXSIPURIParsedSipContact * parsed = [PEXSipUri parseSipContact:privData.username];
    if (parsed == nil || [PEXUtils isEmpty:parsed.domain]){
        DDLogWarn(@"Cannot initialize account, empty domain [%@]", privData.username);
        // TODO: set error.

        return NO;
    }

    [self preparePool];

    // Account ID
    char sipId[MAX_SIP_ID_LENGTH];
    snprintf(sipId, MAX_SIP_ID_LENGTH, "sips:%s", [privData.username cStringUsingEncoding:NSUTF8StringEncoding]);
    pj_strdup2_with_null(_pool, &acc->id, sipId);

    // Reg URI
    char regUri[MAX_SIP_REG_URI_LENGTH];
    snprintf(regUri, MAX_SIP_REG_URI_LENGTH, "sips:%s", [parsed.domain cStringUsingEncoding:NSUTF8StringEncoding]);
    pj_strdup2_with_null(_pool, &acc->reg_uri, regUri);

    // Read some settings from preferences, configured by the server.
    PEXPjConfigPrefs * configPrefs = [PEXPjConfigPrefs prefsFromSettings];
    DDLogVerbose(@"Going to configure PJSIP with settings: %@", configPrefs);

    // Keep alive interval set to zero, we do keep-alive on transports with PJSIP_TLS_KEEP_ALIVE_INTERVAL.
    acc->ka_interval = configPrefs.acc_ka_interval;
    acc->publish_enabled = NO;

    // CRLF CRLF client ping-pong keep-alive.
    acc->use_rfc5626 = YES;

    // Keep active calls as long as possible.
    acc->drop_calls_on_reg_fail = NO;

    // EXPERIMENTAL
    acc->reg_delay_before_refresh = configPrefs.acc_reg_delay_before_refresh;
    acc->reg_timeout = configPrefs.acc_reg_timeout;  // For this big registration period we really need outbound ping.

    // Maximum register transaction keep-alive is set to 23 seconds so we don't spend too long in iOS keep-alive block.
    acc->register_tsx_timeout = configPrefs.acc_register_tsx_timeout;

    // Re-registration retry time, set to 60 seconds.
    acc->reg_retry_interval = 60;

    // Quick re-registration is quite instant. Is randomized by 10 seconds by default.
    acc->reg_first_retry_interval = 0;

    // Let first 5 re-registration attempts perform with a quick reconnection.
    acc->reg_attempts_quick_retry = 5;

    // Enable IPv6 in media transport
    acc->ipv6_media_use = PJSUA_IPV6_ENABLED;

    // Account cred info
    acc->cred_count = 1;
    acc->cred_info[0].scheme = pj_str("digest");
    acc->cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    pj_strdup2_with_null(_pool, &(acc->cred_info[0].realm), [parsed.domain cStringUsingEncoding:NSUTF8StringEncoding]);
    pj_strdup2_with_null(_pool, &(acc->cred_info[0].username), [privData.username cStringUsingEncoding:NSUTF8StringEncoding]);
    pj_strdup2_with_null(_pool, &(acc->cred_info[0].data), [privData.pass cStringUsingEncoding:NSUTF8StringEncoding]);
    return YES;
}

- (pjsua_config *)getPjsuaConfig {
    return &_cfg;
}

- (pjsua_logging_config *)getLoggingConfig {
    return &_log_cfg;
}

- (pjsua_media_config *)getMediaConfig {
    return &_media_cfg;
}

- (BOOL)updateConfigFromServer:(NSDictionary *)settings privData:(PEXUserPrivate *)privData {
    return [PEXPjConfigPrefs updateFromServerSettings:settings privData:privData];
}

@end