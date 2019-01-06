//
// Created by Matej Oravec on 05/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbCursor;


@interface PEXModelHelper : NSObject

- (id) initWithCursor: (PEXDbCursor * const) cursor index: (const int) index;

- (bool) assignStringTo: (NSString * __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignIntTo: (NSNumber *  __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignInt64To: (NSNumber *  __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignDoubleTo: (NSNumber *  __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignBlobTo: (NSData *  __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignDateTo: (NSDate * __strong *) value_out ifMatchesColumn: (NSString * const) columnName;
- (bool) assignBoolTo: (bool *) value_out ifMatchesColumn: (NSString * const) columnName;

@end