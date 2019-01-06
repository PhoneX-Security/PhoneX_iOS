//
// Created by Dusan Klinec on 27.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <pthread.h>
#import <sys/time.h>
#import "PEXDoubleCondition.h"

@interface PEXDoubleCondition () {
    pthread_mutex_t _cMutex;
    pthread_cond_t  _cFull;
    pthread_cond_t  _cEmpty;
}
@end


@implementation PEXDoubleCondition {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        int code = pthread_mutex_init(&_cMutex, NULL);
        if (code != 0){
            DDLogError(@"Cannot initialize mutex, err=%d", code);
            return nil;
        }

        code = pthread_cond_init(&_cEmpty, NULL);
        if (code != 0){
            DDLogError(@"Cannot initialize cond1, err=%d", code);
            pthread_mutex_destroy(&_cMutex);
            return nil;
        }

        code = pthread_cond_init(&_cFull, NULL);
        if (code != 0){
            DDLogError(@"Cannot initialize cond2, err=%d", code);
            pthread_mutex_destroy(&_cMutex);
            pthread_cond_destroy(&_cEmpty);
            return nil;
        }
    }

    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&_cMutex);
    pthread_cond_destroy(&_cEmpty);
    pthread_cond_destroy(&_cFull);
}

- (void)lock {
    int code = pthread_mutex_lock(&_cMutex);
    if (code != 0){
        DDLogError(@"Locking code error: %d", code);
        [NSException raise:PEXRuntimeException format:@"Locking code error: %d", code];
    }
}

- (BOOL)tryLock {
    return pthread_mutex_trylock(&_cMutex) == 0;
}

- (void)unlock {
    int code = pthread_mutex_unlock(&_cMutex);
    if (code != 0){
        DDLogError(@"Unlocking code error: %d", code);
        [NSException raise:PEXRuntimeException format:@"Unlocking code error: %d", code];
    }
}

- (void)wait:(int)idx {
    if (idx != 0 && idx != 1){
        [NSException raise:PEXRuntimeException format:@"Unknown condition specified: %d", idx];
    }

    pthread_cond_t * cond = idx == 0 ? &_cEmpty : &_cFull;
    int code = pthread_cond_wait(cond, &_cMutex);
    if (code != 0){
        DDLogError(@"Cannot wait, error=%d", code);
        [NSException raise:PEXRuntimeException format:@"Cannot wait, error=%d", code];
    }
}

- (BOOL)wait:(int)idx untilDate:(NSDate *)date {
    if (idx != 0 && idx != 1){
        [NSException raise:PEXRuntimeException format:@"Unknown condition specified: %d", idx];
    }

    pthread_cond_t * cond = idx == 0 ? &_cEmpty : &_cFull;

    // If already expired, return NO.
    NSDate * now = [NSDate date];
    NSTimeInterval interval = [date timeIntervalSinceDate:now];
    if (interval <= 0.0){
        DDLogWarn(@"Wait time is in past!");
    }

    int code = 0;
    long millis = (long)(interval * 1000.0);
    struct timeval tv;
    struct timespec ts;

    gettimeofday(&tv, NULL);
    ts.tv_sec = time(NULL) + (long) interval;
    ts.tv_nsec = tv.tv_usec * 1000 + 1000 * 1000 * (millis % 1000);
    ts.tv_sec += ts.tv_nsec / (1000 * 1000 * 1000);
    ts.tv_nsec %= (1000 * 1000 * 1000);

    code = pthread_cond_timedwait(cond, &_cMutex, &ts);
    if (code == 0){
        return YES;
    } else if (code == ETIMEDOUT){
        return NO;
    } else {
        DDLogError(@"Error during pthread_cond_timedwait, code=%d", code);
    }

    return NO;
}

- (void)signal:(int)idx {
    if (idx != 0 && idx != 1){
        [NSException raise:PEXRuntimeException format:@"Unknown condition specified: %d", idx];
    }

    pthread_cond_t * cond = idx == 0 ? &_cEmpty : &_cFull;
    int code = pthread_cond_signal(cond);
    if (code != 0) {
        DDLogError(@"Signaling code error: %d", code);
        [NSException raise:PEXRuntimeException format:@"Signaling code error: %d", code];
    }
}

- (void)broadcast:(int)idx {
    if (idx != 0 && idx != 1){
        [NSException raise:PEXRuntimeException format:@"Unknown condition specified: %d", idx];
    }

    pthread_cond_t * cond = idx == 0 ? &_cEmpty : &_cFull;
    int code = pthread_cond_broadcast(cond);
    if (code != 0) {
        DDLogError(@"Broadcasting code error: %d", code);
        [NSException raise:PEXRuntimeException format:@"Broadcasting code error: %d", code];
    }
}

@end