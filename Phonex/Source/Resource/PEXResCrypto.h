//
// Created by Dusan Klinec on 02.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXResCrypto : NSObject

+(NSData *) loadDHGroupId:(int) groupID;
+(NSData *) loadCARoots;
+(NSData *) loadCAWebRoots;
+(NSData *) loadExpiredCARoots;

@end