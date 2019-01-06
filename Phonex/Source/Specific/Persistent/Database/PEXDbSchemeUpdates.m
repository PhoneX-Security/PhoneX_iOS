//
// Created by Dusan Klinec on 25.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbSchemeUpdates.h"
#import "PEXDatabase.h"
#import "PEXDBMessage.h"
#import "PEXUtils.h"
#import "PEXDbMessageQueue.h"
#import "PEXDbContact.h"
#import "PEXDbReceivedFile.h"
#import "PEXDbFileTransfer.h"
#import "PEXDBUserProfile.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbContactNotification.h"
#import "PEXDbCallLog.h"


@implementation PEXDbSchemeUpdates {

}

+ (void)onUpgrade:(PEXDatabase *)db oldVersion:(int)oldVersion newVersion:(int)newVersion {
    if (oldVersion == newVersion){
        return;
    }

    if (oldVersion > newVersion){
        DDLogError(@"New version [%d] is smaller than old version [%d]", newVersion, oldVersion);
        return;
    }

    DDLogInfo(@"Upgrading database of: %d -> %d;", oldVersion, newVersion);

    if (oldVersion < 12){
        @try {
            [self dropTable:db table:PEX_DBRF_TABLE_NAME];
        } @catch (NSException *e) {
            DDLogError(@"Upgrade of ReceivedFile failed... maybe a crappy form..., exception=%@", e);
        }

        @try {
            [self dropTable:db table:PEX_DBFT_TABLE_NAME];
        } @catch (NSException *e) {
            DDLogError(@"Upgrade of FileTransfer failed... maybe a crappy form..., exception=%@", e);
        }
    }

    if (oldVersion < 20){
        @try {
            [self addColumn:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME field:PEX_DBUSR_FIELD_LICENSE_TYPE type:@"TEXT"];
            [self addColumn:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME field:PEX_DBUSR_FIELD_LICENSE_ISSUED_ON type:@"INTEGER DEFAULT 0"];
            [self addColumn:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME field:PEX_DBUSR_FIELD_LICENSE_EXPIRES_ON type:@"INTEGER DEFAULT 0"];
            [self addColumn:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME field:PEX_DBUSR_FIELD_LICENSE_EXPIRED type:@"INTEGER DEFAULT 0"];
        } @catch (NSException *e) {
            DDLogError(@"Upgrade of Accounts failed... maybe a crappy form..., exception=%@", e);
        }
    }

    if (oldVersion < 22){
        @try {
            [self exec:db statement:[NSString stringWithFormat:@"DELETE FROM %@", PEX_UCRT_TABLE]];
            [self exec:db statement:@"VACUUM"];
            [self exec:db statement:[NSString stringWithFormat:@"CREATE UNIQUE INDEX IF NOT EXISTS usridx ON %@ (%@)", PEX_UCRT_TABLE, PEX_UCRT_FIELD_OWNER]];
        } @catch(NSException * e){
            DDLogError(@"Could not add unique constrain to the database, %@", e);
        }
    }

    if (oldVersion < 23){
        @try {
            [self addColumn:db table:PEX_MSGQ_TABLE_NAME field:PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER type:@"INTEGER DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add send attempt counter column, %@", e);
        }
    }

    if (oldVersion < 24){
        @try {
            [self addColumn:db table:PEX_DBCONTACTNOTIFICATION_TABLE field:PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID type:@"INTEGER DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add server id column, %@", e);
        }
    }

    // Message queue column types changed. Since SQLite does not support alter table to modify column, it is a bit more complicated.
    if (oldVersion < 32){
        @try {
            [self addColumn:db table:PEX_MSGQ_TABLE_NAME field:PEX_MSGQ_FIELD_LAST_SEND_CALL type:@"NUMERIC DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add last send call column, %@", e);
        }

        // Message queue.
        [self tryColumnsTypeChanged:db table:PEX_MSGQ_TABLE_NAME createTable:[PEXDbMessageQueue getCreateTable]];

        // Message table.
        [self tryColumnsTypeChanged:db table:PEXDBMessage_TABLE_NAME createTable:[PEXDbMessage getCreateTable]];

        // Call log table.
        [self tryColumnsTypeChanged:db table:PEX_DBCLOG_TABLE createTable:[PEXDbCallLog getCreateTable]];

        // Db notif
        [self tryColumnsTypeChanged:db table:PEX_DBCONTACTNOTIFICATION_TABLE createTable:[PEXDbContactNotification getCreateTable]];

        // User cert
        [self tryColumnsTypeChanged:db table:PEX_UCRT_TABLE createTable:[PEXDbUserCertificate getCreateTable]];

        // Db user profile
        [self tryColumnsTypeChanged:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME createTable:[PEXDbUserProfile getCreateTable]];
    }

    if (oldVersion < 33){
        @try {
            [self addColumn:db table:PEX_DBCLOG_TABLE field:PEX_DBCLOG_FIELD_EVENT_TIMESTAMP type:@"NUMERIC DEFAULT 0"];
            [self addColumn:db table:PEX_DBCLOG_TABLE field:PEX_DBCLOG_FIELD_EVENT_NONCE type:@"INTEGER DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add event identification fields to call log, %@", e);
        }
    }

    if (oldVersion < 36){
        @try {
            [self addColumn:db table:PEX_MSGQ_TABLE_NAME field:PEX_MSGQ_FIELD_IS_OFFLINE type:@"INTEGER DEFAULT 0"];
            [self addColumn:db table:PEXDBMessage_TABLE_NAME field:PEXDBMessage_FIELD_IS_OFFLINE type:@"INTEGER DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add offline fields to message queue, %@", e);
        }
    }

    if (oldVersion < 37){
        @try {
            [self addColumn:db table:PEX_MSGQ_TABLE_NAME field:PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE type:@"INTEGER DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add message subtype fields to message queue, %@", e);
        }
    }

    if (oldVersion < 38){
        @try {
            [self addColumn:db table:PEX_DBCLOG_TABLE field:PEX_DBCLOG_FIELD_SIP_CALL_ID type:@"TEXT"];
        } @catch(NSException * e){
            DDLogError(@"Could not add sip call id field to call log, %@", e);
        }
    }

    if (oldVersion < 40){
        @try {
            [self addColumn:db table:DBCL(TABLE) field:DBCL(FIELD_LAST_ACTIVE) type:@"NUMERIC DEFAULT 0"];
            [self addColumn:db table:DBCL(TABLE) field:DBCL(FIELD_LAST_TYPING) type:@"NUMERIC DEFAULT 0"];
        } @catch(NSException * e){
            DDLogError(@"Could not add last active, last typing fields to contact database, %@", e);
        }
    }

    if (oldVersion < 41){
        @try {
            [self addColumn:db table:PEX_DBUSR_ACCOUNTS_TABLE_NAME field:PEX_DBUSR_FIELD_RECOVERY_EMAIL type:@"TEXT"];
        } @catch(NSException * e){
            DDLogError(@"Could not add recovery email field to profile database, %@", e);
        }
    }

    if (oldVersion < 42){
        @try {
            // Convert all invalid sendDates in message DB.
            // Shifted by 3 magnitudes, stored as milliseconds, should be stored as seconds.
            [self exec:db statement:[NSString stringWithFormat:@"UPDATE %@ SET `%@`=(`%@` / 1000.0) WHERE `%@` > %.4f",
                            PEXDBMessage_TABLE_NAME,
                            PEXDBMessage_FIELD_SEND_DATE,
                            PEXDBMessage_FIELD_SEND_DATE,
                            PEXDBMessage_FIELD_SEND_DATE,
                            ([[NSDate date] timeIntervalSince1970] * 10.0)

            ]];
        } @catch(NSException * e){
            DDLogError(@"Could not add recovery email field to profile database, %@", e);
        }
    }

    if (oldVersion < 43){
        @try {
            [self addColumn:db table:PEX_DBRF_TABLE_NAME field:PEX_DBRF_FIELD_FILE_META_HASH type:@"TEXT"];
        } @catch(NSException * e){
            DDLogError(@"Could not add file meta hash to received files, %@", e);
        }
    }
}

+(BOOL) exec:(PEXDatabase *)db statement: (NSString *) statement {
    return [db executeSimple:[statement cStringUsingEncoding:NSUTF8StringEncoding]];
}

+(void) addColumn:(PEXDatabase *)db table: (NSString *) table field: (NSString *) field type: (NSString *) type {
    NSString * statement = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@", table, field, type];
    DDLogVerbose(@"Add column statement: %@", statement);

    BOOL result = [db executeSimple:[statement cStringUsingEncoding:NSUTF8StringEncoding]];
    if (!result){
        [NSException raise:@"DBException" format:@"Statement execution ended with error. [%@]", statement];
    }
}

/**
 * Convenience method to wrap colun change method with try-catch and nil conversion block (implicit conversion).
 */
+(BOOL) tryColumnsTypeChanged:(PEXDatabase *)db table: (NSString *) table createTable: (NSString *) createTable {
    @try {
        return [self columnsTypeChanged:db table:table createTable:createTable conversionBlock:nil];
    } @catch(NSException * e){
        DDLogError(@"Could not convert table %@, %@", table, e);
    }

    return NO;
}

/**
 * Since column type changes are not supported in SQLite, the whole procedure is complicated.
 * One has to:
 * 1. rename old table to TMP.
 * 2. create a new table with standard create table.
 * 3. insert all data from TMP to newly created table. Auto conversion will be applied here if conversion block is nil.
 *    If you want to convert fields manually, different logic is required.
 * 4. old table is dropped.
 */
+(BOOL) columnsTypeChanged:(PEXDatabase *)db table: (NSString *) table createTable: (NSString *) createTable
           conversionBlock: (PEXTableConversionBlock) conversionBlock
{
    NSString * tableOld = [NSString stringWithFormat:@"%@_old_%d", table,
                    ((int)([[NSDate date] timeIntervalSince1970]*1000.0) * arc4random_uniform(8192)) % 8192];
    DDLogDebug(@"Going to transform table %@, temporary table: %@", table, tableOld);

    // 0. drop old table if exists.
    [self dropTable:db table:tableOld];

    // 1. rename.
    if (![self renameTable:db table:table newName:tableOld]){
        // Graceful fail, without exception. No data loss.
        [NSException raise:@"DBException" format:@"Could not rename table [%@] to [%@]", table, tableOld];
    }

    // 2. Create new one.
    if (![self exec:db statement:createTable]){
        // Could not create a new table.
        DDLogError(@"Create table error for table: %@", table);
        // Try to rename back so we at least save the data.
        BOOL renameSuccess = [self renameTable:db table:tableOld newName:table];
        [NSException raise:@"DBException" format:@"Could not create table [%@], rename success: %d", table, renameSuccess];
    }

    // 3. Conversion.
    BOOL conversionSuccess;
    if (conversionBlock != nil){
        conversionSuccess = conversionBlock(tableOld, table) >= 0;
    } else {
        NSString * insertCmd = [NSString stringWithFormat:@"INSERT INTO %@ SELECT * FROM %@", table, tableOld];
        conversionSuccess = [db executeSimple:[insertCmd cStringUsingEncoding:NSUTF8StringEncoding]];
    }

    if (!conversionSuccess){
        DDLogError(@"Data conversion failed for table %@", table);
        // Try to rename back.
        [self renameTable:db table:tableOld newName:table];
        [NSException raise:@"DBException" format:@"Table data migration failed for table [%@]", table];
    }

    // 4. Drop the old one.
    if (![self dropTable:db table:tableOld]){
        DDLogError(@"Old table could not be dropped: %@", tableOld);
        // Not very cool, but we can manage one old table.
    }

    return YES;
}

+(BOOL) renameTable:(PEXDatabase *)db table: (NSString *) table newName:(NSString *) newName {
    NSString * renameCmd = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", table, newName];
    DDLogVerbose(@"SQL rename: %@", renameCmd);

    return [db executeSimple:[renameCmd cStringUsingEncoding:NSUTF8StringEncoding]];
}

+(BOOL) dropTable:(PEXDatabase *)db table: (NSString *) table{
    NSString * dropCmd = [NSString stringWithFormat:@"DROP TABLE %@", table];
    DDLogVerbose(@"SQL drop: %@", dropCmd);

    return [db executeSimple:[dropCmd cStringUsingEncoding:NSUTF8StringEncoding]];
}

+(NSArray *) getTableColumns: (PEXDatabase *) db tableName: (NSString *) tableName {
    NSMutableArray * columns = [[NSMutableArray alloc] init];
    NSString * cmd = @"pragma table_info(?);";
    PEXDbCursor * cur = [db prepareCursor:[cmd cStringUsingEncoding:NSUTF8StringEncoding] arguments:@[tableName]];

    if (cur == nil){
        DDLogError(@"Retrieving table columns for table [%@] returned null cursor, table probably doesn't exist", tableName);
        return nil;
    }

    while ([cur moveToNext]) {
        [columns addObject:[cur getString:[cur getColumnIndex:@"name"]]];
    }

    [PEXUtils closeSilentlyCursor:cur];
    return columns;
}

/**
* Drop column table softly, preserving data (by recreating table and copying data)
* Can be also used for adding columns and preserving data
* @param db
* @param createTableCmd
* @param tableName
* @param colsToRemove
* @throws java.sql.SQLException
*/
+(void) dropColumn:(PEXDatabase *)db tableName: (NSString *) tableName createTable: (NSString *) createTable colsToRemove: (NSArray *)colsToRemove{
    NSMutableArray * updatedTableColumns = [[self getTableColumns:db tableName:tableName] mutableCopy];
    if (updatedTableColumns == nil){
        [NSException raise:@"DBException" format:@"Cannot drop column, current column list is nil"];
    }

    // Remove the columns we don't want anymore from the table's list of columns
    for(NSString * col2remove in colsToRemove){
        [updatedTableColumns removeObject:col2remove];
    }

    NSString * columnsSeparated = [updatedTableColumns componentsJoinedByString:@","];
    NSString * oldTable = [NSString stringWithFormat:@"%@_old", tableName];
    [self renameTable:db table:tableName newName:oldTable];

    // Creating the table on its new format (no redundant columns)
    [db executeSimple:[createTable cStringUsingEncoding:NSUTF8StringEncoding]];

    // Populating the table with the data
    NSString * insertCmd = [NSString stringWithFormat:@"INSERT INTO %@(%@) SELECT %@ FROM %@_old",
            tableName, columnsSeparated, columnsSeparated, tableName];
    [db executeSimple:[insertCmd cStringUsingEncoding:NSUTF8StringEncoding]];

    [self dropTable:db table:oldTable];
}

@end