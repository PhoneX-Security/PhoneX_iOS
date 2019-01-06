//
// Created by Matej Oravec on 27/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PEXPreferencesManager

- (NSString *) getStringPrefForKey: (NSString *) key defaultValue: (NSString *) defaultValue;
- (NSNumber *) getNumberPrefForKey: (NSString *) key defaultValue: (NSNumber *) defaultValue;
- (BOOL) getBoolPrefForKey: (NSString *) key defaultValue: (BOOL) defaultValue;
- (NSInteger) getIntPrefForKey: (NSString *) key defaultValue: (NSInteger) defaultValue;
- (double) getDoublePrefForKey: (NSString *) key defaultValue: (double) defaultValue;

- (void) setStringPrefForKey: (NSString *) key value: (NSString *) value;
- (void) setNumberPrefForKey: (NSString *) key value: (NSNumber *) value;
- (void) setBoolPrefForKey: (NSString *) key value: (BOOL) value;
- (void) setIntPrefForKey: (NSString *) key value: (NSInteger) value;
- (void) setDoublePrefForKey: (NSString *) key value: (double) value;

@end