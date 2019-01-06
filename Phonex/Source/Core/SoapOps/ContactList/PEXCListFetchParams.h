//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbAppContentProvider.h"

@interface PEXCListFetchParams : NSObject
@property (nonatomic) NSString * sip;

// ID of user in database - used to link contact list entry to account
@property (nonatomic) int64_t dbId;

// update contact list table from data fetched from
@property (nonatomic) BOOL updateClistTable;

// If YES, presence of the contact will be reset.
@property (nonatomic) BOOL resetPresence;

@property (nonatomic) PEXDbContentProvider * cr;

@end