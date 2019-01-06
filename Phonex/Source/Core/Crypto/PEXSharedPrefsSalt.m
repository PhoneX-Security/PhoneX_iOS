//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSharedPrefsSalt.h"
#import "PEXSecurityCenter.h"
#import "PEXCryptoUtils.h"


@implementation PEXSharedPrefsSalt {

}

/**
* Returns preference key for salt for the given user.
* @param user
* @return
*/
+(NSString *) getSaltPrefsKey: (NSString *) prefsKey user:(NSString *) user{
    if (user==nil) {
        [NSException raise:@"IllegalArgumentException" format:@"Cannot work with null"];
    }

    const uint64_t len = [user length];
    if (len==0) {
        return [NSString stringWithFormat:@"%@_DEFAULT", prefsKey];
    }

    NSString * ukey = [PEXSecurityCenter getUsernamePathKey:user];
    return [NSString stringWithFormat:@"%@_%@", prefsKey, ukey];
}

/**
* Returns true if there is stored a salt value in a shared preferences.
* @param ctxt
* @return
*/
+(BOOL) saltExists: (NSString *) prefsKey user: (NSString *) user{
    NSUserDefaults const * defaults = [NSUserDefaults standardUserDefaults];
    NSString * key = [self getSaltPrefsKey:prefsKey user:user];
    const id obj = [defaults objectForKey: key];
    return obj!=nil;
}

/**
* Generates new salt to the shared preferences.
* @param ctxt
* @param rand
*/
+(NSData *) generateNewSalt: (NSString *) prefsKey user: (NSString *) user saltSize: (int) saltSize{
    NSMutableData * salt = [PEXCryptoUtils secureRandomData:nil len:saltSize amplifyWithArc:YES];
    NSString * stringSalt = [salt base64EncodedStringWithOptions:0];

    NSString * key = [self getSaltPrefsKey:prefsKey user:user];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:stringSalt forKey:key];
    [defaults synchronize];

    return salt;
}

/**
* Loads salt from preferences
* @param ctxt
* @return
* @throws IOException
*/
+(NSData *) getSalt: (NSString *) prefsKey user: (NSString *) user{
    NSString * key = [self getSaltPrefsKey:prefsKey user:user];
    NSUserDefaults const * defaults = [NSUserDefaults standardUserDefaults];

    id obj = [defaults objectForKey:key];
    if (obj == nil){
        DDLogWarn(@"Warning: no salt for key: %@", prefsKey);
        return nil;
    }

    NSString * saltEncoded = (NSString *)obj;
    NSData * decodedData = [[NSData alloc] initWithBase64EncodedString:saltEncoded options:0];

    return decodedData;
}

@end