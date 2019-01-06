//
// Created by Dusan Klinec on 10.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjTone.h"
#import "PEXPjConfig.h"
#import "PEXPjUtils.h"
#import "PEXPjTone_protected.h"
#import "pjsua-lib/pjsua_internal.h"
#import "PEXPjCall.h"
#import "PEXPjManager.h"

@implementation PEXPjTone {

}

- (instancetype)initWithConfig:(PEXPjConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        _tone_on = PJ_FALSE;
        _tone_port = NULL;
        _tone_cnt = 0;
        _tone_slot = PJSUA_INVALID_ID;
        _tone_initialized = NO;
        _tone_duration = 0;
        _pool = nil;
        _tone = NULL;
    }

    return self;
}

+ (instancetype)toneWithConfig:(PEXPjConfig *)config {
    return [[self alloc] initWithConfig:config];
}

+ (unsigned long)compute_tone_duration:(int)tone_cnt tone:(pjmedia_tone_desc *)tone {
    unsigned long duration = 0ul;
    int i;
    for(i = 0; i < tone_cnt; i++){
        duration += (unsigned long) tone[i].on_msec;
        duration += (unsigned long) tone[i].off_msec;
    }

    return duration;
}

-(pj_status_t)tone_init {
    _tone_slot = PJSUA_INVALID_ID;
    _tone_on = PJ_FALSE;
    _tone_cnt = 0;
    _tone_initialized = NO;
    _tone_port = NULL;
    _tone = NULL;

    // Prepare memory pool.
    if (self.config == nil){
        DDLogError(@"Configuration is nil, cannot init ringback");
        return PJ_EINVAL;
    }
    [self.config preparePool];
    _pool = self.config.memPool;

    // Check tone sanity.
    unsigned int toneCnt = [self tone_cnt];
    if (toneCnt == 0){
        DDLogError(@"Cannot init tone with 0 tones");
        return PJ_EINVAL;
    }

    // Loops
    unsigned options = [self tone_isLoop] ? PJMEDIA_TONEGEN_LOOP : 0u;

    // Copy tone name, it is not copied in tonegen_create2, just assigned.
    pj_str_t name = {NULL, 0};
    [PEXPjUtils assignToPjString:[self tone_name] pjstr:&name];

    // Create tone port.
    pj_status_t status = pjmedia_tonegen_create2(_pool, &name, 16000, 1, 320, 16, options, &_tone_port);
    if (status != PJ_SUCCESS){
        DDLogError(@"Cannot create a new tone");
        return status;
    }

    // Initialize timer.
    _tone_timer_heap = pjsip_endpt_get_timer_heap(pjsua_var.endpt);

    // Create a tone.
    _tone = (pjmedia_tone_desc *) pj_pool_zalloc(_pool, sizeof(pjmedia_tone_desc) * toneCnt);
    pj_bzero(_tone, sizeof(pjmedia_tone_desc) * toneCnt);
    [self tone_set:_tone];

    // Compute tone duration for auto-stop.
    _tone_duration = [self tone_duration];

    // If tone is a loop, this is done only once.
    if ([self tone_isLoop]){
        [self tone_init_tonePlay];
    }

    _tone_initialized = YES;
    return status;
}

-(pj_status_t) tone_init_tonePlay {
    unsigned int toneCnt = [self tone_cnt];
    unsigned options = [self tone_isLoop] ? PJMEDIA_TONEGEN_LOOP : 0u;

    // Stop at first to release resources.
    pj_status_t status = pjmedia_tonegen_stop(_tone_port);
    if (status != PJ_SUCCESS){
        DDLogError(@"Could not stop tone");
    }

    status = pjmedia_tonegen_play(_tone_port, toneCnt, _tone, options);
    if (status != PJ_SUCCESS){
        DDLogError(@"Cannot set tone data");
        return status;
    }

    if (_tone_slot == PJSUA_INVALID_ID){
        status = pjsua_conf_add_port(_pool, _tone_port, &_tone_slot);
        if (status != PJ_SUCCESS){
            DDLogError(@"Cannot add tone to conf");
            return status;
        }
    }

    DDLogVerbose(@"Tone %@ play port, port=%p, slot=%d",
            [self tone_name], _tone_port, _tone_slot);

    return status;
}

-(void)tone_destroy {
    if (_tone_initialized && _tone_port && _tone_slot != PJSUA_INVALID_ID) {
        DDLogVerbose(@"Tone de-initialized [%@]", [self tone_name]);

        [self tone_stop:PJSUA_INVALID_ID];

        // Tone destroy logic.
        pjsua_conf_remove_port(_tone_slot);
        _tone_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(_tone_port);
        _tone_port = NULL;
        _tone_initialized = NO;
        _tone_cnt = 0;
        _tone = NULL;
    }
}

// ---------------------------------------------
#pragma mark - Tone playback control
// ---------------------------------------------

-(BOOL) tone_start: (pjsua_call_id) call_id {
    if (!_tone_initialized) {
        DDLogError(@"Cannot play, tone is not initialized");
        return NO;
    }

    // For loops.
    if (_tone_on){
        return PJ_FALSE;
    }



    _tone_on = PJ_TRUE;
    if (++_tone_cnt == 1) {
        // If tone is not a loop, it needs to be re-initialized.
        if (![self tone_isLoop]) {
            // For no-loop tones this has to be set again.
            if ([self tone_init_tonePlay] != PJ_SUCCESS) {
                DDLogError(@"Could not init tone");
                return PJ_FALSE;
            }
        }

        if (_tone_slot != PJSUA_INVALID_ID) {
            DDLogVerbose(@"Starting tone %@, no_snd=%d, snd_is_on=%d", [self tone_name], pjsua_var.no_snd, pjsua_var.snd_is_on);
            pjsua_conf_connect(_tone_slot, 0);

            // Schedule tone stop when tone play is over for non-loop tones.
            if (![self tone_isLoop] && [self tone_autoStopNoLoop]) {
                DDLogVerbose(@"Going to schedule tone auto-disconnect, time=%lu", _tone_duration);
                [self tone_schedule_stop:(int32_t) _tone_duration + 500l];
            }

            return PJ_TRUE;
        }
    }

    return PJ_FALSE;
}

-(BOOL) tone_stop: (pjsua_call_id) call_id {
    if (!_tone_initialized) {
        DDLogError(@"Cannot play, tone is not initialized");
        return NO;
    }

    if (_tone_initialized && _tone_on) {
        _tone_on = PJ_FALSE;

        if (_tone_cnt <= 0){
            DDLogError(@"Tone is in inconsistent state! cnt=%d", _tone_cnt);
        }

        if (--_tone_cnt == 0 && _tone_slot != PJSUA_INVALID_ID) {
            DDLogVerbose(@"Stopping tone %@", [self tone_name]);
            pjsua_conf_disconnect(_tone_slot, 0);
            pjmedia_tonegen_rewind(_tone_port);
            return YES;
        }
    }

    return NO;
}

// ---------------------------------------------
#pragma mark - Tone scheduling
// ---------------------------------------------
- (pj_status_t)tone_cancel_timer:(int32_t)time {
    return [self tone_dispatch_cancel_timer:time];
}

- (pj_status_t)tone_schedule_stop:(int32_t)time {
    return [self tone_dispatch_schedule_stop:time];
}

- (pj_status_t)tone_schedule_start:(int32_t)time {
    return [self tone_dispatch_schedule_start:time];
}

- (pj_status_t)tone_timer_schedule_stop:(int32_t)time {
    pj_time_val timeout;

    timeout.sec = time / 1000;
    timeout.msec = time % 1000;

    pj_timer_entry_init(&_tone_stop_timer, 0, (__bridge void*)self, tone_timer_callback);
    if(_tone_timer_heap != NULL){
        DDLogVerbose(@"Going to schedule timer in time: %lu; heap 0x%p heapID", (unsigned long) time, _tone_timer_heap);
        pj_timer_heap_schedule(_tone_timer_heap, &_tone_stop_timer, &timeout);
    } else {
        DDLogWarn(@"Warning! _tone_timer_heap=NULL");
    }

    return PJ_SUCCESS;
}

- (pj_status_t)tone_timer_schedule_start:(int32_t)time  {
    pj_time_val timeout;

    timeout.sec = time / 1000;
    timeout.msec = time % 1000;

    pj_timer_entry_init(&_tone_start_timer, 0, (__bridge void*)self, tone_timer_start_callback);
    if(_tone_timer_heap != NULL){
        DDLogVerbose(@"Going to schedule timer in time: %lu; heap 0x%p heapID", (unsigned long) time, _tone_timer_heap);
        pj_timer_heap_schedule(_tone_timer_heap, &_tone_start_timer, &timeout);
    } else {
        DDLogWarn(@"Warning! _tone_timer_heap=NULL");
    }

    return PJ_SUCCESS;
}

- (pj_status_t)tone_timer_cancel_timer:(int32_t)time {
    if(_tone_timer_heap != NULL){
        pj_timer_heap_cancel_if_active(_tone_timer_heap, &_tone_stop_timer, 0);
    }
    return PJ_SUCCESS;
}

- (pj_status_t)tone_dispatch_cancel_timer:(int32_t)time {
    return PJ_SUCCESS;
}

- (pj_status_t)tone_dispatch_schedule_stop:(int32_t)time {
    WEAKSELF;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (unsigned long long)((time * NSEC_PER_SEC)/1000.0)),
            dispatch_get_main_queue(),
            ^{
                [[PEXPjManager instance] pjExecName:[NSString stringWithFormat:@"tone_stop_%@", [weakSelf tone_name]]
                                              async:YES
                                              block:^{
                    [weakSelf tone_stop:PJSUA_INVALID_ID];
                }];
            });

    return PJ_SUCCESS;
}

- (pj_status_t)tone_dispatch_schedule_start:(int32_t)time {
    WEAKSELF;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (unsigned long long)((time * NSEC_PER_SEC)/1000.0)),
            dispatch_get_main_queue(),
            ^{
                [[PEXPjManager instance] pjExecName:[NSString stringWithFormat:@"tone_start_%@", [weakSelf tone_name]]
                                              async:YES
                                              block:^{
                                                  [weakSelf tone_start:PJSUA_INVALID_ID];
                                              }];
            });

    return PJ_SUCCESS;
}

- (void)timer_callback_fired:(pj_timer_heap_t *)ht e:(pj_timer_entry *)e {
    DDLogVerbose(@"Timer fired");
    [self tone_stop:PJSUA_INVALID_ID];
    PJ_UNUSED_ARG(ht);
}

- (void)timer_start_callback_fired:(pj_timer_heap_t *)ht e:(pj_timer_entry *)e {
    DDLogVerbose(@"Timer fired");
    [self tone_start:PJSUA_INVALID_ID];
    PJ_UNUSED_ARG(ht);
}

// ---------------------------------------------
#pragma mark - Child tone API
// ---------------------------------------------

- (NSString *)tone_name {
    return @"tone";
}

- (unsigned int)tone_cnt {
    DDLogError(@"Calling an abstract method");
    return 0;
}

- (unsigned long)tone_duration {
    return _tone == NULL ? 0 : [PEXPjTone compute_tone_duration:[self tone_cnt] tone:_tone];
}

- (void)tone_set:(pjmedia_tone_desc *)tone {
    DDLogError(@"Calling an abstract method");
}

- (BOOL)tone_autoStopNoLoop {
    return YES;
}

- (BOOL)tone_isLoop {
    return YES;
}

// ---------------------------------------------
#pragma mark - Call state handlers
// ---------------------------------------------

- (void)on_call_state:(pjsua_call_id)call_id
                event:(pjsip_event *)e
            call_info: (pjsua_call_info * ) call_info
        call_session: (PEXPjCall *) call_session
{

}

- (void) on_call_media_state:(pjsua_call_id)call_id call_info: (pjsua_call_info *) pjsua_call_info {

}

- (pj_status_t)on_call_media_transport_state:(pjsua_call_id)call_id info:(const pjsua_med_tp_state_info *)info {
    return PJ_SUCCESS;
}

@end

void tone_timer_callback(pj_timer_heap_t* ht, pj_timer_entry* e) {
    if (e->user_data == NULL){
        PJ_LOG(1, ("PjTone", "Error: timer has null object"));
        return;
    }

    // Static timer now calls tone timer callback instance.
    PEXPjTone * t = (__bridge PEXPjTone *) e->user_data;
    [t timer_callback_fired:ht e:e];
}

void tone_timer_start_callback(pj_timer_heap_t* ht, pj_timer_entry* e) {
    if (e->user_data == NULL){
        PJ_LOG(1, ("PjTone", "Error: timer has null object"));
        return;
    }

    // Static timer now calls tone timer callback instance.
    PEXPjTone * t = (__bridge PEXPjTone *) e->user_data;
    [t timer_start_callback_fired:ht e:e];
}

