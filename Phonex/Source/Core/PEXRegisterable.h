//
// Created by Dusan Klinec on 07.04.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXRegisterable <NSObject>
- (void)doRegister;
- (void)doUnregister;
@end