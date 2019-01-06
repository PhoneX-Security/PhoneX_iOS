//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Class for generating, saving and loading random salt to/from SharedPreferences.
 *
 * @author ph4r05
 */
@interface PEXSharedPrefsSalt : NSObject
+(NSString *) getSaltPrefsKey: (NSString *) prefsKey user:(NSString *) user;
+(BOOL) saltExists: (NSString *) prefsKey user: (NSString *) user;
+(NSData *) generateNewSalt: (NSString *) prefsKey user: (NSString *) user saltSize: (int) saltSize;
+(NSData *) getSalt: (NSString *) prefsKey user: (NSString *) user;
@end