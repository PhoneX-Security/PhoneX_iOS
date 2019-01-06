//
// Created by Dusan Klinec on 11.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbContentProvider;


@interface PEXFirewall : NSObject
-(void) doRegister;
-(void) doUnregister;

-(BOOL) isCallAllowedFromRemote: (NSString *) fromRemote toLocal: (NSString *) toLocal;
-(BOOL) isMessageAllowedFromRemote: (NSString *) fromRemote toLocal: (NSString *) toLocal;

@end