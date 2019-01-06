//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSOAPTask.h"

@interface PEXOneTimeTokenTask : NSObject
@property (nonatomic) PEXSOAPTask * soapTask;
@property (nonatomic) NSString * username;
@property (nonatomic) NSString * userToken;
@property (nonatomic) NSString * serverToken;
@end

// TODO: finish this.