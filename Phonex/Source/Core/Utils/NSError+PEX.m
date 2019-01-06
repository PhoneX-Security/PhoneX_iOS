//
// Created by Dusan Klinec on 11.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "NSError+PEX.h"


@implementation NSError (PEX)
+ (NSDictionary *)chainSubError:(NSDictionary *)userInfo sub:(NSError *)subError {
    if (subError == nil){
        return userInfo;
    }

    if (userInfo == nil){
        return @{NSUnderlyingErrorKey : subError};
    }

    NSMutableDictionary * tmpDict = [userInfo mutableCopy];
    tmpDict[NSUnderlyingErrorKey] = subError;

    return [NSDictionary dictionaryWithDictionary:tmpDict];
}

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict subError:(NSError *)subError {
    return [NSError errorWithDomain:domain code:code userInfo:[NSError chainSubError:dict sub:subError]];
}

+ (NSError *)errorWithError:(NSError *)error subError:(NSError *)subError {
    if (error == nil){
        return nil;
    }

    if (subError == nil){
        return error;
    }

    NSMutableDictionary * tmpDict = [error.userInfo mutableCopy];
    tmpDict[NSUnderlyingErrorKey] = subError;
    tmpDict[PEXExtraOriginalError] = error;

    return [NSError errorWithDomain:error.domain code:error.code userInfo:[NSDictionary dictionaryWithDictionary:tmpDict]];
}

+ (NSError *) addUserDataToError: (NSError *) err userData: (NSDictionary *) toAdd {
    if (toAdd == nil || [toAdd count] == 0){
        return err;
    }

    if (err == nil){
        NSError * error = [[NSError alloc] initWithDomain:@"unknown" code:-1 userInfo:toAdd];
        return error;
    }

    NSMutableDictionary * tmpDict = [err.userInfo mutableCopy];
    [tmpDict addEntriesFromDictionary:toAdd];
    return [NSError errorWithDomain:err.domain code:err.code userInfo:[NSDictionary dictionaryWithDictionary:tmpDict]];
}

@end