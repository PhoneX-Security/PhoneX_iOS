//
//  PEXCredentials.h
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXCredentials : NSObject

@property (nonatomic) NSString * username;
@property (nonatomic) NSString * password;

- (BOOL)isMissingData;
- (instancetype)initWithPassword:(NSString *)password username:(NSString *)username;
+ (instancetype)credentialsWithPassword:(NSString *)password username:(NSString *)username;

@end
