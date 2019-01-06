//
//  PEXMessageUtils.h
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXMessageUtils : NSObject

+ (bool) isSendeable: (NSString * const) messageText;
+ (void) callSendMessage: (NSString *) to body: (NSString *) body;

@end
