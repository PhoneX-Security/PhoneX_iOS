//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXStopwatch.h"

@interface PEXStopwatch() {}
@property(nonatomic) NSTimeInterval totalTime;
@property(nonatomic) NSDate * lastStart;
@property(nonatomic) NSString * name;
@end

@implementation PEXStopwatch {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.totalTime = 0.0;
        self.lastStart = nil;
        self.name = nil;
    }

    return self;
}

- (instancetype)initAndStart {
    self = [self init];
    if (self) {
        [self start];
    }

    return self;
}

- (instancetype)initAndStartIf: (BOOL) start {
    self = [self init];
    if (self && start) {
        [self start];
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [self init];
    if (self) {
        self.name = name;
    }

    return self;
}

- (instancetype)initWithNameAndStart:(NSString *)name {
    self = [self init];
    if (self) {
        self.name = name;
        [self start];
    }

    return self;
}

+ (instancetype)buildAndStart {
#ifdef PEX_STOPWATCH_ENABLED
    return [[PEXStopwatch alloc] initAndStart];
#else
    return nil;
#endif
}

+ (instancetype)buildWithName:(NSString *)name {
#ifdef PEX_STOPWATCH_ENABLED
    return [[PEXStopwatch alloc] initWithName:name];
#else
    return nil;
#endif
}

+ (instancetype)buildWithNameAndStart:(NSString *)name {
#ifdef PEX_STOPWATCH_ENABLED
    return [[PEXStopwatch alloc] initWithNameAndStart:name];
#else
    return nil;
#endif
}

-(void) start {
#ifdef PEX_STOPWATCH_ENABLED
    @synchronized (self) {
        self.totalTime = 0.0;
        self.lastStart = [NSDate date];
    }
#endif
}

-(void) pause {
#ifdef PEX_STOPWATCH_ENABLED
    if (self.lastStart != nil) {
        @synchronized (self) {
            if (self.lastStart != nil) {
                _totalTime += [[NSDate date] timeIntervalSinceDate:self.lastStart];
                self.lastStart = nil;
            }
        }
    }
#endif
}

-(void) resume {
#ifdef PEX_STOPWATCH_ENABLED
    if (self.lastStart == nil) {
        @synchronized (self) {
            if (self.lastStart == nil) {
                self.lastStart = [NSDate date];
            }
        }
    }
#endif
}

-(NSTimeInterval) current {
    NSTimeInterval ret = 0;
#ifdef PEX_STOPWATCH_ENABLED
    if (self.lastStart != nil) {
        @synchronized (self) {
            if (self.lastStart != nil) {
                ret += [[NSDate date] timeIntervalSinceDate:self.lastStart];
            }
        }
    }
#endif
    return ret;
}

-(NSTimeInterval) stop {
#ifdef PEX_STOPWATCH_ENABLED
    @synchronized (self) {
        [self pause];
        return self.totalTime;
    }
#else
    return 0;
#endif
}

-(NSTimeInterval) stopAndLog {
#ifdef PEX_STOPWATCH_ENABLED
    [self pause];
    DDLogVerbose(@"TimeMeasurement [%@], time=%f",
            [self.name stringByPaddingToLength:PEX_STOPWATCH_NAME_PADDING withString:@" " startingAtIndex:0], self.totalTime);
    return self.totalTime;
#else
    return 0;
#endif
}

@end