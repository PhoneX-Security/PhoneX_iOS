//
// Created by Dusan Klinec on 07.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUserKeyRefreshRecord.h"


#define PEX_DHKEY_USER_REFRESH_KEY_PRIORITY 200.0
#define PEX_DHKEY_USER_REFRESH_KEY_REQUESTS 200.0
#define PEX_DHKEY_USER_REFRESH_KEY_RECENT_FILE_TRANSFERS 100.0
#define PEX_DHKEY_USER_REFRESH_KEY_RECENT_MESSAGES 50.0

@implementation PEXUserKeyRefreshRecord {
    BOOL _isDirty;
    double _cost;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isDirty = YES;
        _certIsOK = YES;
    }

    return self;
}

- (BOOL)shouldBeProcessed {
    return _availableKeys < _maximalKeys && _certIsOK;
}

- (void) recomputeCost {
    _cost = 0;
    if (!_certIsOK){
        _cost += -5000;
    }

    // Compute priority based on number of available keys.
    // If there are no keys or a very small amount, boost its priority.
    _cost += ((double)(_maximalKeys-_availableKeys) / (double)_maximalKeys) * PEX_DHKEY_USER_REFRESH_KEY_PRIORITY;

    // Increase priority w.r.t. recent requests.
    // If somebody is willing to send us a file, during e.g. file picking he may send us a notification so we can
    // generate new keys while he performs the selection.
    _cost += MIN(_numberOfKeyRequests * PEX_DHKEY_USER_REFRESH_KEY_REQUESTS, 3 * PEX_DHKEY_USER_REFRESH_KEY_REQUESTS);

    // Increase priority w.r.t. ratio of recent file transfers.
    // Prioritize more contacts with more file transfer activity since this may repeat.
    _cost += _ratioOfFilesInLastWindow * PEX_DHKEY_USER_REFRESH_KEY_RECENT_FILE_TRANSFERS;

    // Increase priority w.r.t. ratio of recent messages.
    // Prioritize more contacts with messages activity since users with no messages are less urgent, having
    // smaller probability of a need for a key.
    _cost += _ratioOfMessagesInLastWindow * PEX_DHKEY_USER_REFRESH_KEY_RECENT_MESSAGES;

    // Priority is designated for max-heap, cost is min-heap so invert it to negative numbers.
    _cost *= -1;
    _isDirty = NO;
}

- (void)updateFromRecord:(PEXUserKeyRefreshRecord *)rec {
    _maximalKeys = rec.maximalKeys;
    _availableKeys = rec.availableKeys;
    _numberOfKeyRequests = rec.numberOfKeyRequests;
    _ratioOfMessagesInLastWindow = rec.ratioOfMessagesInLastWindow;
    _ratioOfFilesInLastWindow = rec.ratioOfFilesInLastWindow;
    _certIsOK = rec.certIsOK;
    _isDirty = YES;
    [self recomputeCost];
}

- (double)cost {
    if (_isDirty){
        [self recomputeCost];
    }

    return _cost;
}

- (void)setAvailableKeys:(NSInteger)availableKeys {
    _availableKeys = availableKeys;
    _isDirty = YES;
}

- (void)setMaximalKeys:(NSInteger)maximalKeys {
    _maximalKeys = maximalKeys;
    _isDirty = YES;
}

- (void)setNumberOfKeyRequests:(NSInteger)numberOfKeyRequests {
    _numberOfKeyRequests = numberOfKeyRequests;
    _isDirty = YES;
}

- (void)setRatioOfMessagesInLastWindow:(double)ratioOfMessagesInLastWindow {
    _ratioOfMessagesInLastWindow = ratioOfMessagesInLastWindow;
    _isDirty = YES;
}

- (void)setRatioOfFilesInLastWindow:(double)ratioOfFilesInLastWindow {
    _ratioOfFilesInLastWindow = ratioOfFilesInLastWindow;
    _isDirty = YES;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _isDirty = [coder decodeBoolForKey:@"_isDirty"];
        _cost = [coder decodeDoubleForKey:@"_cost"];
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.availableKeys = [coder decodeIntForKey:@"self.availableKeys"];
        self.maximalKeys = [coder decodeIntForKey:@"self.maximalKeys"];
        self.numberOfKeyRequests = [coder decodeIntForKey:@"self.numberOfKeyRequests"];
        self.ratioOfMessagesInLastWindow = [coder decodeDoubleForKey:@"self.ratioOfMessagesInLastWindow"];
        self.ratioOfFilesInLastWindow = [coder decodeDoubleForKey:@"self.ratioOfFilesInLastWindow"];
        self.certIsOK = [coder decodeBoolForKey:@"self.certIsOK"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:_isDirty forKey:@"_isDirty"];
    [coder encodeDouble:_cost forKey:@"_cost"];
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeInt:self.availableKeys forKey:@"self.availableKeys"];
    [coder encodeInt:self.maximalKeys forKey:@"self.maximalKeys"];
    [coder encodeInt:self.numberOfKeyRequests forKey:@"self.numberOfKeyRequests"];
    [coder encodeDouble:self.ratioOfMessagesInLastWindow forKey:@"self.ratioOfMessagesInLastWindow"];
    [coder encodeDouble:self.ratioOfFilesInLastWindow forKey:@"self.ratioOfFilesInLastWindow"];
    [coder encodeBool:self.certIsOK forKey:@"self.certIsOK"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXUserKeyRefreshRecord *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy->_isDirty = _isDirty;
        copy->_cost = _cost;
        copy.user = self.user;
        copy.availableKeys = self.availableKeys;
        copy.maximalKeys = self.maximalKeys;
        copy.numberOfKeyRequests = self.numberOfKeyRequests;
        copy.ratioOfMessagesInLastWindow = self.ratioOfMessagesInLastWindow;
        copy.ratioOfFilesInLastWindow = self.ratioOfFilesInLastWindow;
        copy.certIsOK = self.certIsOK;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToRecord:other];
}

- (BOOL)isEqualToRecord:(PEXUserKeyRefreshRecord *)record {
    if (self == record)
        return YES;
    if (record == nil)
        return NO;
    if (_isDirty != record->_isDirty)
        return NO;
    if (_cost != record->_cost)
        return NO;
    if (self.user != record.user && ![self.user isEqualToString:record.user])
        return NO;
    if (self.availableKeys != record.availableKeys)
        return NO;
    if (self.maximalKeys != record.maximalKeys)
        return NO;
    if (self.numberOfKeyRequests != record.numberOfKeyRequests)
        return NO;
    if (self.ratioOfMessagesInLastWindow != record.ratioOfMessagesInLastWindow)
        return NO;
    if (self.ratioOfFilesInLastWindow != record.ratioOfFilesInLastWindow)
        return NO;
    if (self.certIsOK != record.certIsOK)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) _isDirty;
    hash = hash * 31u + [[NSNumber numberWithDouble:_cost] hash];
    hash = hash * 31u + [self.user hash];
    hash = hash * 31u + self.availableKeys;
    hash = hash * 31u + self.maximalKeys;
    hash = hash * 31u + self.numberOfKeyRequests;
    hash = hash * 31u + [[NSNumber numberWithDouble:self.ratioOfMessagesInLastWindow] hash];
    hash = hash * 31u + [[NSNumber numberWithDouble:self.ratioOfFilesInLastWindow] hash];
    hash = hash * 31u + self.certIsOK;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_isDirty=%d", _isDirty];
    [description appendFormat:@", _cost=%f", _cost];
    [description appendFormat:@", self.user=%@", self.user];
    [description appendFormat:@", self.availableKeys=%li", (long)self.availableKeys];
    [description appendFormat:@", self.maximalKeys=%li", (long)self.maximalKeys];
    [description appendFormat:@", self.numberOfKeyRequests=%li", (long)self.numberOfKeyRequests];
    [description appendFormat:@", self.ratioOfMessagesInLastWindow=%f", self.ratioOfMessagesInLastWindow];
    [description appendFormat:@", self.ratioOfFilesInLastWindow=%f", self.ratioOfFilesInLastWindow];
    [description appendFormat:@", self.certIsOK=%d", self.certIsOK];
    [description appendString:@">"];
    return description;
}


@end
