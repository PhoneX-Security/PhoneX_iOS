//
//  PEXPjZrtpTimer.h
//  Phonex
//
//  Created by Dusan Klinec on 09.12.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef __Phonex__PEXPjZrtpTimer__
#define __Phonex__PEXPjZrtpTimer__

#include <stdio.h>
#import <pj/config_site.h>
#import <pjmedia/types.h>
#import <pj/timer.h>

pj_bool_t zrtp_timer_is_initialized();
pj_status_t zrtp_timer_init(pjmedia_endpt *endpt);
void zrtp_timer_stop();
int zrtp_timer_add_entry(pj_timer_entry *entry, pj_time_val *delay);
int zrtp_timer_cancel_entry(pj_timer_entry *entry);
#endif /* defined(__Phonex__PEXPjZrtpTimer__) */
