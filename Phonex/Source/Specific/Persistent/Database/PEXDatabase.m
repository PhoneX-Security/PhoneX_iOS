//
// Created by Matej Oravec on 09/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

// The sqlite implementation library (i.e. sqlCipher) must compiled
// with -DSQLITE_THREADSAFE=1 (by default, when not set)
// which ensures serialized accces to the database.#import "PEXDbStatement.h"
// see https://www.sqlite.org/threadsafe.html

// auto-commit http://www.sqlite.org/c3ref/get_autocommit.html#import "PEXDbCursor.h"

#import "PEXDatabase.h"

#import "sqlite3.h"
#import "PEXUser.h"
#import "PEXContentProvider.h"
#import "PEXDbStatement.h"
#import "PEXDbPreparedArgument.h"
#import "PEXDbCursor.h"
#import "PEXDbAppContentProvider.h"
#import "PEXSecurityCenter.h"
#import "PEXDbContact.h"
#import "PEXDBMessage.h"
#import "PEXDbUserCertificate.h"
#import "PEXDBUserProfile.h"
#import "PEXDbMessageQueue.h"
#import "PEXDbCallLog.h"
#import "PEXDbSchemeUpdates.h"
#import "PEXDbDhKey.h"
#import "PEXDbReceivedFile.h"
#import "PEXDbFileTransfer.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXDbContactNotification.h"
#import "PEXUtils.h"
#import "PEXReport.h"
#import "PEXDbAccountingPermission.h"
#import "PEXDbAccountingLog.h"

NSString * const PEX_ACTION_DB_RELOAD_REQUEST = @"net.phonex.phonex.ACTION.db-reload-request";
NSString * const PEX_ACTION_DB_OPENED = @"net.phonex.phonex.ACTION.db-opened";
NSString * const PEX_ACTION_DB_RELOAD_CRASH = @"db.reload.crash";
NSString * const PEX_ACTION_DB_FAIL_CRASH = @"db.fail.crash";
NSString * const PEX_ACTION_DB_INSERT_ROW_CRASH = @"db.insertrow.crash";

static const char * const MAIN_DB = "main";
// default sqlite is 0
static const int USER_VERSION = 43;

@interface PEXDatabase ()
{
@private
    volatile int _commonersCount, _mastersCount;
    volatile int _consecutiveDbErrorCount;
    volatile int _failedDbReloads;
    volatile int _totalDbReloads;
    volatile int _totalErrors;
    volatile BOOL _rekeyInProgress;
    sqlite3 * _database;
}

@property (nonatomic) NSString * databasePath;

@property (nonatomic) NSLock * commonLock;
@property (nonatomic) NSLock * commonCountLock;
@property (nonatomic) NSLock * masterLock;
@property (nonatomic) NSLock * masterCountLock;

@property (nonatomic) NSDate * databaseLoadedTime;

@end

@implementation PEXDatabase

// PUBLIC ACCESS SECTION

- (sqlite3 *) database
{
    return _database;
}

/* COMMON SECTION */

// TODO concurrent safe?
+ (int64_t) idOfLastInsertedRow
{
    return [[self instance] idOfLastInsertedRow];
}

- (int64_t) idOfLastInsertedRow
{
    // TODO: just an experiment, race condition may set _database to nil after this check.
    if (_database == nil){
        DDLogError(@"idOfLastInsertedRow on unloaded database. dbPtr=%p", _database);
        [PEXReport logEvent:PEX_ACTION_DB_INSERT_ROW_CRASH];
        [NSException raise:@"PEXDatabaseException" format:@"Database is not loaded"];
    }

    return sqlite3_last_insert_rowid(_database);
}

+ (bool) executeSimple: (const char * const) sqlStmt
{
    return [[self instance] executeSimple:sqlStmt];
}

- (bool) executeSimple: (const char * const) sqlStmt {
    return [self executeSimpleNotAlone:sqlStmt status:NULL];
}

- (bool) executeSimple: (const char * const) sqlStmt status: (int *) pStatus
{
    bool result = false;
    [self commonLock];

    if (_database) {
        result = [self executeSimpleNotAlone:sqlStmt status:pStatus];
    } else {
        DDLogError(@"Could not execute statement since DB is nil");
    }

    [self commonQuit];
    return result;
}

- (bool) executeSimpleNotAlone: (const char * const) sqlStmt {
    return [self executeSimpleNotAlone:sqlStmt status:NULL];
}

- (bool) executeSimpleNotAlone: (const char * const) sqlStmt status: (int *) pStatus {
    char *errMsg;

    const int status = sqlite3_exec(_database, sqlStmt, NULL, NULL, &errMsg);
    if (pStatus != NULL){
        *pStatus = status;
    }

    if (status != SQLITE_OK)
    {
        DDLogError(@"ExecuteSimple message: %s, code: %d, statement [%s], dbPtr=%p", errMsg, status, sqlStmt, _database);
        sqlite3_free(errMsg);
        return false;
    }

    return true;
}

+ (int) executePreparedEx: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments{
    return [[self instance] executePreparedEx:sqlStmtPrepared arguments:arguments];
}

+ (bool) executePrepared: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments
{
    return [[self instance] executePrepared:sqlStmtPrepared arguments:arguments];
}

- (bool) executePrepared: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments{
    return [self executePreparedEx:sqlStmtPrepared arguments:arguments] >= 0;
}

- (int) executePreparedEx: (const char * const)sqlStmtPrepared arguments: (NSArray * const) arguments
{
    // Prepare the statement.
    PEXDbStatement * statement = [self prepareStatement:sqlStmtPrepared arguments:arguments];
    if (statement == nil){
        int errorCode = sqlite3_errcode(_database);
        int extendedErrorCode = sqlite3_extended_errcode(_database);
        const char * errorMessage = sqlite3_errmsg(_database);
        DDLogError(@"failed to prepare statement %s, code=%d, extended=%d, errorMessage=%s, dbPtr=%p, dbPath=%@",
                sqlStmtPrepared, errorCode, extendedErrorCode, errorMessage, _database, _databasePath);

        [self onStatementExecutionFail:errorCode];
        return -1;
    }

    // Statement execution.
    [self commonLock];
    int sresult = sqlite3_step(statement.statement);
    int changes = sqlite3_changes(_database);
    bool result = (sresult == SQLITE_DONE);
    [self commonQuit];

    if (!result){
        int errorCode = sqlite3_errcode(_database);
        int extendedErrorCode = sqlite3_extended_errcode(_database);
        const char * errorMessage = sqlite3_errmsg(_database);
        DDLogError(@"failed to execute statement %s, code=%d, extended=%d, errorMessage=%s, dbPtr=%p, dbPath=%@",
                sqlStmtPrepared, errorCode, extendedErrorCode, errorMessage, _database, _databasePath);

        [self onStatementExecutionFail:errorCode];
        return -2;
    }

    [self onStatementExecutionSuccess];
    return changes;
}

-(void) onStatementExecutionFail: (int) errorCode {
    if (errorCode == SQLITE_OK || errorCode == SQLITE_ROW || errorCode == SQLITE_DONE){
        return;
    }

    @try {
        // IPH-306, IPH-319. Sometime happened DB connection was broken.
        // Database file sanity test (existence, readability, writability).
        NSFileManager * const fileMgr = [NSFileManager defaultManager];
        const BOOL dbExists = [fileMgr fileExistsAtPath:_databasePath];
        const BOOL dbReadable = dbExists && [fileMgr isReadableFileAtPath:_databasePath];
        const BOOL dbWritable = dbExists && [fileMgr isWritableFileAtPath:_databasePath];
        const BOOL dbDirWritable = [fileMgr isWritableFileAtPath:[_databasePath stringByDeletingLastPathComponent]];
        const BOOL dbBroken = _database != nil && (!dbExists || !dbReadable || !dbWritable || !dbDirWritable);
        NSString * const dbReport = [self genDbLogReport];

        // Some specific errors.
        BOOL tryDbReload = NO;
        switch (errorCode) {
            case SQLITE_NOMEM: {
                // Memory problem, log memory level.
                _consecutiveDbErrorCount += 1;
                _totalErrors += 1;
                NSString *memReport = [PEXUtils getFreeMemoryReport:NULL resident:NULL suspend:NULL];
                tryDbReload = _database != nil && (_consecutiveDbErrorCount >= 3 || dbBroken);
                DDLogError(@"Database NO-MEMORY problem. Memory report (%@), DB report (%@), #errors: %d, doReload: %d",
                        memReport, dbReport, _consecutiveDbErrorCount, tryDbReload);
                break;
            }
            case SQLITE_CANTOPEN: {
                // Database could not be opened, log it. Also happens related to the memory error.
                _consecutiveDbErrorCount += 1;
                _totalErrors += 1;
                NSString *memReport = [PEXUtils getFreeMemoryReport:NULL resident:NULL suspend:NULL];
                NSArray const * lsofArray = [PEXUtils lsof];
                NSString const * lsofReport = [lsofArray componentsJoinedByString:@"\n"];

                // Fix permissions.
                NSUInteger checked = _databasePath != nil ? [PEXDatabase fixUpDatabaseFileProtection:_databasePath] : 0;

                tryDbReload = _database != nil && (_consecutiveDbErrorCount >= 3 || dbBroken);
                DDLogError(@"Database problem: SQLITE_CANTOPEN. Memory report (%@), DB report (%@), #errors: %d, doReload: %d"
                        "\n; checkedFiles: %lu, lsofSize: %lu, lsof: %@",
                        memReport, dbReport, _consecutiveDbErrorCount, tryDbReload,
                        (long unsigned) checked, (long unsigned)[lsofArray count], lsofReport);
                break;
            }
            case SQLITE_NOTADB:
            case SQLITE_MISUSE:
            case SQLITE_CORRUPT:
            case SQLITE_ERROR:
            case SQLITE_IOERR: {
                _consecutiveDbErrorCount += 1;
                _totalErrors += 1;
                tryDbReload = _database != nil && (_consecutiveDbErrorCount >= 3 || dbBroken);
                DDLogError(@"Database fatal problem, code: %d, #errors: %d. Db report: (%@), doReload: %d",
                        errorCode, _consecutiveDbErrorCount, dbReport, tryDbReload);
                break;
            };

            default: {
                // Not fatal errors, no DB reload here.
                DDLogError(@"DB error, not critical one code: %d. Db report: (%@)", errorCode, dbReport);
            }
        }

        // If DB should be reloaded. Do only if database was loaded and suddenly crashed somehow.
        if (_database != nil && tryDbReload) {
            _consecutiveDbErrorCount = 0;
            DDLogError(@"DB reload requested, posting notification to reload, errCnt: %d, broken: %d", _consecutiveDbErrorCount, dbBroken);
            [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_DB_RELOAD_REQUEST object:nil userInfo:@{}];
        }

    } @catch(NSException * e){
        DDLogError(@"Exception in handling DB error: %@", e);
    }
}

+ (NSUInteger) fixUpDatabaseFileProtection: (NSString *) dbPath {
    if (dbPath == nil || [PEXUtils isEmpty:dbPath]){
        return 0;
    }

    // Fix it individually.
    [PEXSecurityCenter setDefaultProtectionMode:dbPath fileClass:PEX_SECURITY_FILE_CLASS_DB pError:nil];

    // Temporary files
    // https://www.sqlite.org/tempfiles.html
    [PEXSecurityCenter setDefaultProtectionMode:[dbPath stringByAppendingString:@"-journal"] fileClass:PEX_SECURITY_FILE_CLASS_DB pError:nil];
    [PEXSecurityCenter setDefaultProtectionMode:[dbPath stringByAppendingString:@"-wal"] fileClass:PEX_SECURITY_FILE_CLASS_DB pError:nil];
    [PEXSecurityCenter setDefaultProtectionMode:[dbPath stringByAppendingString:@"-shm"] fileClass:PEX_SECURITY_FILE_CLASS_DB pError:nil];

    // Fix whole DB contents.
    NSString * dbDir = [dbPath stringByDeletingLastPathComponent];
    NSUInteger checked = [PEXSecurityCenter setDefaultProtectionModeOnAll:dbDir];
    DDLogVerbose(@"Database permission set to default, numFilesChecked: %lu, file: %@", (unsigned long)checked, dbPath);

    return checked;
}

- (NSString *)genDbLogReport: (NSString *) dbPath {
    NSFileManager * const fileMgr = [NSFileManager defaultManager];
    const BOOL dbExists = [fileMgr fileExistsAtPath:dbPath];
    const BOOL dbReadable = dbExists && [fileMgr isReadableFileAtPath:dbPath];
    const BOOL dbWritable = dbExists && [fileMgr isWritableFileAtPath:dbPath];
    const BOOL dbDirWritable = [fileMgr isWritableFileAtPath:[dbPath stringByDeletingLastPathComponent]];

    // File size + protection mode.
    NSDictionary *fileAttributes = [fileMgr attributesOfItemAtPath:dbPath error:nil];

    // Are files protected?
    const BOOL protectedAvailable = [[UIApplication sharedApplication] isProtectedDataAvailable];

    // Simple fopen test.
    BOOL openTestPass = NO;
    if (dbExists && dbReadable){
        FILE * dbf = fopen([dbPath UTF8String], "r");
        openTestPass = dbf != NULL;
        if (dbf != NULL) {
            fclose(dbf);
        }
    }

    NSDate * databaseLoadedTime = _databaseLoadedTime;
    NSString * dbReport = [NSString stringWithFormat:@"dbPtr: %p, dbPath: %@, dbExists: %d, "
                                                             "dbReadable: %d, dbWritable: %d, openTestOK: %d, "
                                                             "dbSize: %@, protection: %@, protectionAvailable: %d, "
                                                             "dbDirWritable: %d, errCnt: %d, loadedTime: %@, "
                                                             "errTotal: %d, reloads: %d, failReloads: %d",
                    _database, dbPath, dbExists, dbReadable, dbWritable, openTestPass,
                    fileAttributes[NSFileSize], fileAttributes[NSFileProtectionKey], protectedAvailable,
                    dbDirWritable, _consecutiveDbErrorCount, databaseLoadedTime,
                    _totalErrors, _totalDbReloads, _failedDbReloads];

    return dbReport;
}

- (NSString *)genDbLogReport {
    return [self genDbLogReport:_databasePath];
}

-(void) onStatementExecutionSuccess {
    _consecutiveDbErrorCount = 0;
}

+ (PEXDbCursor *)prepareCursor:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments;
{
    return [[self instance] prepareCursor:sqlStmtPrepared arguments:arguments];
}

- (PEXDbCursor *)prepareCursor:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments
{
    PEXDbStatement * const statement = [self prepareStatement:sqlStmtPrepared arguments:arguments];

    return (statement != nil) ? [[PEXDbCursor alloc] initWithStatement:statement] : nil;
}

- (PEXDbStatement *) prepareStatement:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments
{
    PEXDbStatement * result = nil;
    [self commonLock];

    if (_database) {
        result = [self prepareStatementNotAlone:sqlStmtPrepared arguments:arguments];
    } else {
        DDLogError(@"Could not prepare statement since DB is nil");
    }

    [self commonQuit];
    return result;
}

- (PEXDbStatement *) prepareStatementNotAlone:(const char *const)sqlStmtPrepared arguments: (NSArray * const) arguments
{
    sqlite3_stmt * statement = nil;

    if (sqlite3_prepare_v2(_database, sqlStmtPrepared, -1, &statement, NULL) != SQLITE_OK)
    {
        int errorCode = sqlite3_errcode(_database);
        int extendedErrorCode = sqlite3_extended_errcode(_database);
        const char * errorMessage = sqlite3_errmsg(_database);
        DDLogError(@"Failed to prepare statement %s, code=%d, extended=%d, errorMessage=%s, dbPtr=%p",
                sqlStmtPrepared, errorCode, extendedErrorCode, errorMessage, _database);
        return nil;
    }

    PEXDbStatement * const resultStatement = [[PEXDbStatement alloc] init];
    [resultStatement statement:statement];

    for (NSUInteger i = 0; i < arguments.count; ++i)
    {
        // index of prepared arguments start from 1 and NOT from 0
        int subCode = [arguments[i] addToStatement:resultStatement at:(int)(i + 1)];
        if (subCode != SQLITE_OK)
        {
            DDLogError(@"failed to add prepared argument %@, code: %d", arguments[i], subCode);
            return nil;
        }
    }

    return resultStatement;
}

/* MASTER SECTION */
// Not all master operations need to enter the critical section
// Depends on caller

+(int)unloadDatabase
{
    return [[self instance] unloadDatabase];
}

-(int)unloadDatabase
{
    int result = -1;
    // Because of more reasons for unloading (os kill, user kill, slepp, etc ...)
    [self masterEnter];

    if (_database != nil)
    {
        // TODO https://www.sqlite.org/c3ref/close.html
        // Our prepared statements are automatically deallocated by ARC thus we can
        // use sqlite_close_v2 which closes connection forcefully.
        result = sqlite3_close_v2(_database);
        if (result != SQLITE_OK){
            DDLogError(@"Database could not be closed. Status=%d, Report: %@", result, [self genDbLogReport]);

            // Trigger assertion since we are not ready for database unload fail.
            [DDLog flushLog];
            assert(result == SQLITE_OK && "Database close failed");
        }

        _database = nil;
        _consecutiveDbErrorCount = 0;
        _databaseLoadedTime = nil;
        _databasePath = nil;

    } else {
        DDLogDebug(@"Nothing to close, database is nil");
    }

    [self masterQuit];

    return result;
}

+(PEXDbOpenStatus)tryOpenDatabase: (const PEXUser * const) user
                         encryptionKey: (NSString * const) key
{
    return [[self instance] tryOpenDatabase:user encryptionKey:key];
}

- (PEXDbOpenStatus) tryOpenDatabase: (const PEXUser * const) user
          encryptionKey: (NSString * const) key {

    [self masterEnter];
    if (self.database) {
        [self masterQuit];
        DDLogError(@"Close previously opened database before opening a new one. dbPtr=%p. Path: %@", _database, _databasePath);
        return PEX_DB_OPEN_FAIL_CLOSE_PREVIOUS;
    }

    NSString * const databasePath = [PEXDatabase getDatabasePath:user];
    NSFileManager * const filemgr = [NSFileManager defaultManager];
    if (![filemgr fileExistsAtPath:databasePath]){
        [self masterQuit];
        DDLogError(@"Database file could not be found: %@", databasePath);
        return PEX_DB_OPEN_FAIL_NO_FILE;
    }

    // Set default protection mode so PhoneX has access to the database after device is locked.
    [PEXDatabase fixUpDatabaseFileProtection:databasePath];
    const int dbOpenResult = sqlite3_open_v2([databasePath UTF8String], &_database,
            SQLITE_OPEN_FULLMUTEX  // serialized mode = single connection can be used from multiple threads.
                    | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
            NULL); // IPH-331: we may need to implement SHIM VFS to set security parameters for temporary files.

    [PEXDatabase fixUpDatabaseFileProtection:databasePath];

    // Database open failed.
    if (dbOpenResult != SQLITE_OK) {
        [self masterQuit];
        const char * const msg = sqlite3_errmsg(_database);
        DDLogError(@"Unable to open database, open result=%d, error message: %s, dbPath: %@, dbReport: %@",
                dbOpenResult, msg, databasePath, [self genDbLogReport: databasePath]);

        return PEX_DB_OPEN_FAIL_OPEN_FAILED;
    }

    DDLogDebug(@"Database successfully opened, report: %@", [self genDbLogReport:databasePath]);

    // Step 2 - unlock the database.
    if (!key || ![self unlockDatabaseWithKey:key]) {
        [self masterQuit];
        DDLogError(@"Database could not be unlocked. KeyIsEmpty: %d", [PEXUtils isEmpty:key]);
        return PEX_DB_OPEN_FAIL_INVALID_KEY;

    }

    [self masterQuit];
    DDLogDebug(@"Database successfully loaded");

    [self onDbOpenedAndUnlocked:databasePath];
    return PEX_DB_OPEN_OK;
}

+(PEXDbLoadResult)openOrCreateDatabase: (const PEXUser * const) user
                         encryptionKey: (NSString * const) key
{
    return [[self instance] openOrCreateDatabase:user encryptionKey:key];
}

- (PEXDbLoadResult)openOrCreateDatabase: (const PEXUser * const) user
                  encryptionKey: (NSString * const) key
{
    [self masterEnter];
    if (self.database)
    {
        [self masterQuit];
        [NSException raise:@"First, unload currently loaded database"
                    format:@"First, unload currently loaded database"];
    }

    NSString * const databasePath = [PEXDatabase getDatabasePath:user];
    NSFileManager * const filemgr = [NSFileManager defaultManager];
    const BOOL new = ![filemgr fileExistsAtPath: databasePath];

    // TODO in future check storage size?
    PEXDbLoadResult result = PEX_DB_LOAD_FATAL_ERROR;

    // TODO https://www.sqlite.org/c3ref/open.html
    [PEXDatabase fixUpDatabaseFileProtection:databasePath];
    const int dbOpenResult = sqlite3_open_v2([databasePath UTF8String], &_database,
            SQLITE_OPEN_FULLMUTEX  // serialized mode = single connection can be used from multiple threads.
            | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
            NULL); // IPH-331: we may need to implement SHIM VFS to set security parameters for temporary files.

    // Set default protection mode so PhoneX has access to the database after device is locked.
    [PEXDatabase fixUpDatabaseFileProtection:databasePath];

    if (dbOpenResult == SQLITE_OK)
    {
        DDLogDebug(@"Database successfully opened, report: %@", [self genDbLogReport:databasePath]);

        if (!key || ![self unlockDatabaseWithKey:key])
        {
            DDLogError(@"Problem with unlocking the database. See previous logs.");
            result = PEX_DB_LOAD_KEY_PROBLEM;
        }
        else
        {
            if (new)
            {
                DDLogDebug(@"Creating new database, version=%d", USER_VERSION);
                [self setUserVersion:USER_VERSION];
            }

            DDLogDebug(@"Database successfully loaded");
            [self onDbOpenedAndUnlocked:databasePath];

            result = PEX_DB_LOAD_OK;
        }
    }
    else
    {
        const char * const msg = sqlite3_errmsg(_database);
        if (!new)
        {
            if ([self removeDatabase:user])
            {
                // remove old database ?
                // recreate (go up) ?
                // if succ recreation then PEX_DB_LOAD_RECCREATED else notify ?
                DDLogDebug(@"Recreating database");
                result = PEX_DB_LOAD_RECCREATED;
            }
            else
            {
                //log and notify about the error
                DDLogError(@"Unable to remove the old database: %d : %s", dbOpenResult, msg);
            }
        }
        else
        {
            // should not happen
            DDLogError(@"No database before and unable to create new: %d : %s", dbOpenResult, msg);
        }
    }

    [self masterQuit];
    return result;
}

- (void) onDbOpenedAndUnlocked: (NSString * const) databasePath {
    _consecutiveDbErrorCount = 0;
    _failedDbReloads = 0;
    _databaseLoadedTime = [NSDate date];
    [self createTables];
    self.databasePath = databasePath;
    [self checkAndUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_DB_OPENED object:nil userInfo:@{}];
}

- (BOOL)tryReloadDatabase:(const PEXUser *const)user encryptionKey:(NSString *const)key pStatus: (PEXDbOpenStatus *) pStatus {
    DDLogVerbose(@"DB reload request");
    NSString * newDbPath = [PEXDatabase getDatabasePath:user];

    // If failed attempts for restart is too big, assert.
    if (_failedDbReloads >= 10){
        DDLogError(@"Number of failed reload attempts is too big, %d", _failedDbReloads);
        [PEXReport logEvent:PEX_ACTION_DB_RELOAD_CRASH];
        [DDLog flushLog];
        assert(_failedDbReloads < 10 && "Could not reload DB too many times");
    }

    // At first, unload existing database.
    _totalDbReloads += 1;
    if (_database != nil) {
        NSString *existingDbPath;
        @try {
            existingDbPath = [[PEXDatabase instance] databasePath];
            if (existingDbPath == nil) {
                DDLogError(@"Existing DB path is nil");
            } else if (![existingDbPath isEqualToString:newDbPath]) {
                DDLogError(@"Existing DB path does not match new DB path. old %@ vs new %@", existingDbPath, newDbPath);
            }

            // New path could be nil? Check.
            if (newDbPath == nil) {
                DDLogError(@"New database path is nil! Cannot reload");
                return NO;
            }

            // Existence of the new path.
            NSFileManager *const fileMgr = [NSFileManager defaultManager];
            if (![fileMgr fileExistsAtPath:newDbPath]) {
                DDLogError(@"New database path does not exist, cannot reload. Path: %@", newDbPath);
                return NO;
            }

            [PEXDatabase unloadDatabase];
        } @catch (NSException *e) {
            DDLogError(@"Exception when unloading database, %@", e);
        }
    }

    // Try to load a new database.
    @try {
        // Database check - is the same as previously loaded?
        PEXDbOpenStatus openStatus = [self tryOpenDatabase:user encryptionKey:key];
        if (pStatus != NULL){
            *pStatus = openStatus;
        }

        if (openStatus == PEX_DB_OPEN_OK){
            _consecutiveDbErrorCount = 0;
            return YES;

        } else if (openStatus == PEX_DB_OPEN_FAIL_INVALID_KEY){
            DDLogError(@"Database could not be opened with new key, invalid key. Report: %@", [self genDbLogReport]);
            _failedDbReloads += 1;
            [self unloadDatabase];

        } else {
            _failedDbReloads += 1;
            [self unloadDatabase];
            DDLogError(@"Database open error: %ld.  Report: %@", (long)openStatus, [self genDbLogReport]);
        }

        // If here -> open failed.
        return NO;

    } @catch(NSException * e){
        DDLogError(@"Exception when loading a new database, %@", e);
    }

    return NO;
}

- (void) checkAndUpdate
{
    const int userVersion = [self getUserVersion];
    if (userVersion < USER_VERSION)
    {
        [PEXDbSchemeUpdates onUpgrade:self oldVersion:userVersion newVersion:USER_VERSION];
        [self setUserVersion:USER_VERSION];
    }
}

- (bool) unlockDatabaseWithKey: (NSString * const) key
{
    DDLogDebug(@"Unlocking database");

    const char * const keyUtf8 = [key UTF8String];
    if (_database == nil){
        DDLogError(@"Trying to unlock nil database");
        return false;
    }

    /*
     CONVENIENCE C FUNCTION sqlite3_key DOES THE SAME AS:
     (([self executeSimple:[[NSString stringWithFormat:@"PRAGMA key = '%@'", key] UTF8String ]])
     */
    int status = sqlite3_key(_database, keyUtf8, (int)strlen(keyUtf8));
    if (status != SQLITE_OK){
        DDLogError(@"Unable to unlock database, code=%d, dbPtr=%p, dbPath=%@", status, _database, _databasePath);
        return false;
    }

    // CHECK WHETHER THE KEY PASSED AND WE CAN READ FROM THE DATABASE
    int readStatus;
    if (![self testDatabaseRead: &readStatus]){
        DDLogError(@"unlockDatabaseWithKey: DB read test failed, read status: %d", readStatus);
        return false;
    }

    return true;
}

- (void) setUserVersion: (const int) userVersion
{
    [self executeSimple:[[NSString stringWithFormat:@"PRAGMA user_version = '%d'", userVersion] UTF8String]];
}

- (int) getUserVersion
{
    PEXDbStatement * statement = [self prepareStatement:[@"PRAGMA user_version" UTF8String] arguments:nil];
    if (statement != nil)
    {
        int result;

        do
        {
            result = sqlite3_step(statement.statement);
        }
        while (result != SQLITE_ROW);
    }

    return sqlite3_column_int(statement.statement, 0);
}

+ (bool) rekeyDatabase: (NSString * const) oldKey withKey:(NSString * const) newKey
{
    return [[self instance] rekeyDatabase:oldKey withKey:newKey];
}

// both must be open
+ (bool) copy: (sqlite3 * const) from to:(sqlite3 * const ) to
{
    bool result = false;
    DDLogDebug(@"Creating backup data structure");
    sqlite3_backup * backupStruct = sqlite3_backup_init(to, MAIN_DB, from, MAIN_DB);

    if (backupStruct)
    {
        const int backupStepResult = sqlite3_backup_step(backupStruct, -1);
        if (backupStepResult == SQLITE_OK || backupStepResult == SQLITE_DONE) {
            const int backupFinishRc = sqlite3_backup_finish(backupStruct);
            result = backupFinishRc == SQLITE_OK || backupFinishRc == SQLITE_DONE;
        } else {
            DDLogError(@"Database backup failed. status: %d", backupStepResult);
            return false;
        }
    }

    return result;
}

- (bool) rekeyDatabase: (NSString * const) oldKey withKey:(NSString * const) newKey
{
    bool result = false;

    [self masterEnter];

    _rekeyInProgress = YES;
    sqlite3 * dbCopy = NULL;
    NSString * const dbCopyPath = [NSString stringWithFormat:@"%@%@", self.databasePath, @"-copy"];

    // Delete previous possible artifacts from crashed rekeying.
    [[NSFileManager defaultManager] removeItemAtPath:dbCopyPath error:nil];

    // Open the empty database - creates a new one.
    DDLogDebug(@"Opening db copy");
    if (sqlite3_open_v2([dbCopyPath UTF8String], &dbCopy,
            SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK)
    {
        DDLogError(@"Rekey failed, could not open new database");
        _rekeyInProgress = NO;
        [self masterQuit];
        return false;
    }

    // Set default protection mode so PhoneX has access to the database after device is locked.
    [PEXDatabase fixUpDatabaseFileProtection:dbCopyPath];

    // Rekey procedure
    DDLogDebug(@"Keying db copy");
    const char * const oldKeyUtf8 = [oldKey UTF8String];
    const int keyStatus = sqlite3_key(dbCopy, oldKeyUtf8, (int)strlen(oldKeyUtf8));
    if (keyStatus == SQLITE_OK)
    {
        if ([PEXDatabase copy:_database to:dbCopy]) {
            DDLogDebug(@"Rekeying db copy");
            const char * const newKeyUtf8 = [newKey UTF8String];
            const int newKeyUtf8Length = (int) strlen(newKeyUtf8);
            const int rekeyResult = sqlite3_rekey(dbCopy, newKeyUtf8, newKeyUtf8Length);

            if (rekeyResult == SQLITE_OK) {
                // the copy is created and unlocked
                const int closeDbResult = sqlite3_close_v2(_database);
                if (closeDbResult == SQLITE_OK) {

                    _database = NULL;
                    if ([[NSFileManager defaultManager] removeItemAtPath:self.databasePath error:nil]) {
                        const int closeDbCopyResult = sqlite3_close_v2(dbCopy);
                        if (closeDbCopyResult == SQLITE_OK) {

                            dbCopy = NULL;
                            [[NSFileManager defaultManager] moveItemAtPath:dbCopyPath toPath:self.databasePath error:nil];

                            [PEXDatabase fixUpDatabaseFileProtection:self.databasePath];
                            if (sqlite3_open_v2([self.databasePath UTF8String], &_database,
                                    SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK)
                            {
                                // Set default protection mode so PhoneX has access to the database after device is locked.
                                [PEXDatabase fixUpDatabaseFileProtection:self.databasePath];

                                result = [self unlockDatabaseWithKey:newKey];
                                DDLogVerbose(@"DB rekey finished with result: %d, report: %@", result, [self genDbLogReport]);
                            }
                        } else {
                            DDLogError(@"Rekey failed, could not close copy database");
                        }
                    } else {
                        DDLogError(@"Rekey failed, could not delede current database");
                    }
                } else {
                    DDLogError(@"Rekey failed, Closing current database failed, status: %d", closeDbResult);
                }
            } else {
                DDLogError(@"Rekey failed, result: %d", rekeyResult);
            }
        } else {
            DDLogError(@"Rekey failed, database copy failed, to: %p", dbCopy);
        }
    } else {
        DDLogError(@"Could not open copy database, status: %d", keyStatus);
    }

    // close and remove copy in any ways
    if (dbCopy != NULL) {
        sqlite3_close_v2(dbCopy);
    }
    dbCopy = NULL;
    [[NSFileManager defaultManager] removeItemAtPath:dbCopyPath error:nil];

    _rekeyInProgress = NO;
    [self masterQuit];
    return result;
}

/* OTHERS / UTILS SECTION*/

+ (void) removeAllDatabases
{
    // TODO do nothing ... Documents directory now stores logs and files
    /*
    [self unloadDatabase];

    const NSFileManager * const fileMgr = [[NSFileManager alloc] init];
    NSString * const documentsPath = [PEXDatabase getDocumentsPath];
    const NSArray * const directoryContents = [fileMgr contentsOfDirectoryAtPath:documentsPath error:nil];

    for (NSString * const path in directoryContents)
    {
        [fileMgr removeItemAtPath:[documentsPath stringByAppendingPathComponent:path] error:nil];
    }*/
}

+ (bool) removeDatabase: (const PEXUser * const) user
{
    return [[self instance] removeDatabase:user];
}

- (bool) removeDatabase: (const PEXUser * const) user
{
    // TODO check for openend database or running executions
    NSString * const databasePath = [PEXDatabase getDatabasePath:user];
    return [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];
}

+ (NSString *) getDatabasePath: (const PEXUser * const) user
{
    return [PEXSecurityCenter getDatabaseFile:user.email];
}

-(void) createTable: (NSString *) createTable{
    BOOL qOk = [self executeSimple:[createTable cStringUsingEncoding:NSUTF8StringEncoding]];
    if (!qOk){
        DDLogError(@"Cannot create table, str: %@", createTable);
        [NSException raise:PEXRuntimeException format:@"Cannot create table exception"];
    }
}

- (void) createTables
{
    // TODO create tables - use dedicated database helper that will be called here
    // in order to a) update table schema in case of an update b) create table if
    // they do not exist.

    [self createTable:[PEXDbContact getCreateTable]];
    [self createTable:[PEXDbMessage getCreateTable]];
    [self createTable:[PEXDbUserCertificate getCreateTable]];
    [self createTable:[PEXDbUserProfile getCreateTable]];
    [self createTable:[PEXDbMessageQueue getCreateTable]];
    [self createTable:[PEXDbCallLog getCreateTable]];
    [self createTable:[PEXDbDhKey getCreateTable]];
    [self createTable:[PEXDbReceivedFile getCreateTable]];
    [self createTable:[PEXDbFileTransfer getCreateTable]];
    [self createTable:[PEXDbExpiredLicenceLog getCreateTable]];
    [self createTable:[PEXDbContactNotification getCreateTable]];
    [self createTable:[PEXDbAccountingPermission getCreateTable]];
    [self createTable:[PEXDbAccountingLog getCreateTable]];
}

// SINGLETON SECTION

+ (void) initInstance
{
    [PEXDatabase instance];
}

+ (PEXDatabase *) instance
{
    static PEXDatabase * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXDatabase alloc] init];
    });

    return instance;
}

- (id) init
{
    self = [super init];

    _mastersCount = _commonersCount = 0;
    _failedDbReloads = 0;
    _consecutiveDbErrorCount = 0;
    _totalErrors = 0;
    _totalDbReloads = 0;
    self.masterLock = [[NSLock alloc] init];
    self.commonLock = [[NSLock alloc] init];
    self.commonCountLock = [[NSLock alloc] init];
    self.masterCountLock = [[NSLock alloc] init];

    return self;
}

- (bool) testDatabaseRead: (int *) pStatus
{
    return ([self executeSimple:"SELECT count(*) FROM sqlite_master;" status:pStatus]);
}

// MASTER writers may set the _database to nil
// so it needs to be checked after enter
- (void) commonEnter
{
    [self.commonLock lock];
    [self.commonCountLock lock];
    ++_commonersCount;
    if (_commonersCount == 1)
        [self.masterLock lock];
    [self.commonCountLock unlock];
    [self.commonLock unlock];
}

- (void) commonQuit
{
    [self.commonCountLock lock];
    --_commonersCount;
    if (_commonersCount == 0)
        [self.masterLock unlock];
    [self.commonCountLock unlock];
}

// MASTER writers may set the _database to nil
// so it needs to be checked after enter
- (void) masterEnter
{
    [self.masterCountLock lock];
    ++_mastersCount;
    if (_mastersCount == 1)
        [self.commonLock lock];
    [self.masterCountLock unlock];

    [self.masterLock lock];
}

- (void) masterQuit
{
    [self.masterLock unlock];

    [self.masterCountLock lock];
    --_mastersCount;
    if (_mastersCount == 0)
        [self.commonLock unlock];
    [self.masterCountLock unlock];
}

+ (NSString *)sqlEscapeString:(NSString *)input {
    char const * inpCstring = [input cStringUsingEncoding:NSUTF8StringEncoding];
    char * buff = sqlite3_mprintf("%Q", inpCstring);
    if (buff == NULL){
        DDLogError(@"Cannot SQL escape string [%@]", input);
        return @"";
    }

    NSString * ret = [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];

    // Buff has to be released
    sqlite3_free(buff);
    return ret;
}

@end