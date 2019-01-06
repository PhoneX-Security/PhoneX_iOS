//
// Created by Matej Oravec on 26/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbUri.h"
#import "PEXUri_Protected.h"

@interface PEXDbUri () {}
@property (nonatomic) NSNumber * itemId;
@end

@implementation PEXDbUri {

}

- (instancetype)initWithUri:(NSString *)uri {
    self = [super init];
    if (self) {
        self.uri = uri;
        self.itemId = nil;
    }

    return self;
}

- (instancetype)initWithTableName:(NSString *)tableName andID:(int64_t)id1 {
    self = [super init];
    if (self) {
        self.uri = [NSString stringWithFormat:@"content://net.phonex.db/%@", tableName];
        self.itemId = @(id1);
    }

    return self;
}

- (instancetype)initWithTableName:(NSString *)tableName {
    return [self initWithTableName:tableName isBase:NO];
}

- (instancetype)initWithTableName:(NSString *)tableName isBase:(BOOL)base {
    self = [super init];
    if (self) {
        self.uri = [NSString stringWithFormat:@"content://net.phonex.db/%@%@", tableName, base ? @"/" : @""];
    }

    return self;
}

- (instancetype)initWithURI:(const PEXUri * const)uri {
    self = [super init];
    if (self) {
        self.uri = [uri uri2string];
    }

    return self;
}

- (instancetype)initWithURI:(const PEXUri * const)uri andID:(int64_t)id1 {
    self = [super init];
    if (self) {
        self.uri = [uri uri2string];
        self.itemId = @(id1);
    }

    return self;
}

-(BOOL) matchesBase:(const PEXUri *const)aUri {
    // Simplified URI matching.
    // In deal world we would have URI template here, e.g., content://net.phone.db/mockContacts/#
    // And we would match given URI against given template.
    //
    // If we do not have id, complete match is required.
    if (aUri == nil){
        return NO;
    }

    // Here we require a complete match.
    return [[aUri baseUri2string] isEqualToString:[self baseUri2string]];
}

- (BOOL)matches:(const PEXUri *const)aUri {
    if (aUri == nil){
        return NO;
    }

    if ([aUri isKindOfClass:[PEXDbUri class]]){
        // If number is set, compare as strings.
        PEXDbUri const * const dbUri = (PEXDbUri const * const) aUri;
        if (dbUri.itemId != nil && self.itemId != nil){
            NSString * toCompare = [dbUri uri2string];
            return [self.uri2string isEqualToString:toCompare];
        }

        // Without ID, compare just basic uri.
        NSString * toCompare = [dbUri baseUri2string];
        return [[self baseUri2string] isEqualToString:toCompare];
    }

    // Ordinary URI.
    NSString * toCompare = [aUri uri2string];
    return [self.uri isEqualToString:toCompare];
}

- (NSString *)baseUri2string {
    return self.uri;
}

- (NSString *)uri2string {
    if (self.itemId == nil){
        return self.uri;
    }

    NSString *maybeSlash = [self.uri substringFromIndex: [self.uri length] - 1];
    if (maybeSlash == nil || ![maybeSlash isEqualToString:@"/"]){
        return [NSString stringWithFormat:@"%@/%lld", self.uri, [self.itemId longLongValue]];
    } else {
        return [NSString stringWithFormat:@"%@%lld", self.uri, [self.itemId longLongValue]];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.itemId = [coder decodeObjectForKey:@"self.itemId"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.itemId forKey:@"self.itemId"];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"self.uri=%@, ", self.uri];
    [description appendFormat:@"self.itemId=%@", self.itemId];

    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), description];
}

+ (instancetype)uriWithUri:(NSString *)uri {
    return [[self alloc] initWithUri:uri];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToDbUri:other];
}

- (BOOL)isEqualToDbUri:(PEXDbUri *)uri {
    if (self == uri)
        return YES;
    if (uri == nil)
        return NO;
    if (![super isEqual:uri])
        return NO;
    if (self.itemId != uri.itemId && ![self.itemId isEqualToNumber:uri.itemId])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [super hash];
    hash = hash * 31u + [self.itemId hash];
    return hash;
}


@end