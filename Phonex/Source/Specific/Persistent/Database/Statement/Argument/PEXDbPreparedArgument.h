//
// Created by Matej Oravec on 23/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbStatement;

@protocol PEXDbPreparedArgument <NSObject>

- (int) addToStatement: (PEXDbStatement * const) statement at:(const int) position;

@end