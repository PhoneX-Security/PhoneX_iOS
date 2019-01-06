//
// Created by Dusan Klinec on 15.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXRestRequester.h"

typedef void (^PEXLicenseLoadFinished)(NSDictionary * licenses);
typedef void (^PEXLicenseLoadFailed)(void);

@interface PEXLicenseLoader : PEXRestRequester
@property(nonatomic, readonly) NSError * loadError;

- (bool) loadItemsCompletion: (NSArray *) licenseIds
                  completion: (PEXLicenseLoadFinished)completion
                errorHandler: (PEXLicenseLoadFailed)errorHandler;

@end