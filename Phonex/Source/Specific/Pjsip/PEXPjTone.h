//
// Created by Dusan Klinec on 10.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "pexpj.h"

@class PEXPjConfig;
@class PEXPjCall;

static void tone_timer_callback(pj_timer_heap_t *ht, pj_timer_entry *e);
static void tone_timer_start_callback(pj_timer_heap_t *ht, pj_timer_entry *e);

@interface PEXPjTone : NSObject
@property(nonatomic, weak) PEXPjConfig * config;

- (instancetype)initWithConfig:(PEXPjConfig *)config;
+ (instancetype)toneWithConfig:(PEXPjConfig *)config;

/**
* Initialize ringing tone, should be called when pjsua_init is called.
*/
-(pj_status_t)tone_init;

/**
* Destroys ringing tone, releases allocated resources.
* Should be called prior pjsua_destroy() call.
*/
-(void)tone_destroy;

/**
 * Returns complete duration of a tone.
 */
+ (unsigned long) compute_tone_duration: (int) tone_cnt tone:(pjmedia_tone_desc *) tone;

// ---------------------------------------------
#pragma mark - Tone playback control
// ---------------------------------------------

/**
* Starts ringing.
*/
-(BOOL) tone_start: (pjsua_call_id) call_id;

/**
* Stops current ringing.
*/
-(BOOL) tone_stop: (pjsua_call_id) call_id;

// ---------------------------------------------
#pragma mark - Tone scheduling
// ---------------------------------------------
-(pj_status_t) tone_schedule_stop: (int32_t) time;
-(pj_status_t) tone_schedule_start: (int32_t) time;
-(pj_status_t) tone_cancel_timer: (int32_t) time;

-(pj_status_t) tone_timer_schedule_stop: (int32_t) time;
-(pj_status_t) tone_timer_schedule_start: (int32_t) time;
-(pj_status_t) tone_timer_cancel_timer: (int32_t) time;

-(pj_status_t) tone_dispatch_schedule_stop: (int32_t) time;
-(pj_status_t) tone_dispatch_schedule_start: (int32_t) time;
-(pj_status_t) tone_dispatch_cancel_timer: (int32_t) time;


-(void) timer_callback_fired: (pj_timer_heap_t *)ht e: (pj_timer_entry *)e;
-(void) timer_start_callback_fired: (pj_timer_heap_t *)ht e: (pj_timer_entry *)e;

// ---------------------------------------------
#pragma mark - Child tone API
// ---------------------------------------------

-(NSString *) tone_name;
-(unsigned int) tone_cnt;
-(unsigned long) tone_duration;
-(void) tone_set:(pjmedia_tone_desc *) tone;
-(BOOL) tone_isLoop;
-(BOOL) tone_autoStopNoLoop;

// ---------------------------------------------
#pragma mark - Call state handlers
// ---------------------------------------------

/**
* Receives call state event here.
* Starts ringing tone when appropriate.
*/
-(void) on_call_state:(pjsua_call_id)call_id
                event:(pjsip_event *)e
            call_info: (pjsua_call_info * ) call_info
         call_session: (PEXPjCall *) call_session;

/**
* Media update of the call.
* Stops ringing.
*/
- (void) on_call_media_state:(pjsua_call_id)call_id call_info: (pjsua_call_info *) pjsua_call_info;

- (pj_status_t)on_call_media_transport_state:(pjsua_call_id)call_id info:(const pjsua_med_tp_state_info *)info;

@end