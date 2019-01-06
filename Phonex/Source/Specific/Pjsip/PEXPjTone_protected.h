//
// Created by Dusan Klinec on 10.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "pexpj.h"
#import "PEXPjTone.h"

@interface PEXPjTone() {
@protected
    pj_pool_t      *_pool;
    int             _tone_slot;
    int             _tone_cnt;
    pjmedia_port   *_tone_port;
    BOOL volatile   _tone_on;
    BOOL            _tone_initialized;

    pjmedia_tone_desc *  _tone;
    unsigned long        _tone_duration;
    pj_pool_t           * _tone_timer_pool;
    pj_timer_heap_t     * _tone_timer_heap;
    pj_timer_entry        _tone_stop_timer;
    pj_timer_entry        _tone_start_timer;
}

@end