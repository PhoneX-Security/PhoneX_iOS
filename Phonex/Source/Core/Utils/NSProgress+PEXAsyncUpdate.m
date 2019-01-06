//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "NSProgress+PEXAsyncUpdate.h"


@implementation NSProgress (PEXAsyncUpdate)

- (void)executeOnMain:(dispatch_block_t)block {
    [self executeOnMain:YES block:block];
}

- (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block {
    if (!block) {
        return;
    } else if ([NSThread isMainThread]) {
        block();
    } else if (async) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)finishProgress {
    if (self!=nil) {
        self.completedUnitCount = self.totalUnitCount;
    }
}

- (void)finishProgressOnMain: (BOOL) async {
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
            [sSelf finishProgress];
        }
    }];
}

- (void)setProgressOnMain:(int)maxCount completedCount:(int)completedCount {
    [self setProgressOnMain:maxCount completedCount:completedCount async:YES];
}

- (void)setProgressOnMain:(int)maxCount completedCount:(int)completedCount async: (BOOL) async {
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
//            sSelf.totalUnitCount = maxCount;
//            sSelf.completedUnitCount = completedCount;
        }
    }];
}

- (void)updateProgressOnMain: (int)completedCount async: (BOOL) async {
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
            sSelf.completedUnitCount = completedCount;
        }
    }];
}

- (void)incProgressOnMain: (int)delta {
    [self incProgressOnMain:delta async:YES];
}

- (void)incProgressOnMain: (int)delta async: (BOOL) async{
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
            sSelf.completedUnitCount += delta;
        }
    }];
}

-(void) becomeCurrentWithPendingUnitCountOnMain: (int64_t) unitCount async: (BOOL) async {
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
            [sSelf becomeCurrentWithPendingUnitCount:unitCount];
        }
    }];
}

-(void) resignCurrentOnMainAsync: (BOOL) async {
    __weak __typeof(self) weakSelf = self;
    [self executeOnMain: async block: ^{
        NSProgress * sSelf = weakSelf;
        if (sSelf!=nil) {
            [sSelf resignCurrent];
        }
    }];
}

+ (instancetype)doInitOnMainSync:(NSProgress *)cur unitCount:(int64_t)unitCount {
    if ([NSThread isMainThread]) {
        NSProgress * toReturn = [cur initWithParent:[NSProgress currentProgress] userInfo:nil];
        if (toReturn!=nil){
            toReturn.totalUnitCount = unitCount;
        }

        return toReturn;
    } else {
        __block NSProgress * toReturn = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            toReturn = [cur initWithParent:[NSProgress currentProgress] userInfo:nil];
            if (toReturn!=nil){
                toReturn.totalUnitCount = unitCount;
            }
        });

        return toReturn;
    }
}

+ (instancetype)doInitWithParentOnMainSync:(NSProgress *)cur userInfo:(NSDictionary *)userInfo {
    if ([NSThread isMainThread]) {
        return [cur initWithParent:[NSProgress currentProgress] userInfo:userInfo];
    } else {
        __block NSProgress * toReturn = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            toReturn = [cur initWithParent:[NSProgress currentProgress] userInfo:userInfo];
        });

        return toReturn;
    }
}

+ (instancetype)doInitWithParentOnMainSync:(NSProgress *)cur parent:(NSProgress *)parent userInfo:(NSDictionary *)userInfo {
    if ([NSThread isMainThread]) {
        return [cur initWithParent:parent userInfo:userInfo];
    } else {
        __block NSProgress * toReturn = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            toReturn = [cur initWithParent:parent userInfo:userInfo];
        });

        return toReturn;
    }
}

+ (void)doInitOnMainAsync:(NSProgress *)cur destination:(NSProgress **)destination unitCount:(int64_t)unitCount {
    if ([NSThread isMainThread]) {
        *destination = [cur initWithParent:[NSProgress currentProgress] userInfo:nil];
        if ((*destination)!=nil){
            (*destination).totalUnitCount = unitCount;
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            *destination = [cur initWithParent:[NSProgress currentProgress] userInfo:nil];
            if ((*destination)!=nil){
                (*destination).totalUnitCount = unitCount;
            }
        });
    }
}

+ (void)doInitWithParentOnMainAsync:(NSProgress *)cur destination:(NSProgress **)destination userInfo:(NSDictionary *)userInfo {
    if ([NSThread isMainThread]) {
        *destination = [cur initWithParent:[NSProgress currentProgress] userInfo:userInfo];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            *destination =  [cur initWithParent:[NSProgress currentProgress] userInfo:userInfo];
        });
    }
}

@end