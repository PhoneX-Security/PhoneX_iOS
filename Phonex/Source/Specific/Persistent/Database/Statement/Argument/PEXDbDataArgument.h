//
// Created by Matej Oravec on 23/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbPreparedArgument.h"


@interface PEXDbDataArgument : NSObject<PEXDbPreparedArgument>

- (id)initWithData:(NSData *const)data;

@end