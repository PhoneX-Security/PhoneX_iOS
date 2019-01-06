//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRestRequester.h"

typedef void (^PEXProductsLoadFinished)(NSDictionary * products);
typedef void (^PEXProductsLoadFailed)(void);

@interface PEXPackagesLoader : PEXRestRequester
@property(nonatomic, readonly) NSError * loadError;

- (bool) loadItemsCompletion: (PEXProductsLoadFinished)completion
                errorHandler: (PEXProductsLoadFailed)errorHandler;

@end