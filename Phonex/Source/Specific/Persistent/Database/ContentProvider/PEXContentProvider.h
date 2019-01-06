//
// Created by Matej Oravec on 21/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbCursor;
@class PEXDbContentValues;
@class PEXDbUri;

@protocol PEXContentProvider <NSObject>

- (PEXDbCursor *) query: (const PEXDbUri * const) uri
             projection: (const NSArray *const) projection
              selection: (NSString *const) selection
          selectionArgs: (const NSArray *const) selectionArgs
              sortOrder: (NSString *const) sortOrder;

// FOR PEXDbContentProvider returns currently always nil
- (const PEXDbUri * const) insert: (const PEXDbUri * const) uri
  contentValues:(const PEXDbContentValues * const)contentValues;

- (bool) update:(const PEXDbUri * const) uri
  ContentValues: (const PEXDbContentValues * const)contentValues
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs;

- (bool) delete:(const PEXDbUri * const) uri
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs;

- (bool) bulk:(const PEXDbUri * const) uri
       insert:(const NSArray * const)contentValuesArray;

/**
 * Extended interface, returns negative number in case of an error.
 * Otherwise returns number of rows affected by the statement.
 * Return code semantics is same as on Android.
 */
- (int) updateEx:(const PEXDbUri * const) uri
  ContentValues: (const PEXDbContentValues * const)contentValues
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs;

/**
 * Extended interface, returns negative number in case of an error.
 * Otherwise returns number of rows affected by the statement.
 * Return code semantics is same as on Android.
 */
- (int) deleteEx:(const PEXDbUri * const) uri
      selection: (NSString * const) selection
  selectionArgs: (const NSArray * const) selectionArgs;
@end