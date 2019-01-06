//
// Created by Dusan Klinec on 18.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCallLogManager.h"

#import "PEXDbCallLog.h"
#import "PEXDbAppContentProvider.h"

@implementation PEXCallLogManager {

}

+ (void) seeAll
{
    PEXDbContentValues * const cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_DBCLOG_FIELD_SEEN_BY_USER integer:1];

    [[PEXDbAppContentProvider instance]
     update:[PEXDbCallLog getURI]
     ContentValues:cv
     selection:nil
     selectionArgs:nil];
}

+ (void) seeWithId: (const NSNumber * const) id
{
    PEXDbContentValues * const cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_DBCLOG_FIELD_SEEN_BY_USER integer:1];

    [[PEXDbAppContentProvider instance]
     update:[PEXDbCallLog getURI]
     ContentValues:cv
     selection:[PEXDbCallLog getWhereForId]
     selectionArgs:[PEXDbCallLog getWhereForIdArgs:id]];
}

@end