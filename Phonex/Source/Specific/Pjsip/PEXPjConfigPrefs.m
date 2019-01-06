//
// Created by Dusan Klinec on 09.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjConfigPrefs.h"
#import "PEXMessageDigest.h"
#import "PEXPjConfig.h"
#import "PEXUtils.h"

NSString * PEX_PJPREFS_HASH = @"pex_pjprefs_hash";
NSString * PEX_PJPREFS_ACC_KA_INTERVAL = @"pex_pjprefs_acc_ka_interval";
NSString * PEX_PJPREFS_ACC_REG_TIMEOUT = @"pex_pjprefs_acc_reg_timeout";
NSString * PEX_PJPREFS_REG_DELAY_BEFORE_REFRESH = @"pex_pjprefs_acc_reg_delay_before_refresh";
NSString * PEX_PJPREFS_ACC_REGISTER_TSX_TIMEOUT = @"pex_pjprefs_acc_register_tsx_timeout";

NSString * PEX_PJPREFS_TLS_KA = @"pex_pjprefs_tls_ka";
NSString * PEX_PJPREFS_TLS_NODELAY = @"pex_pjprefs_tls_nodelay";
NSString * PEX_PJPREFS_TLS_KA_IDLE = @"pex_pjprefs_tls_ka_idle";
NSString * PEX_PJPREFS_TLS_KA_INTERVAL = @"pex_pjprefs_tls_ka_interval";

@implementation PEXPjConfigPrefs {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _acc_ka_interval = PEX_PJ_DEF_ACC_KA_INTERVAL;
        _acc_reg_delay_before_refresh = PEX_PJ_DEF_ACC_REG_DELAY_BEFORE_REFRESH;
        _acc_reg_timeout = PEX_PJ_DEF_ACC_REG_TIMEOUT;
        _acc_register_tsx_timeout = PEX_PJ_DEF_ACC_REGISTER_TSX_TIMEOUT;

        _tls_ka = PEX_PJ_DEF_TLS_KA < 0 ? nil : @(PEX_PJ_DEF_TLS_KA);
        _tls_noDelay = PEX_PJ_DEF_TLS_NODELAY < 0 ? nil : @(PEX_PJ_DEF_TLS_NODELAY);
        _tls_ka_idle = PEX_PJ_DEF_TLS_KA_IDLE < 0 ? nil : @(PEX_PJ_DEF_TLS_KA_IDLE);
        _tls_ka_interval = PEX_PJ_DEF_TLS_KA_INTERVAL < 0 ? nil : @(PEX_PJ_DEF_TLS_KA_INTERVAL);
    }

    return self;
}

- (instancetype)initFromSettings {
    self = [self init];
    if (self) {
        [self loadFromSettings];
    }

    return self;
}

+ (instancetype)prefsFromSettings {
    return [[self alloc] initFromSettings];
}

- (void)loadFromSettings {
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    _acc_ka_interval =
            [[prefs getNumberPrefForKey:PEX_PJPREFS_ACC_KA_INTERVAL defaultValue:@(PEX_PJ_DEF_ACC_KA_INTERVAL)] unsignedIntValue];

    _acc_reg_delay_before_refresh =
            [[prefs getNumberPrefForKey:PEX_PJPREFS_REG_DELAY_BEFORE_REFRESH defaultValue:@(PEX_PJ_DEF_ACC_REG_DELAY_BEFORE_REFRESH)] unsignedIntValue];

    _acc_reg_timeout =
            [[prefs getNumberPrefForKey:PEX_PJPREFS_ACC_REG_TIMEOUT defaultValue:@(PEX_PJ_DEF_ACC_REG_TIMEOUT)] unsignedIntValue];

    _acc_register_tsx_timeout =
            [[prefs getNumberPrefForKey:PEX_PJPREFS_ACC_REGISTER_TSX_TIMEOUT defaultValue:@(PEX_PJ_DEF_ACC_REGISTER_TSX_TIMEOUT)] unsignedLongValue];

    _tls_ka =
            [prefs getNumberPrefForKey:PEX_PJPREFS_TLS_KA defaultValue:PEX_PJ_DEF_TLS_KA < 0 ? nil : @(PEX_PJ_DEF_TLS_KA)];

    _tls_noDelay =
            [prefs getNumberPrefForKey:PEX_PJPREFS_TLS_NODELAY defaultValue:PEX_PJ_DEF_TLS_NODELAY < 0 ? nil : @(PEX_PJ_DEF_TLS_NODELAY)];

    _tls_ka_idle =
            [prefs getNumberPrefForKey:PEX_PJPREFS_TLS_KA_IDLE defaultValue:PEX_PJ_DEF_TLS_KA_IDLE < 0 ? nil : @(PEX_PJ_DEF_TLS_KA_IDLE)];

    _tls_ka_interval =
            [prefs getNumberPrefForKey:PEX_PJPREFS_TLS_KA_INTERVAL defaultValue:PEX_PJ_DEF_TLS_KA_INTERVAL < 0 ? nil : @(PEX_PJ_DEF_TLS_KA_INTERVAL)];
}

- (void)saveToSettings {
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];

    // Hash determines current configuration version.
    [prefs setStringPrefForKey:PEX_PJPREFS_HASH value:[self getSettingsHash]];

    // Set individual configuration elements.
    [prefs setNumberPrefForKey:PEX_PJPREFS_ACC_KA_INTERVAL value:@(_acc_ka_interval)];
    [prefs setNumberPrefForKey:PEX_PJPREFS_REG_DELAY_BEFORE_REFRESH value:@(_acc_reg_delay_before_refresh)];
    [prefs setNumberPrefForKey:PEX_PJPREFS_ACC_REG_TIMEOUT value:@(_acc_reg_timeout)];
    [prefs setNumberPrefForKey:PEX_PJPREFS_ACC_REGISTER_TSX_TIMEOUT value:@(_acc_register_tsx_timeout)];

    [prefs setNumberPrefForKey:PEX_PJPREFS_TLS_KA value:_tls_ka];
    [prefs setNumberPrefForKey:PEX_PJPREFS_TLS_NODELAY value:_tls_noDelay];
    [prefs setNumberPrefForKey:PEX_PJPREFS_TLS_KA_INTERVAL value:_tls_ka_interval];
    [prefs setNumberPrefForKey:PEX_PJPREFS_TLS_KA_IDLE value:_tls_ka_idle];
}

- (void)loadFromServerSettings:(NSDictionary *)settings privData:(PEXUserPrivate *)privData {
    if (settings == nil){
        return;
    }

    // Load server side settings.
    NSNumber * acc_ka_interval = [PEXUtils getAsNumber:settings[@"acc_ka_interval"]];
    NSNumber * acc_reg_delay_before_refresh = [PEXUtils getAsNumber:settings[@"acc_reg_delay_before_refresh"]];
    NSNumber * acc_reg_timeout = [PEXUtils getAsNumber:settings[@"acc_reg_timeout"]];
    NSNumber * acc_register_tsx_timeout = [PEXUtils getAsNumber:settings[@"acc_register_tsx_timeout"]];

    NSNumber * tls_ka = settings[@"tls_ka"] == nil ?
            @(PEX_PJ_DEF_TLS_KA) : [PEXUtils getAsNumber:settings[@"tls_ka"]];

    NSNumber * tls_nodelay = settings[@"tls_nodelay"] == nil ?
            @(PEX_PJ_DEF_TLS_NODELAY) : [PEXUtils getAsNumber:settings[@"tls_nodelay"]];

    NSNumber * tls_ka_idle = settings[@"tls_ka_idle"] == nil ?
            @(PEX_PJ_DEF_TLS_KA_IDLE) : [PEXUtils getAsNumber:settings[@"tls_ka_idle"]];

    NSNumber * tls_ka_interval = settings[@"tls_ka_interval"] == nil ?
            @(PEX_PJ_DEF_TLS_KA_INTERVAL) : [PEXUtils getAsNumber:settings[@"tls_ka_interval"]];

    _acc_ka_interval = acc_ka_interval != nil ?
            [acc_ka_interval unsignedIntValue] : PEX_PJ_DEF_ACC_KA_INTERVAL;

    _acc_reg_delay_before_refresh = acc_reg_delay_before_refresh != nil ?
                [acc_reg_delay_before_refresh unsignedIntValue] : PEX_PJ_DEF_ACC_REG_DELAY_BEFORE_REFRESH;

    _acc_reg_timeout = acc_reg_timeout != nil ?
                [acc_reg_timeout unsignedIntValue] : PEX_PJ_DEF_ACC_REG_TIMEOUT;

    _acc_register_tsx_timeout = acc_register_tsx_timeout != nil ?
                [acc_register_tsx_timeout unsignedLongValue] : PEX_PJ_DEF_ACC_REGISTER_TSX_TIMEOUT;

    _tls_ka = tls_ka;
    _tls_noDelay = tls_nodelay;
    _tls_ka_idle = tls_ka_idle;
    _tls_ka_interval = tls_ka_interval;

    // Negative means nil -> do not change parameters.
    // If setting is absent on the server -> use default values.
    if (_tls_ka != nil && [_tls_ka longValue] < 0){
        _tls_ka = nil;
    }
    if (_tls_noDelay != nil && [_tls_noDelay longValue] < 0){
        _tls_noDelay = nil;
    }
    if (_tls_ka_idle != nil && [_tls_ka_idle longValue] < 0){
        _tls_ka_idle = nil;
    }
    if (_tls_ka_interval != nil && [_tls_ka_interval longValue] < 0){
        _tls_ka_interval = nil;
    }
}

+ (BOOL)updateFromServerSettings:(NSDictionary *)settings privData:(PEXUserPrivate *)privData {
    PEXPjConfigPrefs * localPrefs = [PEXPjConfigPrefs prefsFromSettings];
    NSString * localHash = [localPrefs getSettingsHash];

    // Server prefs are initialized from settings and reloaded from server settings as the
    // server configuration does not have to include all setting directives.
    PEXPjConfigPrefs * serverPrefs = [PEXPjConfigPrefs prefsFromSettings];
    [serverPrefs loadFromServerSettings:settings privData:privData];
    NSString * serverHash = [serverPrefs getSettingsHash];

    if ([localHash isEqualToString:serverHash]){
        return NO;
    }

    [serverPrefs saveToSettings];
    DDLogVerbose(@"Settings updated from the server: %@", serverPrefs);
    return YES;
}

- (NSString *)getSettingsHash {
    NSString * desc = [self description];
    return [PEXMessageDigest bytes2base64: [PEXMessageDigest md5Message:desc]];
}

// ---------------------------------------------
#pragma mark - Generated methods
// ---------------------------------------------

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.acc_ka_interval = [coder decodeInt64ForKey:@"self.acc_ka_interval"];
        self.acc_reg_delay_before_refresh = [coder decodeInt64ForKey:@"self.acc_reg_delay_before_refresh"];
        self.acc_reg_timeout = [coder decodeInt64ForKey:@"self.acc_reg_timeout"];
        self.acc_register_tsx_timeout = [coder decodeInt64ForKey:@"self.acc_register_tsx_timeout"];
        self.tls_ka = [coder decodeObjectForKey:@"self.tls_ka"];
        self.tls_noDelay = [coder decodeObjectForKey:@"self.tls_noDelay"];
        self.tls_ka_idle = [coder decodeObjectForKey:@"self.tls_ka_idle"];
        self.tls_ka_interval = [coder decodeObjectForKey:@"self.tls_ka_interval"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.acc_ka_interval forKey:@"self.acc_ka_interval"];
    [coder encodeInt64:self.acc_reg_delay_before_refresh forKey:@"self.acc_reg_delay_before_refresh"];
    [coder encodeInt64:self.acc_reg_timeout forKey:@"self.acc_reg_timeout"];
    [coder encodeInt64:self.acc_register_tsx_timeout forKey:@"self.acc_register_tsx_timeout"];
    [coder encodeObject:self.tls_ka forKey:@"self.tls_ka"];
    [coder encodeObject:self.tls_noDelay forKey:@"self.tls_noDelay"];
    [coder encodeObject:self.tls_ka_idle forKey:@"self.tls_ka_idle"];
    [coder encodeObject:self.tls_ka_interval forKey:@"self.tls_ka_interval"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPjConfigPrefs *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.acc_ka_interval = self.acc_ka_interval;
        copy.acc_reg_delay_before_refresh = self.acc_reg_delay_before_refresh;
        copy.acc_reg_timeout = self.acc_reg_timeout;
        copy.acc_register_tsx_timeout = self.acc_register_tsx_timeout;
        copy.tls_ka = self.tls_ka;
        copy.tls_noDelay = self.tls_noDelay;
        copy.tls_ka_idle = self.tls_ka_idle;
        copy.tls_ka_interval = self.tls_ka_interval;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToPrefs:other];
}

- (BOOL)isEqualToPrefs:(PEXPjConfigPrefs *)prefs {
    if (self == prefs)
        return YES;
    if (prefs == nil)
        return NO;
    if (self.acc_ka_interval != prefs.acc_ka_interval)
        return NO;
    if (self.acc_reg_delay_before_refresh != prefs.acc_reg_delay_before_refresh)
        return NO;
    if (self.acc_reg_timeout != prefs.acc_reg_timeout)
        return NO;
    if (self.acc_register_tsx_timeout != prefs.acc_register_tsx_timeout)
        return NO;
    if (self.tls_ka != prefs.tls_ka && ![self.tls_ka isEqualToNumber:prefs.tls_ka])
        return NO;
    if (self.tls_noDelay != prefs.tls_noDelay && ![self.tls_noDelay isEqualToNumber:prefs.tls_noDelay])
        return NO;
    if (self.tls_ka_idle != prefs.tls_ka_idle && ![self.tls_ka_idle isEqualToNumber:prefs.tls_ka_idle])
        return NO;
    if (self.tls_ka_interval != prefs.tls_ka_interval && ![self.tls_ka_interval isEqualToNumber:prefs.tls_ka_interval])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = self.acc_ka_interval;
    hash = hash * 31u + self.acc_reg_delay_before_refresh;
    hash = hash * 31u + self.acc_reg_timeout;
    hash = hash * 31u + self.acc_register_tsx_timeout;
    hash = hash * 31u + [self.tls_ka hash];
    hash = hash * 31u + [self.tls_noDelay hash];
    hash = hash * 31u + [self.tls_ka_idle hash];
    hash = hash * 31u + [self.tls_ka_interval hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.acc_ka_interval=%u", self.acc_ka_interval];
    [description appendFormat:@", self.acc_reg_delay_before_refresh=%u", self.acc_reg_delay_before_refresh];
    [description appendFormat:@", self.acc_reg_timeout=%u", self.acc_reg_timeout];
    [description appendFormat:@", self.acc_register_tsx_timeout=%u", self.acc_register_tsx_timeout];
    [description appendFormat:@", self.tls_ka=%@", self.tls_ka];
    [description appendFormat:@", self.tls_noDelay=%@", self.tls_noDelay];
    [description appendFormat:@", self.tls_ka_idle=%@", self.tls_ka_idle];
    [description appendFormat:@", self.tls_ka_interval=%@", self.tls_ka_interval];
    [description appendString:@">"];
    return description;
}

@end