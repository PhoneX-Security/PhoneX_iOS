//
// Created by Matej Oravec on 25/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXLogsSender : NSObject

@property (nonatomic) NSString * userMessage;;

- (bool) sendLogs;

@end