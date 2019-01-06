//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXRestRequester.h"

@interface PEXRestRequester ()

@property (nonatomic) NSURLConnection * connection;
@property (nonatomic) NSMutableData * receivedData;

- (NSArray *) satisfactoryCodes;
- (void) errorOccurred;
- (void) nilProperties;

@end