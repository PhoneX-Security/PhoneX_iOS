//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSProgress (PEXAsyncUpdate)
/**
* Ensures the given block will be executed on main thread.
*/
- (void) executeOnMain: (dispatch_block_t) block;
- (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block;

/**
* Sets completedUnitCount to totalUnitCount.
*/
- (void)finishProgress;

/**
* Finishes the progress on main thread. Sets completedUnitCount to totalUnitCount.
*/
- (void) finishProgressOnMain: (BOOL) async;

/**
* Sets progress object on the main thread.
*/
- (void) setProgressOnMain: (int) maxCount completedCount: (int) completedCount;
- (void) setProgressOnMain: (int) maxCount completedCount: (int) completedCount async: (BOOL) async;

- (void) updateProgressOnMain: (int) completedCount async: (BOOL) async;

/**
* Increments completedUnitCount of progress object by given delta.
*/
- (void) incProgressOnMain: (int) delta;
- (void) incProgressOnMain: (int) delta async: (BOOL) async;

/**
* Prepares for setting-up childhood relationship on the main thread.
* Sometimes needed to do on main thread since the child NSProgress has to be
* initialized in the same thread.
*/
-(void) becomeCurrentWithPendingUnitCountOnMain: (int64_t) unitCount async: (BOOL) async;

/**
* Closes current childhood relationship on the main thread.
*/
-(void) resignCurrentOnMainAsync: (BOOL) async;

/**
* Initializes given progress on the main thread.
* Synchronous wait.
*/
+(instancetype)doInitOnMainSync:(NSProgress *)cur unitCount: (int64_t) unitCount;

/**
* Initializes given progress with master parent and given user info.
* Synchronous wait.
*/
+(instancetype)doInitWithParentOnMainSync:(NSProgress *)cur userInfo: (NSDictionary *) userInfo;

/**
* Initializes given progress with master parent and given user info.
* Synchronous wait.
*/
+(instancetype)doInitWithParentOnMainSync:(NSProgress *)cur parent: (NSProgress *) parent userInfo: (NSDictionary *) userInfo;

/**
* Initializes given progress on the main thread.
* Asynchronous process.
*/
+(void) doInitOnMainAsync: (NSProgress *) cur destination: (NSProgress **) destination unitCount: (int64_t) unitCount;

/**
* Initializes given progress with master parent and given user info.
* Asynchronous process.
*/
+(void) doInitWithParentOnMainAsync: (NSProgress *) cur destination: (NSProgress **) destination userInfo: (NSDictionary *) userInfo;
@end