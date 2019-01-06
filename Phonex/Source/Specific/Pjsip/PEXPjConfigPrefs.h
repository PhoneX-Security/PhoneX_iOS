//
// Created by Dusan Klinec on 09.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pj/types.h"


@interface PEXPjConfigPrefs : NSObject <NSCoding, NSCopying>
@property(nonatomic) unsigned acc_ka_interval;
@property(nonatomic) unsigned acc_reg_delay_before_refresh;
@property(nonatomic) unsigned acc_reg_timeout;
@property(nonatomic) pj_uint32_t acc_register_tsx_timeout;

// TLS Keep-alive socket options
@property(nonatomic) NSNumber * tls_ka;
@property(nonatomic) NSNumber * tls_noDelay;
@property(nonatomic) NSNumber * tls_ka_idle;
@property(nonatomic) NSNumber * tls_ka_interval;

- (instancetype)initFromSettings;
+ (instancetype)prefsFromSettings;

/**
 * Updates settings from the server, returning YES if something has changed from the current values.
 */
+ (BOOL) updateFromServerSettings: (NSDictionary *)settings privData:(PEXUserPrivate *)privData;

/**
 * Loads current settings from preferences.
 */
- (void) loadFromSettings;

/**
 * Saves current values to the settings.
 */
- (void) saveToSettings;

/**
 * Loads current settings from server setting format.
 */
- (void) loadFromServerSettings: (NSDictionary *)settings privData:(PEXUserPrivate *)privData;

/**
 * Returns settings hash for the current setting.
 * When settings got changes, settings hash changes also.
 */
- (NSString *) getSettingsHash;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)copyWithZone:(NSZone *)zone;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToPrefs:(PEXPjConfigPrefs *)prefs;

- (NSUInteger)hash;

- (NSString *)description;
@end