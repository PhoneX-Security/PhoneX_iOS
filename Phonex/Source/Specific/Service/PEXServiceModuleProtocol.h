//
// Created by Dusan Klinec on 03.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXServiceModuleProtocol <NSObject>
- (void) doRegister;
- (void) doUnregister;

@optional
- (void)updatePrivData:(PEXUserPrivate *)privData;
@end