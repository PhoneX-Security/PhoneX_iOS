//
// Created by Matej Oravec on 28/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXUri.h"
#import "PEXUri_Protected.h"

@implementation PEXUri {

}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.uri = [coder decodeObjectForKey:@"self.uri"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.uri forKey:@"self.uri"];
}

- (BOOL)matchesBase:(const PEXUri *const)aUri {
    // Simplified URI matching.
    // In deal world we would have URI template here, e.g., content://net.phone.db/mockContacts/#
    // And we would match given URI against given template.
    //
    // If we do not have id, complete match is required.
    if (aUri == nil){
        return NO;
    }

    // Here we require a complete match.
    return [[aUri baseUri2string] isEqualToString:_uri];
}

- (BOOL)matches:(const PEXUri *const)aUri {
    return [self matchesBase:aUri];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToUri:other];
}

- (BOOL)isEqualToUri:(const PEXUri * const)uri {
    if (self == uri)
        return YES;
    if (uri == nil)
        return NO;
    if (self.uri != uri.uri && ![self.uri isEqualToString:uri.uri])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.uri hash];
}

- (NSString *)description {
    return self.uri;
}

- (NSString *)uri2string {
    return self.uri;
}

- (NSString *)baseUri2string {
    return self.uri;
}

@end