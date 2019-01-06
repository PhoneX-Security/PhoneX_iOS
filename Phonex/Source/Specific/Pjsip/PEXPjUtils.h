//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pj/types.h"
#import "pjsip/sip_types.h"


@interface PEXPjUtils : NSObject

+(NSString *) copyToString: (pj_str_t const *) str;

/**
* Assigns string from NSString to PJ string.
* String is not copied. Life time should be same as the str object have.
*/
+(void) assignToPjString: (NSString const * const) str pjstr: (pj_str_t *) pj;

/**
 * Searches for a string header in the given message.
 */
+(NSString *) searchForHeader: (NSString *) hdr inMessage: (pjsip_msg *) msg;

+ (NSString *)getCallIdFromMessage:(pjsip_msg *)msg;
+ (pjsip_msg *)getMsgFromEvt:(pjsip_event *)e ;
+ (NSString *)getCallIdFromEvt:(pjsip_event *)e;

@end