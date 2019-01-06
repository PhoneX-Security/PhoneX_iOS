//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller <NSObject>
-(BOOL) isCancelled;

@optional
-(BOOL) isCancelled: (NSString *) key;
@end