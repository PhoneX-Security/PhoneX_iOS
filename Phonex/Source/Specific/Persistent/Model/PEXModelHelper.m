//
// Created by Matej Oravec on 05/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXModelHelper.h"
#import "PEXDbCursor.h"
#import "PEXDBModelBase.h"


@interface PEXModelHelper ()
{
@private
    int _index;
}

@property (nonatomic) PEXDbCursor * cursor;
@property (nonatomic) NSString * columnName;

@end

@implementation PEXModelHelper {

}

- (id) initWithCursor: (PEXDbCursor * const) cursor index: (const int) index
{
    self = [super init];

    self.cursor = cursor;
    _index = index;
    self.columnName = [cursor getColumnName:index];

    return self;
}

- (bool) assignStringTo: (NSString *  __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [self.cursor getString:_index];
        result = true;
    }

    return result;
}

- (bool) assignIntTo: (NSNumber * __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [self.cursor getInt:_index];
        result = true;
    }

    return result;
}

- (bool) assignInt64To: (NSNumber * __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [self.cursor getInt64:_index];
        result = true;
    }

    return result;
}

- (bool) assignDoubleTo: (NSNumber * __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [self.cursor getDouble:_index];
        result = true;
    }

    return result;
}

- (bool) assignBlobTo: (NSData * __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [self.cursor getBlob:_index];
        result = true;
    }

    return result;
}

- (bool) assignDateTo: (NSDate * __strong *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [PEXDbModelBase getDateFromCursor:self.cursor idx:_index];
        result = true;
    }

    return result;
}

- (bool) assignBoolTo: (bool *) value_out ifMatchesColumn: (NSString * const) columnName
{
    bool result = false;

    if ([columnName isEqualToString:self.columnName])
    {
        *value_out = [[self.cursor getInt: _index] integerValue] == 1;
        result = true;
    }

    return result;
}

@end