//
// Created by Dusan Klinec on 18.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "hr.h"

@class hr_authCheckV3Response;
@class USBoolean;


@interface PEXSoapAdditions : NSObject
+(NSString *) authCheckToString: (hr_authCheckV3Response *) resp;
@end