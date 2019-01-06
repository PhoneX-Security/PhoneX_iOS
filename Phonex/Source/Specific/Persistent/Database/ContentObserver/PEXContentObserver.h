//
// Created by Matej Oravec on 28/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXUri;

@protocol PEXContentObserver <NSObject>

//Returns true if this observer is interested receiving self-change notifications.
- (bool) deliverSelfNotifications;

// Dispatches a change notification to the observer.
- (void) dispatchChange: (const bool) selfChange
                    uri: (const PEXUri * const) uri;

/*
 In ANDROID the observer is an abstract class
 but in case of protocol we dont need it

// This method is called when a content change occurs.
- (void) onChange: (const bool) selfChange
              uri: (const PEXUri * const) uri;

// This method is called when a content change occurs.
- (void) onChange: (const bool) selfChange;
 */

// CUSTOM
@optional
/*
- (void) onInsert: (const bool) selfChange
              uri: (const PEXUri * const) uri;
- (void) onDelete: (const bool) selfChange
              uri: (const PEXUri * const) uri;
- (void) onUpdate: (const bool) selfChange
              uri: (const PEXUri * const) uri;
 */

- (void) dispatchChangeInsert: (const bool) selfChange
                    uri: (const PEXUri * const) uri;
- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri;
- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri;

@end