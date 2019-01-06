//
// Created by Matej Oravec on 28/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXContentProvider.h"
#import "PEXContentObservable.h"


@interface PEXDbContentProvider : NSObject<PEXContentProvider, PEXContentObservable>

- (void) unregisterAll;

// Raw query for virtual tables / views.
- (PEXDbCursor *) queryRaw: (NSString * const) query selectionArgs: (const NSArray * const) selectionArgs;

/**
* Performs simple query SELECT count(*) FROM sqlite_master;
* to test database was opened and unlocked successfully.
*/
- (bool) testDatabaseRead: (int *) pStatus;
@end