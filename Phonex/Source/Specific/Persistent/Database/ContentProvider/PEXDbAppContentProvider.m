//
// Created by Matej Oravec on 21/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <sqlite3.h>
#import "PEXDbAppContentProvider.h"
#import "PEXDbContentProvider_Protected.h"
#import "PEXDbContentProvider_Protected.h"
#import "PEXDatabase.h"
#import "PEXUser.h"
#import "PEXDbStatement.h"
#import "PEXURIMatcher.h"
#import "PEXDbTextArgument.h"
#import "PEXDbContentValues.h"
#import "PEXDbCursor.h"
#import "PEXDbNumberArgument.h"
#import "PEXDbDataArgument.h"
#import "PEXDbUri.h"
#import "PEXURIMatcher.h"
#import "PEXDbMessage.h"
#import "PEXDbUserProfile.h"
#import "PEXDbContact.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbMessageQueue.h"
#import "PEXDbCallLog.h"
#import "PEXDbDhKey.h"
#import "PEXDbReceivedFile.h"
#import "PEXDbFileTransfer.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXDbContactNotification.h"
#import "PEXDbAccountingLog.h"
#import "PEXDbAccountingPermission.h"

// URI identifiers
// Base identifiers are odd, ID identifiers are even.
#define PEX_URIID_ACCOUNTS 1
#define PEX_URIID_ACCOUNTS_ID 2
#define PEX_URIID_ACCOUNTS_STATUS 3
#define PEX_URIID_ACCOUNTS_STATUS_ID 4
#define PEX_URIID_CALLLOGS 5
#define PEX_URIID_CALLLOGS_ID 6
#define PEX_URIID_FILTERS 7
#define PEX_URIID_FILTERS_ID 8
#define PEX_URIID_MESSAGES 9
#define PEX_URIID_MESSAGES_ID 10
#define PEX_URIID_THREADS 11
#define PEX_URIID_THREADS_ID 12
#define PEX_URIID_THREADS_ID_ID 14             //specify both sender and receiver
#define PEX_URIID_CLIST 51
#define PEX_URIID_CLIST_ID 52
#define PEX_URIID_CERT 53
#define PEX_URIID_CERT_ID 54
#define PEX_URIID_CLIST_STATE 55
#define PEX_URIID_CLIST_STATE_ID 56
#define PEX_URIID_SIGNATURE_WARNING 61
#define PEX_URIID_SIGNATURE_WARNING_ID 62
#define PEX_URIID_KV_STORAGE 71
#define PEX_URIID_KV_STORAGE_ID 72
#define PEX_URIID_CALL_SIMULATION 81
#define PEX_URIID_CALL_SIMULATION_ID 82
#define PEX_URIID_DH_OFFLINE 91               // pre-generated DiffieHellman keys
#define PEX_URIID_DH_OFFLINE_ID 92            // pre-generated DiffieHellman keys
#define PEX_URIID_RECEIVED_FILES 101
#define PEX_URIID_RECEIVED_FILES_ID 102
#define PEX_URIID_FILE_TRANSFER 103
#define PEX_URIID_FILE_TRANSFER_ID 104
#define PEX_URIID_QUEUED_MESSAGE 111
#define PEX_URIID_QUEUED_MESSAGE_ID 112
#define PEX_URIID_EXPIRED_INFO 113
#define PEX_URIID_EXPIRED_INFO_ID 114
#define PEX_URIID_CONTACT_NOTIFICATION 115
#define PEX_URIID_CONTACT_NOTIFICATION_ID 116
#define PEX_URIID_QUEUED_MESSAGE_NEWEST_PER_RECIPIENT 121
#define PEX_URIID_QUEUED_MESSAGE_OLDEST_PER_RECIPIENT 122
#define PEX_URIID_ACCOUNTING_LOG 130
#define PEX_URIID_ACCOUNTING_LOG_ID 131
#define PEX_URIID_ACCOUNTING_PERMISSION 140
#define PEX_URIID_ACCOUNTING_PERMISSION_ID 141

@interface PEXDbAppContentProvider ()

@end

@implementation PEXDbAppContentProvider {

}

// Resolves URI to our identifier.
-(int) getURIId: (const PEXDbUri * const) uri{
    // Static URI matching initialization.
    static PEXURIMatcher * uriMatcher = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        uriMatcher = [[PEXURIMatcher alloc] init];

        // Add our DB models and supported URIs here.
        // Has to be done manually. This design is OK for now.
        // Later, if necessary, this can be refactored to register/unregister design.
        //
        // Messages
        [uriMatcher addURI:[PEXDbMessage getURI]     idx:PEX_URIID_MESSAGES];
        [uriMatcher addURI:[PEXDbMessage getURIBase] idx:PEX_URIID_MESSAGES_ID];
        // User profile
        [uriMatcher addURI:[PEXDbUserProfile getURI]     idx:PEX_URIID_ACCOUNTS];
        [uriMatcher addURI:[PEXDbUserProfile getURIBase] idx:PEX_URIID_ACCOUNTS_ID];
        // User mockContacts
        [uriMatcher addURI:[PEXDbContact getURI]     idx:PEX_URIID_CLIST];
        [uriMatcher addURI:[PEXDbContact getURIBase] idx:PEX_URIID_CLIST_ID];
        // User certificates
        [uriMatcher addURI:[PEXDbUserCertificate getURI]     idx:PEX_URIID_CERT];
        [uriMatcher addURI:[PEXDbUserCertificate getURIBase] idx:PEX_URIID_CERT_ID];
        // Queue messages
        [uriMatcher addURI:[PEXDbMessageQueue getURI]     idx:PEX_URIID_QUEUED_MESSAGE];
        [uriMatcher addURI:[PEXDbMessageQueue getURIBase] idx:PEX_URIID_QUEUED_MESSAGE_ID];
        // Call logs
        [uriMatcher addURI:[PEXDbCallLog getURI] idx:PEX_URIID_CALLLOGS];
        [uriMatcher addURI:[PEXDbCallLog getURIBase] idx:PEX_URIID_CALLLOGS_ID];
        // For messaging
        [uriMatcher addURI:[PEXDbMessageQueue getNewestPerRecipientURI] idx:PEX_URIID_QUEUED_MESSAGE_NEWEST_PER_RECIPIENT];
        [uriMatcher addURI:[PEXDbMessageQueue getOldestPerRecipientURI] idx:PEX_URIID_QUEUED_MESSAGE_OLDEST_PER_RECIPIENT];
        // For DH keys
        [uriMatcher addURI:[PEXDbDhKey getURI] idx:PEX_URIID_DH_OFFLINE];
        [uriMatcher addURI:[PEXDbDhKey getURIBase] idx:PEX_URIID_DH_OFFLINE_ID];
        // Received files.
        [uriMatcher addURI:[PEXDbReceivedFile getURI] idx:PEX_URIID_RECEIVED_FILES];
        [uriMatcher addURI:[PEXDbReceivedFile getURIBase] idx:PEX_URIID_RECEIVED_FILES_ID];
        // File transfer
        [uriMatcher addURI:[PEXDbFileTransfer getURI] idx:PEX_URIID_FILE_TRANSFER];
        [uriMatcher addURI:[PEXDbFileTransfer getURIBase] idx:PEX_URIID_FILE_TRANSFER_ID];

        [uriMatcher addURI:[PEXDbExpiredLicenceLog getURI] idx:PEX_URIID_EXPIRED_INFO];
        [uriMatcher addURI:[PEXDbExpiredLicenceLog getURIBase] idx:PEX_URIID_EXPIRED_INFO_ID];

        [uriMatcher addURI:[PEXDbContactNotification getURI] idx:PEX_URIID_CONTACT_NOTIFICATION];
        [uriMatcher addURI:[PEXDbContactNotification getURIBase] idx:PEX_URIID_CONTACT_NOTIFICATION_ID];

        [uriMatcher addURI:[PEXDbAccountingLog getURI] idx:PEX_URIID_ACCOUNTING_LOG];
        [uriMatcher addURI:[PEXDbAccountingLog getURIBase] idx:PEX_URIID_ACCOUNTING_LOG_ID];

        [uriMatcher addURI:[PEXDbAccountingPermission getURI] idx:PEX_URIID_ACCOUNTING_PERMISSION];
        [uriMatcher addURI:[PEXDbAccountingPermission getURIBase] idx:PEX_URIID_ACCOUNTING_PERMISSION_ID];
    });

    // Call matcher on given URI.
    return [uriMatcher match:uri];
}

// Returns default table name for the registered URI based on its ID.
-(NSString *) getTableFromID: (int) uriID {
    switch(uriID){
        case PEX_URIID_MESSAGES:
        case PEX_URIID_MESSAGES_ID:
            return PEXDBMessage_TABLE_NAME;
        case PEX_URIID_ACCOUNTS:
        case PEX_URIID_ACCOUNTS_ID:
            return PEX_DBUSR_ACCOUNTS_TABLE_NAME;
        case PEX_URIID_CLIST:
        case PEX_URIID_CLIST_ID:
            return PEX_DBCL_TABLE;
        case PEX_URIID_CERT:
        case PEX_URIID_CERT_ID:
            return PEX_UCRT_TABLE;
        case PEX_URIID_QUEUED_MESSAGE:
        case PEX_URIID_QUEUED_MESSAGE_ID:
            return PEX_MSGQ_TABLE_NAME;
        case PEX_URIID_CALLLOGS:
        case PEX_URIID_CALLLOGS_ID:
            return PEX_DBCLOG_TABLE;
        case PEX_URIID_QUEUED_MESSAGE_NEWEST_PER_RECIPIENT:
        case PEX_URIID_QUEUED_MESSAGE_OLDEST_PER_RECIPIENT:
            return PEX_MSGQ_TABLE_NAME;
        case PEX_URIID_DH_OFFLINE:
        case PEX_URIID_DH_OFFLINE_ID:
            return PEX_DBDH_TABLE;
        case PEX_URIID_RECEIVED_FILES:
        case PEX_URIID_RECEIVED_FILES_ID:
            return PEX_DBRF_TABLE_NAME;
        case PEX_URIID_FILE_TRANSFER:
        case PEX_URIID_FILE_TRANSFER_ID:
            return PEX_DBFT_TABLE_NAME;
        case PEX_URIID_EXPIRED_INFO:
        case PEX_URIID_EXPIRED_INFO_ID:
            return PEX_DBEXPIRED_TABLE;
        case PEX_URIID_CONTACT_NOTIFICATION:
        case PEX_URIID_CONTACT_NOTIFICATION_ID:
            return PEX_DBCONTACTNOTIFICATION_TABLE;
        case PEX_URIID_ACCOUNTING_LOG:
        case PEX_URIID_ACCOUNTING_LOG_ID:
            return PEX_DBAL_TABLE_NAME;
        case PEX_URIID_ACCOUNTING_PERMISSION:
        case PEX_URIID_ACCOUNTING_PERMISSION_ID:
            return PEX_DBAP_TABLE_NAME;
        default:
            return nil;
    }
}

/**
* Override in order to handle virtual table views.
*/
- (PEXDbCursor *)query:(const PEXDbUri *const)uri projection:(const NSArray *const)projection selection:(NSString *const)selection selectionArgs:(const NSArray *const)selectionArgs sortOrder:(NSString *const)sortOrder {
    int uriID = [self getURIId:uri];
    if (uriID == PEXURIMatcher_URI_NOT_FOUND){
        [NSException raise:@"IllegalArgumentException" format:@"URI not found"];
    }

    if (uriID == PEX_URIID_QUEUED_MESSAGE_NEWEST_PER_RECIPIENT || uriID == PEX_URIID_QUEUED_MESSAGE_OLDEST_PER_RECIPIENT){
        // Special uri: Greatest-per-group problem
        // Solution explained: http://stackoverflow.com/questions/979034/mysql-shows-incorrect-rows-when-using-group-by/979079#979079

        // required columns for joining and ordering
        NSMutableArray * columns = [projection mutableCopy];
        if (![columns containsObject:PEX_MSGQ_FIELD_TO]){
            [columns addObject:PEX_MSGQ_FIELD_TO];
        }
        if (![columns containsObject:PEX_MSGQ_FIELD_TIME]) {
            [columns addObject:PEX_MSGQ_FIELD_TIME];
        }

        NSString * timeComparator = uriID == PEX_URIID_QUEUED_MESSAGE_NEWEST_PER_RECIPIENT ? @"<" : @">";
        NSString * tableName = [self getTableFromID:uriID];
        NSString * groupCol = PEX_MSGQ_FIELD_TO;
        NSString * orderCol = PEX_MSGQ_FIELD_TIME;
        NSString * finalProjection = [columns componentsJoinedByString:@","];
        NSString * innerSelect = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@", finalProjection, tableName, selection];
        NSString * query = [NSString stringWithFormat:
                @"SELECT t1.* FROM (%@) AS t1 LEFT OUTER JOIN (%@) AS t2 ON"
                "(t1.%@ = t2.%@ AND t1.%@ %@ t2.%@) WHERE t2.%@ IS NULL",
                    innerSelect, innerSelect,
                    groupCol, groupCol, orderCol, timeComparator, orderCol, groupCol];

        // Duplicate selection arguments since it occurs twice in the query.
        NSMutableArray * finalArgs = [NSMutableArray arrayWithArray:selectionArgs];
        [finalArgs addObjectsFromArray:selectionArgs];

        return [self queryRaw:query selectionArgs:finalArgs];
    } else {
        // Default case.
        return [super query:uri projection:projection selection:selection selectionArgs:selectionArgs sortOrder:sortOrder];
    }
}

// SINGLETON

+ (void) initInstance
{
    [PEXDbAppContentProvider instance];
}

+ (PEXDbAppContentProvider *) instance
{
    static PEXDbAppContentProvider * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXDbAppContentProvider alloc] init];
    });

    return instance;
}

@end