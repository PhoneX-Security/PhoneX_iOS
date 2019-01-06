//
// Created by Matej Oravec on 22/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbUri.h"
#import "PEXDbContentValues.h"
#import "PEXDbStatement.h"

#import "PEXDbCursor.h"
#import "PEXDbStatement.h"

#define POSITION_BEFORE_FIRST 0
#define POSITION_FIRST 1
#define POSITION_LAST _rowCount
#define POSITION_AFTER_LAST (_rowCount + 1)

@interface PEXDbCursor ()
{
    bool _closed;
    int _position;
    int _rowCount;
}
@property (nonatomic) PEXDbStatement * pexStatement;

@end

@implementation PEXDbCursor {

}

// MAINTENANCE

- (id) initWithStatement: (PEXDbStatement * const) pexStatement
{
    self = [super init];
    self.pexStatement = pexStatement;

    [self initState];

    return self;
}

- (void)close
{
    _closed = true;
    [self.pexStatement finalize];
}

// HORIZONTAL

- (int) getColumnCount
{
    return sqlite3_column_count(self.pexStatement.statement);
}

- (int) getColumnIndex: (NSString * const) columnName
{
    int result = -1;
    const int columnCount = [self getColumnCount];
    const char * const columnNameUtf8 = [columnName UTF8String];
    for (int i = 0; i < columnCount; ++i)
    {
        if (strcmp(columnNameUtf8, sqlite3_column_name(self.pexStatement.statement, i)) == 0)
        {
            result = i;
            break;
        }
    }

    return result;
}

- (NSString *) getColumnName: (const int) index
{
    return [[NSString alloc] initWithUTF8String:sqlite3_column_name(self.pexStatement.statement, index)];
}

// VERTICAL
/**
* Sets _rowCount to number of row in the result statement and sets position to BEFORE FIRST
*/
- (void)initState
{
    sqlite3_stmt * const statement = self.pexStatement.statement;
    int result = 0;

    // resetting sets the position before First
    sqlite3_reset(statement);
    for (;(sqlite3_step(statement) == SQLITE_ROW); ++result);

    sqlite3_reset(statement);
    _position = POSITION_BEFORE_FIRST;

    _rowCount = result;
    _closed = false;
}

- (int) getCount
{
    return _rowCount;
}

- (int) getPosition
{
    return _position;
}

- (bool) move: (const int) offset
{
    bool result = true;
    sqlite3_stmt * statement = self.pexStatement.statement;

    int finalOffset = 0;
    const int finalPosition = _position + offset;

    if ((finalPosition >= POSITION_BEFORE_FIRST) && (finalPosition <= POSITION_AFTER_LAST))
    {
        if ((offset < 0))
        {
            sqlite3_reset(statement);
            finalOffset = finalPosition;
        }
        else
        {
            finalOffset = offset;
        }

        for (int i = 0; i < finalOffset; ++i)
        {
            // result not checked because of precalculated
            // boudnaries
            result = (sqlite3_step(statement) == SQLITE_ROW);
        }

        _position = finalPosition;
    }
    else
    {
        result = false;
    }

    return result;
}

- (bool) moveToPrevious
{
    return [self move: -1];
}

- (bool) moveToNext
{
    return [self move: 1];
}

- (bool) moveToPosition: (const int) position
{
    return [self move: position - _position];
}

- (bool) moveToLast
{
    return [self moveToPosition:POSITION_LAST];
}

- (bool) moveToFirst
{
    return [self moveToPosition:POSITION_FIRST];
}

- (bool) moveBeforeFirst
{
    return [self moveToPosition:POSITION_BEFORE_FIRST];
}

// Q

- (bool) isAfterLast
{
    return _position == POSITION_AFTER_LAST;
}

- (bool) isBeforeFirst
{
    return _position == POSITION_BEFORE_FIRST;
}

- (bool) isClosed
{
    return _closed;
}

- (bool) isFirst
{
    return _position == POSITION_FIRST;
}

- (bool) isLast
{
    return _position == POSITION_LAST;
}

- (NSData *) getBlob: (const int) position
{
    NSData *result = nil;
    if ([self isNotNull:position])
    {
        result = [NSData dataWithBytes:sqlite3_column_blob(self.pexStatement.statement, position)
        length:(NSUInteger)sqlite3_column_bytes(self.pexStatement.statement, position)];
    }
    return result;
}

- (NSNumber *) getDouble: (const int) position {
    NSNumber *result = nil;
    if ([self isNotNull:position])
    {
        result = [[NSNumber alloc] initWithDouble:sqlite3_column_double(self.pexStatement.statement, position)];
    }
    return result;
}

- (NSNumber *) getInt: (const int) position
{
    NSNumber *result = nil;
    if ([self isNotNull:position])
    {
        result = [[NSNumber alloc] initWithInt:sqlite3_column_int(self.pexStatement.statement, position)];
    }
    return result;
}
- (NSNumber *)getInt64: (const int) position
{
    NSNumber *result = nil;
    if ([self isNotNull:position])
    {
        result = [[NSNumber alloc] initWithLongLong:sqlite3_column_int64(self.pexStatement.statement, position)];
    }
    return result;
}
- (NSString *) getString: (const int) position
{
    NSString *result = nil;
    if ([self isNotNull:position])
    {
        result = [[NSString alloc] initWithUTF8String:(const char* const)sqlite3_column_text(self.pexStatement.statement, position)];
    }
    return result;
}

- (bool) isNotNull: (const int) position
{
    return [self getType:position] != SQLITE_NULL;
}

- (int) getType: (const int) position
{
    return sqlite3_column_type(self.pexStatement.statement, position);
}

@end