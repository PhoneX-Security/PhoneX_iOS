//
// Created by Dusan Klinec on 03.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbContentProvider.h"

@interface PEXCListChangeParams : NSObject
/**
* Contact system identifier that will be added.
*/
@property (nonatomic) NSString * userName;

/**
* Contact alias, defined by the user.
*/
@property (nonatomic) NSString * diplayName;

/**
* Specifies whitelist status. If true, contact can
* send us messages or call us.
*/
@property (nonatomic) BOOL inWhitelist;

/**
* If true, contact will be added as hidden to the contact list.
* By default set to false.
*/
@property (nonatomic) BOOL addAsHidden;
@property (nonatomic) PEXDbContentProvider * cr;
@end
