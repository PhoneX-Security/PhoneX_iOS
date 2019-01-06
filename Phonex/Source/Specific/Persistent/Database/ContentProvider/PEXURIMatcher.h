//
// Created by Dusan Klinec on 26.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbUri.h"

#define PEXURIMatcher_URI_NOT_FOUND -1

/**
* Naive implementation of the URI matcher.
* Could be better. There is room for improvement, e.g., better
* matching algorithm (e.g., Aho-Corasick) if becomes a bottleneck.
*/
@interface PEXURIMatcher : NSObject

/**
* Adds URI to the matcher engine.
*/
-(void) addURI: (const PEXDbUri * const) uri idx: (int) idx;

/**
* Clears matcher internal memory.
*/
-(void) clear;

/**
* Matches provided URI against internal URI database (URIs added by addUri method).
* Returns URI idx if matched, -1 otherwise.
*/
-(int) match: (const PEXDbUri * const) uri;
@end