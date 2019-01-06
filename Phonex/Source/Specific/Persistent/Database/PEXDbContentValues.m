//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbContentValues.h"

@interface PEXDbContentValues ()
@property(nonatomic) NSMutableDictionary * dat;
@property(nonatomic) NSMutableDictionary * met;
@end

@implementation PEXDbContentValues {

}

+ (int)type2SQLType:(int)type {
    switch(type){
        case PEXDBCV_TYPE_BOOL:
        case PEXDBCV_TYPE_BYTE:
        case PEXDBCV_TYPE_INT:
        case PEXDBCV_TYPE_LONG:
        case PEXDBCV_TYPE_NSNUMBER:
            return PEXDBCV_SQLTYPE_INTEGER;
        case PEXDBCV_TYPE_FLOAT:
        case PEXDBCV_TYPE_DOUBLE:
            return PEXDBCV_SQLTYPE_REAL;
        case PEXDBCV_TYPE_NSDATA:
            return PEXDBCV_SQLTYPE_BLOB;
        case PEXDBCV_TYPE_NSSTRING:
            return PEXDBCV_SQLTYPE_TEXT;
        default:
            return PEXDBCV_SQLTYPE_TEXT;
    }
}

+ (NSNumber *)getNumericDateRepresentation:(NSDate *)value {
    return value == nil ? nil : @([value timeIntervalSince1970]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dat = [[NSMutableDictionary alloc] init];
        self.met = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)clear {
    [self.dat removeAllObjects];
    [self.met removeAllObjects];
}

- (BOOL)containsKey:(NSString *)key {
    return (self.dat)[key] != nil;
}

- (BOOL)isNull:(NSString *)key {
    id obj = (self.dat)[key];
    return obj != nil && [[NSNull null] isEqual:obj];
}

- (BOOL)equals:(id)object {
    if (object==nil){
        return NO;
    }

    if (![object isKindOfClass:[PEXDbContentValues class]]){
        return NO;
    }

    __weak PEXDbContentValues * rem = (PEXDbContentValues *) object;
    return [self.dat isEqualToDictionary:rem.dat];
}

- (id)get:(NSString *)key {
    return self.dat[key];
}

- (BOOL)getAsBoolean:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return NO;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return NO;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.boolValue;
}

- (unsigned char) getAsByte:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return 0;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.unsignedCharValue;
}

- (NSData *)getAsByteArray:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil) {
        DDLogWarn(@"Given key [%@] does not exist", key);
        return nil;
    }

    if ([obj isKindOfClass:[NSNull class]]){
        return nil;
    }

    if (![obj isKindOfClass:[NSData class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return nil;
    }

    return (NSData *) obj;
}

- (NSNumber *)getAsNumber:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil) {
        DDLogWarn(@"Given key [%@] does not exist", key);
        return nil;
    }

    if ([obj isKindOfClass:[NSNull class]]){
        return nil;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return nil;
    }

    return (NSNumber *) obj;
}

- (NSString *)getAsString:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil) {
        DDLogWarn(@"Given key [%@] does not exist", key);
        return nil;
    }

    if ([obj isKindOfClass:[NSNull class]]){
        return nil;
    }

    if (![obj isKindOfClass:[NSString class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return nil;
    }

    return (NSString *) obj;
}

- (double)getAsDouble:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0.0;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return 0.0;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.doubleValue;
}

- (float)getAsFloat:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0.0;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return 0.0;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.floatValue;
}

- (NSInteger) getAsInteger:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return 0;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.integerValue;
}

- (int64_t)getAsInt64:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0l;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return NO;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.longLongValue;
}

- (short)getAsShort:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return 0;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return 0;
    }

    NSNumber * num = (NSNumber *) obj;
    return num.shortValue;
}

- (NSDate *)getAsDate:(NSString *)key {
    id obj = self.dat[key];
    if (obj==nil){
        DDLogWarn(@"Given key [%@] does not exist", key);
        return nil;
    }

    if (![obj isKindOfClass:[NSNumber class]]){
        DDLogWarn(@"Given key [%@] does is not of a required type", key);
        return nil;
    }

    NSNumber * num = (NSNumber *) obj;
    return [NSDate dateWithTimeIntervalSince1970:[num doubleValue]];
}

- (NSUInteger)hash {
    return self.dat.hash;
}

- (NSArray *)keyList {
    return self.dat.allKeys;
}

- (NSSet *)keySet {
    return [NSSet setWithArray:self.dat.allKeys];
}

- (void)setMetaType: (NSString *) key type: (int) type {
    self.met[key] = @(type);
}

- (int)getType:(NSString *)key {
    id type = self.met[key];
    return type==nil ? PEXDBCV_TYPE_OBJECT : [((NSNumber *) type) integerValue];
}

- (void)put:(NSString *)key boolean:(BOOL)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_BOOL];
}

- (void)put:(NSString *)key byte:(Byte)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_BYTE];
}

- (void)put:(NSString *)key object:(id)object {
    if (object==nil){
        self.dat[key] = [NSNull null];
        return;
    }

    self.dat[key] = object;
    [self setMetaType:key type:PEXDBCV_TYPE_OBJECT];
}

- (void)put:(NSString *)key data:(NSData *)value {
    if (value==nil){
        self.dat[key] = [NSNull null];
        return;
    }

    self.dat[key] = value;
    [self setMetaType:key type:PEXDBCV_TYPE_NSDATA];
}

- (void)put:(NSString *)key string:(NSString *)value {
    if (value==nil){
        self.dat[key] = [NSNull null];
        return;
    }

    self.dat[key] = value;
    [self setMetaType:key type:PEXDBCV_TYPE_NSSTRING];
}

- (void)put:(NSString *)key number:(NSNumber *)value {
    if (value==nil){
        self.dat[key] = [NSNull null];
        return;
    }

    self.dat[key] = value;
    [self setMetaType:key type:PEXDBCV_TYPE_NSNUMBER];
}

- (void)put:(NSString *)key integer:(int)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_INT];
}

- (void)put:(NSString *)key float:(float)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_FLOAT];
}

- (void)put:(NSString *)key double:(double)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_DOUBLE];
}

- (void)put:(NSString *)key int64:(int64_t)value {
    self.dat[key] = @(value);
    [self setMetaType:key type:PEXDBCV_TYPE_LONG];
}

- (void)put:(NSString *)key NSNumberAsBoolean:(NSNumber *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    self.dat[key] = value != nil ? value : [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_BOOL];
}

- (void)put:(NSString *)key NSNumberAsInt:(NSNumber *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    self.dat[key] = value != nil ? value : [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_INT];
}

- (void)put:(NSString *)key NSNumberAsFloat:(NSNumber *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    self.dat[key] = value != nil ? value : [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_FLOAT];
}

- (void)put:(NSString *)key NSNumberAsDouble:(NSNumber *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    self.dat[key] = value != nil ? value : [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_DOUBLE];
}

- (void)put:(NSString *)key NSNumberAsLongLong:(NSNumber *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    self.dat[key] = value != nil ? value : [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_LONG];
}

- (void)put:(NSString *)key date:(NSDate *)value {
    // For further extension, in order to provide information about intended type
    // of the value stored in NSNumer. Not implemented yet. Just a wrapper.
    if (value == nil){
        [self put:key NSNumberAsDouble:nil];
    } else {
        [self put:key NSNumberAsDouble:@([value timeIntervalSince1970])];
    }
}

- (void)putAll:(PEXDbContentValues *)other {
    if (other==nil || other.size==0) {
        return;
    }

    NSArray * keyList = other.keyList;
    for(id key in keyList){
        self.dat[key] = [other get:key];
        self.met[key] = @([other getType:key]);
    }
}

- (void)putNull:(NSString *)key {
    self.dat[key] = [NSNull null];
    [self setMetaType:key type:PEXDBCV_TYPE_OBJECT];
}

- (void)remove:(NSString *)key {
    [self.dat removeObjectForKey:key];
    [self.met removeObjectForKey:key];
}

- (int)size {
    return (int)self.dat.count;
}

- (NSString *)toString {
    NSMutableString * sb = [[NSMutableString alloc] init];
    if (self.dat.count==0){
        [sb appendString:@"{#0; }"];
        return sb;
    }

    NSUInteger cn = self.dat.count;
    [sb appendFormat:@"{#%lu; ", (unsigned long)cn];

    NSUInteger idx=0;
    NSArray * keys = self.dat.allKeys;
    for(id key in keys){
        NSString * skey = (NSString *) key;
        [sb appendFormat:@"%@(%@): %@", skey, self.met[key], self.dat[key]];

        idx+=1;
        if (idx<cn){
            [sb appendString:@", "];
        }
    }

    return sb;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.dat=%@", self.dat];
    [description appendString:@">"];
    return description;
}

#pragma put_wrappers

/**
* Adds a value to the set.
*/
-(void) putIfNottNil:(NSString *)key object: (id) object
{
    if (object != nil) [self put:key object: object];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNottNil:(NSString *)key data: (NSData*) value
{
    if (value != nil) [self put:key data: value];
}

/**
* Adds a value to the set.
*/
-(void)putIfNotNil:(NSString *)key string: (NSString *) value
{
    if (value != nil) [self put:key string: value];
}

/**
* Adds a value to the set.
*/
-(void)putIfNotNil:(NSString *)key number: (NSNumber *) value
{
    if (value != nil) [self put:key number: value];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsBoolean: (NSNumber *) value
{
    if (value != nil) [self put:key NSNumberAsBoolean: value];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsInt: (NSNumber *) value
{
    if (value != nil) [self put:key NSNumberAsInt: value];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsFloat: (NSNumber *) value
{
    if (value != nil) [self put:key NSNumberAsFloat: value];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsDouble: (NSNumber *) value
{
    if (value != nil) [self put:key NSNumberAsDouble: value];
}

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsLongLong: (NSNumber *) value
{
    if (value != nil) [self put:key NSNumberAsLongLong: value];
}

/**
* Puts date to the set according to convention.
*/
-(void)putIfNotNil:(NSString *)key date:(NSDate *)value
{
    if (value != nil) [self put:key date: value];
}

@end