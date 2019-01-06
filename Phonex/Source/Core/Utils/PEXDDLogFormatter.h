//
// Created by Dusan Klinec on 30.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface PEXDDLogFormatter : NSObject <DDLogFormatter>
+ (instancetype)sharedInstance;
+ (NSString *) normalizeString: (NSString *) input len: (unsigned) length;
@end