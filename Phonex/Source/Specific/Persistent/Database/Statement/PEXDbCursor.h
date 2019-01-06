//
// Created by Matej Oravec on 22/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbStatement;

/**
* PEXDbCursor
* Implementation of result database statement cursor according to the Android API
* http://developer.android.com/reference/android/database/Cursor.html
*/

@interface PEXDbCursor : NSObject

/**
* After initWithStatement the Cursor points BEFORE FIRST.
*/
- (id) initWithStatement: (PEXDbStatement * const) pexStatement;

/**
* Finalizes the statement so it is no longer usable for retrieving info.
* Any further usage may cause exception throw or undefined behavior.
*/
- (void) close;

/**
* @return - column count of the statement
*/
- (int) getColumnCount;

/**
* The method iterates linearly over columns and compares their
* names to the specfied one.
*
* @return - index of a column with specified name
*         - [0 - N] if the such column exists
*         - -1 ifno such column exists in the statement
*/
- (int) getColumnIndex: (NSString * const) columnName;

/**
* @return - column name or nil if there is no such index in the statement
*/
- (NSString *) getColumnName: (const int) index;

/**
* @return - row count initialized at the creation of the Cursor
*/
- (int) getCount;

/**
* 0               - BEFORE FIRST
* [1 - _rowCount] - valid position
* _rowCount + 1   - AFTER LAST
*
* @return - current position of the Cursor
*/
- (int) getPosition;

/**
* Moves the Cursor to offset from its current position
*
* If "offset" < 0 then the operation is costly because
* the position needs to be reset to the beginning and then
* iterated to the final position.
*
* @return if the move operation succeeded. If not, then the position
*         is as before the method call.
*         (e.g. cannot move beyond boundaries,
*         BEFORE FIRST - AFTER LAST are included)
*         FALSE is returned when it gets beyond
*         POSITION_BEFORE_FIRST, POSITION_AFTER_LAST
*/
- (bool) move: (const int) offset;

/**
* @see move: -1
*/
- (bool) moveToPrevious;

/**
* @see move: +1
*/
- (bool) moveToNext;

/**
* @see move: position - _position
*/
- (bool) moveToPosition: (const int) position;

/**
* @see moveToPosition: _rowCount
*/
- (bool) moveToLast;

/**
* @see moveToPosition: 1
*/
- (bool) moveToFirst;

/**
* @see moveToPosition: 0
*/
- (bool) moveBeforeFirst;

/**
* @return true if position is _rowCount + 1
*/
- (bool) isAfterLast;

/**
* @return true if position is 0
*/
- (bool) isBeforeFirst;

/**
* @return true if position is 1
*/
- (bool) isFirst;

/**
* @return true if position is _rowCount
*/
- (bool) isLast;

- (bool) isClosed;
//- (bool) isNull;

/**
* @return nil if the value in Db is NULL
*/
- (NSData *) getBlob: (const int) position;

/**
* @return nil if the value in Db is NULL
*/
- (NSNumber *) getDouble: (const int) position;
//- (float) getFloat: (const int) position; SQLITE has only type REAL (8-byte)

/**
* @return nil if the value in Db is NULL
*/
- (NSNumber *) getInt: (const int) position;

/**
* @return nil if the value in Db is NULL
*/
- (NSNumber *)getInt64: (const int) position;
//- (short) getShort: (const int) position;

/**
* @return nil if the value in Db is NULL
*/
- (NSString *) getString: (const int) position;

/**
* @return @see https://www.sqlite.org/c3ref/c_blob.html
*/
- (int) getType: (const int) position;

// copyStringToBuffer
// getColumnIndexOrThrow
// getComlunNames
// getExtras
// getNotificationUri
// getWantsAllOnMoveCalls
// onMove

// registerContentObserver
// registerDataSetObserver
// respond
//setNotificationUri
//unregisterContentObserver
//unregisterDataSetObserver


@end