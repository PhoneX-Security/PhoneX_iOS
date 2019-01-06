//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PEXDBCV_TYPE_BOOL 1
#define PEXDBCV_TYPE_BYTE 2
#define PEXDBCV_TYPE_INT 3
#define PEXDBCV_TYPE_LONG 4
#define PEXDBCV_TYPE_DOUBLE 5
#define PEXDBCV_TYPE_FLOAT 6
#define PEXDBCV_TYPE_NSSTRING 7
#define PEXDBCV_TYPE_NSNUMBER 8
#define PEXDBCV_TYPE_NSDATA 9
#define PEXDBCV_TYPE_OBJECT 10


// NULL. The value is a NULL value.
#define PEXDBCV_SQLTYPE_NULL 1
// INTEGER. The value is a signed integer, stored in 1, 2, 3, 4, 6, or 8 bytes depending on the magnitude of the value.
#define PEXDBCV_SQLTYPE_INTEGER 2
//REAL. The value is a floating point value, stored as an 8-byte IEEE floating point number.
#define PEXDBCV_SQLTYPE_REAL 3
//TEXT. The value is a text string, stored using the database encoding (UTF-8, UTF-16BE or UTF-16LE).
#define PEXDBCV_SQLTYPE_TEXT 4
// BLOB. The value is a blob of data, stored exactly as it was input.
#define PEXDBCV_SQLTYPE_BLOB 5

@interface PEXDbContentValues : NSObject

/**
* Converts type to sqlite type.
*/
+(int) type2SQLType: (int) type;
+(NSNumber *) getNumericDateRepresentation:(NSDate *)value;

/**
 * Removes all values.
 */
-(void) clear;

/**
* Returns true if this object has the named value.
*/
-(BOOL)	containsKey: (NSString *) key;

/**
* If null.
*/
-(BOOL) isNull: (NSString *) key;

/**
* Compares this instance with the specified object and indicates if they are equal.
*/
-(BOOL)	equals: (id) object;

/**
* Gets a value.
*/
-(id) get:(NSString *) key;

/**
* Returns a specified type, if was set with specialized setter.
*/
-(int) getType: (NSString *) key;

/**
* Gets a value and converts it to a Boolean.
*/
-(BOOL) getAsBoolean:(NSString *)key;

/**
* Gets a value and converts it to a Byte.
*/
-(unsigned char) getAsByte: (NSString *) key;

/**
* Gets a value that is a byte array.
*/
-(NSData *)	getAsByteArray: (NSString *) key;

/**
* Gets a value that is a NSNumber.
*/
-(NSNumber *) getAsNumber: (NSString *) key;

/**
* Gets a value and converts it to a String.
*/
-(NSString *) getAsString:(NSString *)key;

/**
* Gets a value and converts it to a Double.
*/
-(double) getAsDouble:(NSString *)key;

/**
* Gets a value and converts it to a Double.
*/
-(float) getAsFloat:(NSString *)key;

/**
* Gets a value and converts it to a Double.
*/
-(NSInteger) getAsInteger:(NSString *)key;

/**
* Gets a value and converts it to a Long.
*/
-(int64_t)getAsInt64:(NSString *)key;

/**
* Gets a value and converts it to a String.
*/
-(short) getAsShort:(NSString *)key;

/**
* Gets a value as a date according to the convention.
*/
-(NSDate *) getAsDate:(NSString *)key;

/**
* Returns a list of all of the keys
*/
-(NSArray*) keyList;

/**
* Returns a set of all of the keys
*/
-(NSSet*) keySet;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key boolean: (BOOL) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key byte: (Byte) value;

/**
* Adds a value to the set.
*/
-(void) put:(NSString *)key object: (id) object;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key data: (NSData*) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key string: (NSString *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key number: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key integer: (int) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key float: (float) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key double: (double) value;

/**
* Adds a value to the set.
*/
-(void)put:(NSString *)key int64: (int64_t) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key NSNumberAsBoolean: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key NSNumberAsInt: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key NSNumberAsFloat: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key NSNumberAsDouble: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	put:(NSString *)key NSNumberAsLongLong: (NSNumber *) value;

/**
* Puts date to the set according to convention.
*/
-(void)put:(NSString *)key date:(NSDate *)value;

/**
* Adds all values from the passed in PEXDbContentValues.
*/
-(void)	putAll:(PEXDbContentValues *) other;

/**
* Adds a null value to the set.
*/
-(void)	putNull:(NSString *)key;

/**
* Remove a single value.
*/
-(void)	remove:(NSString *)key;

/**
* Returns the number of values.
*/
-(int)	size;

/**
* Returns a string containing a concise, human-readable description of this object.
*/
-(NSString*)	toString;

- (NSString *)description;

//Set<Entry<String, Object>>	valueSet;

#pragma put_wrappers

/**
* Adds a value to the set.
*/
-(void) putIfNottNil:(NSString *)key object: (id) object;

/**
* Adds a value to the set.
*/
-(void)	putIfNottNil:(NSString *)key data: (NSData*) value;

/**
* Adds a value to the set.
*/
-(void)putIfNotNil:(NSString *)key string: (NSString *) value;

/**
* Adds a value to the set.
*/
-(void)putIfNotNil:(NSString *)key number: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsBoolean: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsInt: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsFloat: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsDouble: (NSNumber *) value;

/**
* Adds a value to the set.
*/
-(void)	putIfNotNil:(NSString *)key NSNumberAsLongLong: (NSNumber *) value;

/**
* Puts date to the set according to convention.
*/
-(void)putIfNotNil:(NSString *)key date:(NSDate *)value;

@end