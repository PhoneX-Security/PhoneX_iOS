//
// Created by Dusan Klinec on 21.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushRequestPart;


@interface PEXPushRequestMsg : NSObject
/**
* Array of PEXPushRequestPart.
*/
@property(nonatomic) NSMutableArray * requests;
@property(nonatomic) long tstamp;

-(void) addPart: (PEXPushRequestPart *) part;
-(void) clear;
-(void) mergeWithMessage: (PEXPushRequestMsg *) req;

@end