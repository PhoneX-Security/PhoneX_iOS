//
// Created by Matej Oravec on 09/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "PEXDbLoadResult.h"

@class PEXDbStatement;
@class PEXDbCursor;
@class PEXUser;

// Event called when database should be reloaded (too many consecutive fatal DB errors).
FOUNDATION_EXPORT NSString * const PEX_ACTION_DB_RELOAD_REQUEST;
FOUNDATION_EXPORT NSString * const PEX_ACTION_DB_OPENED;

@interface PEXDatabase : NSObject
@property (nonatomic, readonly) NSString * databasePath;
@property (nonatomic, readonly) int consecutiveDbErrorCount;
@property (nonatomic, readonly) int failedDbReloads;

+ (int64_t) idOfLastInsertedRow;

+ (bool) executeSimple: (const char * const) sqlStmt;
- (bool) executeSimple: (const char * const) sqlStmt;

+ (int) executePreparedEx: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments;
+ (bool) executePrepared: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments;
+ (PEXDbCursor *)prepareCursor:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments;
- (PEXDbCursor *)prepareCursor:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments;

+ (PEXDbOpenStatus)tryOpenDatabase: (const PEXUser * const) user
                    encryptionKey: (NSString * const) key;
+ (PEXDbLoadResult)openOrCreateDatabase: (const PEXUser * const) loggedUser
                  encryptionKey: (NSString * const) key;
+ (int)unloadDatabase;

+ (bool) rekeyDatabase: (NSString * const) oldKey withKey:(NSString * const) newKey;

+ (void) initInstance;
+ (PEXDatabase *) instance;
+ (void) removeAllDatabases;
+ (bool) removeDatabase: (const PEXUser * const) user;

+ (NSString *) sqlEscapeString: (NSString *) input;
+ (NSString *) getDatabasePath: (const PEXUser * const) user;

/**
* Tries reload currently loaded database. If fails, no unloading happens.
*/
- (BOOL)tryReloadDatabase:(const PEXUser *const)user encryptionKey:(NSString *const)key pStatus: (PEXDbOpenStatus *) pStatus;

/**
* Performs simple query SELECT count(*) FROM sqlite_master;
* to test database was opened and unlocked successfully.
*/
- (bool) testDatabaseRead: (int *) pStatus;

/**
* Generate database logging report for debugging DB errors.
*/
- (NSString *) genDbLogReport;

+ (NSUInteger) fixUpDatabaseFileProtection: (NSString *) dbPath;

@end