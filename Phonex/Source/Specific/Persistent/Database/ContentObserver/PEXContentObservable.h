//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXContentObserver;
@class PEXUri;

@protocol PEXContentObservable <NSObject>

// Adds an observer to the list.
- (void) registerObserver:(id<PEXContentObserver>) observer;

// Remove all registered observers.
- (void) unregisterAll;

// Removes a previously registered observer.
- (void) unregisterObserver: (id<PEXContentObserver>)  observer;

- (void) dispatchChange:(const bool) selfChange withUri: (PEXUri * const) uri;

// CUSTOM
@optional
- (void) registerObserverInsert:(id<PEXContentObserver>) observer;
- (void) registerObserverDelete:(id<PEXContentObserver>) observer;
- (void) registerObserverUpdate:(id<PEXContentObserver>) observer;
- (void) unregisterObserverInsert:(id<PEXContentObserver>) observer;
- (void) unregisterObserverDelete:(id<PEXContentObserver>) observer;
- (void) unregisterObserverUpdate:(id<PEXContentObserver>) observer;

@end