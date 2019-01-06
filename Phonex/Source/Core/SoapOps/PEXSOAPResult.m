//
// Created by Dusan Klinec on 07.04.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXSOAPResult.h"
#import "PEXUtils.h"


@implementation PEXSOAPResult {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.code = 0;
        self.ex = nil;
        self.soapTaskError = PEX_SOAP_ERROR_NONE;
        self.err = nil;
    }

    return self;
}

- (BOOL)wasError {
    return _code < 0 || _soapTaskError != PEX_SOAP_ERROR_NONE || _err != nil;
}

+ (BOOL)wasError: (PEXSOAPResult *) res {
    return res == nil || [res wasError];
}

- (BOOL)wasErrorWithConnectivity {
    return _err != nil && [PEXUtils doErrorMatch:_err domain:NSURLErrorDomain];
}

- (void)setToRef:(PEXSOAPResult **)res {
    if (res == nil) return;
    *res = self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.cancelDetected=%d", self.cancelDetected];
    [description appendFormat:@", self.ex=%@", self.ex];
    [description appendFormat:@", self.err=%@", self.err];
    [description appendFormat:@", self.code=%li", (long)self.code];
    [description appendFormat:@", self.responseCode=%li", (long)self.responseCode];
    [description appendFormat:@", self.soapTaskError=%d", self.soapTaskError];
    [description appendFormat:@", self.timeoutDetected=%d", self.timeoutDetected];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.cancelDetected = [coder decodeBoolForKey:@"self.cancelDetected"];
        self.ex = [coder decodeObjectForKey:@"self.ex"];
        self.err = [coder decodeObjectForKey:@"self.err"];
        self.code = [coder decodeIntForKey:@"self.code"];
        self.responseCode = [coder decodeIntForKey:@"self.responseCode"];
        self.soapTaskError = (PEXSoapTaskErrorEnum) [coder decodeIntForKey:@"self.soapTaskError"];
        self.timeoutDetected = [coder decodeBoolForKey:@"self.timeoutDetected"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.cancelDetected forKey:@"self.cancelDetected"];
    [coder encodeObject:self.ex forKey:@"self.ex"];
    [coder encodeObject:self.err forKey:@"self.err"];
    [coder encodeInt:self.code forKey:@"self.code"];
    [coder encodeInt:self.responseCode forKey:@"self.responseCode"];
    [coder encodeInt:self.soapTaskError forKey:@"self.soapTaskError"];
    [coder encodeBool:self.timeoutDetected forKey:@"self.timeoutDetected"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXSOAPResult *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.cancelDetected = self.cancelDetected;
        copy.ex = self.ex;
        copy.err = self.err;
        copy.code = self.code;
        copy.responseCode = self.responseCode;
        copy.soapTaskError = self.soapTaskError;
        copy.timeoutDetected = self.timeoutDetected;
    }

    return copy;
}


@end