//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXToCall : NSObject {}
@property(nonatomic) NSNumber * pjsipAccountId;
@property(nonatomic) NSString * callee;
- (instancetype)initWithPjsipAccountId:(NSNumber *)pjsipAccountId callee:(NSString *)callee;
+ (instancetype)callWithPjsipAccountId:(NSNumber *)pjsipAccountId callee:(NSString *)callee;
@end

@interface PEXPjHelper : NSObject
@end