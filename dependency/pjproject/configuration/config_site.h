#define PJ_CONFIG_IPHONE 1

/*
 * PJLIB settings.
 */

/* Both armv6 and armv7 has FP hardware support.
 * See https://trac.pjsip.org/repos/ticket/1589 for more info
 */
#define PJ_HAS_FLOATING_POINT        1

// Endiannes configuration - auto detection by compiler & target platform.
#define PJ_AUTOCONF 1

// This enables SSL & TLS.
#define PJ_HAS_SSL_SOCK 1

// IPV6 support enabled
#define PJ_HAS_IPV6 1

// Maximal number of PJ Modules. Pay attention that for some
// features one module is created per user. We don't use this.
#define PJSIP_MAX_MODULE 64

// Maximal packet length - has to be enlarged. 
#define PJSIP_MAX_PKT_LEN 10000

// Our modification to assertions - log them.
#define PH_ASSERT 1
//#define PJ_DEBUG 1
#define PJ_LOG_MAX_LEVEL 5

// Disable extra checks.
//#define PJ_ENABLE_EXTRA_CHECK 0

// Redefine software name
#define PJNATH_STUN_SOFTWARE_NAME "phonex"

// Enable SPEEX codec.
#define PJMEDIA_HAS_SPEEX_CODEC 1

// Enables ZRTP.
#define PJMEDIA_HAS_ZRTP 1

// Default keep alive times for STUN & ICE.
#define PJ_STUN_KEEP_ALIVE_SEC 90
#define PJ_ICE_SESS_KEEP_ALIVE_MIN 90
#define PJSIP_TLS_KEEP_ALIVE_INTERVAL 90
#define PJSIP_TCP_KEEP_ALIVE_INTERVAL 90

// Cache auth header.
#define PJSIP_AUTH_HEADER_CACHING 1

// TCP log buffer size.
#define PJSIP_TCP_TRANSPORT_BACKLOG 50

// Disable conference bridge for now.
#define PJMEDIA_CONF_USE_SWITCH_BOARD 0

// QoS from BSD.
#define PJ_QOS_IMPLEMENTATION PJ_QOS_BSD

// Do not bother with via header.
#define PJSIP_CHECK_VIA_SENT_BY 0

// Increase limits for STUN/ICE as we have a lot more candidates nowadays
#define PJ_STUN_MAX_ATTR			    32

// Was 800 by default
#define PJ_STUN_MAX_PKT_LEN			    2000
#define PJ_STUN_SOCK_PKT_LEN			3000

// Maximum number of candidates for each ICE stream transport component.
// Usually we have 2 components: RTP, RTCP.
// Client can be multihomed - more host IPs, IPv6 addresses...
// One candidate slot is reserved for a relay server, another can be host candidates. There are
// stun_cfg->max_host_cands host candidates - by default 64.
#define PJ_ICE_ST_MAX_CAND			    8

// Maximal number of ICE candidates
// All candidates for all components, usually should be
// 2 * PJ_ICE_ST_MAX_CAND
// lcand[PJ_ICE_MAX_CAND]  .. number of overall local candidates
#define PJ_ICE_MAX_CAND			        (2*PJ_ICE_ST_MAX_CAND)

// If number of checks is higher, call ends with 488 error PJ_ETOOMANY.
// Check: each local candidate stream component matched with each remote candidate.
// Number of checks has to be:
//   #local_components_idx1 * #remote_components_idx1 + #local_components_idx2 * #remote_components_idx2
//   2*PJ_ICE_ST_MAX_CAND*PJ_ICE_ST_MAX_CAND
#define PJ_ICE_MAX_CHECKS			    (2*PJ_ICE_ST_MAX_CAND*PJ_ICE_ST_MAX_CAND)

/*
 * PJMEDIA settings
 */

/* We have our own native CoreAudio backend */
#define PJMEDIA_AUDIO_DEV_HAS_PORTAUDIO    0
#define PJMEDIA_AUDIO_DEV_HAS_WMME        0
#define PJMEDIA_AUDIO_DEV_HAS_COREAUDIO    1

/* Workaround to keep silent mode working for ringing call */
#define COREAUDIO_DO_NOT_SET_CATEGORY 1

/* The CoreAudio backend has built-in echo canceller! */
#define PJMEDIA_HAS_SPEEX_AEC    0

/* Disable some codecs */
#define PJMEDIA_HAS_L16_CODEC        0
#define PJMEDIA_HAS_G722_CODEC        0

/* Use the built-in CoreAudio's iLBC codec (yay!) */
#define PJMEDIA_HAS_ILBC_CODEC        1
#define PJMEDIA_ILBC_CODEC_USE_COREAUDIO    1

/* Fine tune Speex's default settings for best performance/quality */
#define PJMEDIA_CODEC_SPEEX_DEFAULT_QUALITY    5

// TODO: enable resampling with libresample
//#define PJMEDIA_RESAMPLE_IMP              PJMEDIA_RESAMPLE_NONE
//#define PJMEDIA_RESAMPLE_IMP                PJMEDIA_RESAMPLE_LIBRESAMPLE

/*
 * PJSUA settings.
 */

/* Default codec quality, previously was set to 5, however it is now
* set to 4 to make sure pjsua instantiates resampler with small filter.
*/
#define PJSUA_DEFAULT_CODEC_QUALITY        4

// Maximal number of transactions, dialogs and calls set to min.
#define PJSIP_MAX_TSX_COUNT        63
#define PJSIP_MAX_DIALOG_COUNT        63
#define PJSUA_MAX_CALLS            8

// Number of PJSIP accounts.
// We have to care about local accounts. So upscale it.
#define PJSUA_MAX_ACC            12

#define PJSUA_MAX_PLAYERS            8
#define PJSUA_MAX_RECORDERS            8
#define PJSUA_MAX_CONF_PORTS        (PJSUA_MAX_CALLS+2*PJSUA_MAX_PLAYERS)

// We do not use SIP presence mechanism, decrease memory fingerprint
#define PJSUA_MAX_BUDDIES            4

/* Seems to fix problems when restarting too frequently */
#define PJ_IOQUEUE_MAX_HANDLES        1024

/**
 * Default retransmission delay, in miliseconds. The combination of 
 * retransmission delay and count determines the query timeout.
 *
 * Default: 2000 (2 seconds, according to RFC 1035)
 */
#define PJ_DNS_RESOLVER_QUERY_RETRANSMIT_DELAY   2000

/**
 * Maximum number of transmissions before timeout is declared for
 * the query.
 *
 * Default: 5
 * We set to 2 as this default number is used during pjsua_init() and
 * if connectivity is not working properly pjsua_init() blocks for a long time.
 */
#define PJ_DNS_RESOLVER_QUERY_RETRANSMIT_COUNT   2

