//
// Created by Matej Oravec on 27/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbAppContentProvider.h"

@class PEXURIMatcher;

@interface PEXDbAppContentProvider ()

// Resolves URI to our identifier.
-(int) getURIId: (const PEXDbUri * const) uri;

// Returns default table name for the registered URI based on its ID.
-(NSString *) getTableFromID: (int) uriID;

// Resolves URI to table name, if found. Exception is thrown otherwise.
-(NSString *) getTableFromURIOrThrow: (const PEXDbUri * const) uri;

@end