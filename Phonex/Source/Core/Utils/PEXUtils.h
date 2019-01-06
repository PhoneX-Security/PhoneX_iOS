//
// Created by Dusan Klinec on 25.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbCursor;


@interface PEXUtils : NSObject
+(BOOL) isEmpty: (NSString *) string;
+(BOOL) isEmptyArr: (NSArray *) arr;
+(BOOL) isEmptyData: (NSData *) dat;
+(NSString *) getStringMaxLen: (NSString *) input length:(int) length;

+(BOOL) areNSNumbersEqual: (NSNumber *) a b:(NSNumber *) b;
+(BOOL) areNSStringsEqual: (NSString *) a b:(NSString *) b;
+(BOOL) doErrorMatch: (NSError *) err domain: (NSString *) domain;
+(BOOL) doErrorMatch: (NSError *) err domain: (NSString *) domain code: (NSInteger) code;
+ (NSError *)getErrorFromArray: (NSArray *) errorsArray domain: (NSString *)domain;
+ (NSError *)getErrorFromArray:(NSArray *) errorsArray domain:(NSString *) domain code:(NSInteger)code;
+ (BOOL) isErrorWithConnectivity: (NSError *) err;

+(void) setError: (NSError **) err domain: (NSString *) domain;
+(void) setError: (NSError **) err domain: (NSString *) domain code: (NSInteger) code;
+(void) setError: (NSError **) err domain: (NSString *) domain code: (NSInteger) code subCode: (NSInteger) subCode;

+(NSData *) compressGzip: (NSData *) input;
+(NSData *) decompressGzip: (NSData *) input;
+(NSData *) getDataFromStream: (NSOutputStream *) os;

+(uint64_t) currentTimeMillis;
+(uint64_t) millisFromDate: (NSDate *) date;
+(NSDate *) dateFromMillis: (uint64_t) milli;

+(NSString *) generateDbPlaceholders: (int) count;
+(void) closeSilentlyCursor: (PEXDbCursor *) c;
+(void) closeSilentlyCursor: (PEXDbCursor *) c logException: (BOOL) logException logTag: (NSString *) logTag;
+ (void)closeSilently:(NSStream *)c;
+ (void)closeSilently:(NSStream *)c logException:(BOOL)logException logTag:(NSString *)logTag;

+ (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block;
+ (void)executeOnQueue: (dispatch_queue_t) queue async: (BOOL) async block: (dispatch_block_t)block;

+(BOOL) areSameDay: (NSDate *) dateA b: (NSDate *) dateB;
+(BOOL) isToday: (NSDate *) date;
+(NSString *) dateDiffFromNowFormatted: (NSDate *) date compact: (BOOL) compact;
+(NSString *) timeIntervalFormatted: (NSTimeInterval) interval compact: (BOOL) compact;

/**
* Compares two dates, if null, it is considered as 0, thus 1.1.1970.
*/
+(int) compareDate: (NSDate *) a b: (NSDate *) b;
+(BOOL) isDate: (NSDate *) a olderThan: (NSTimeInterval) b;

+(BOOL) isEnterprise;
+(BOOL) isDebug;
+(BOOL) isRadioConnectivityFast:(NSString*)radioAccessTechnology;

/**
* Converts byte array to hex coded string.
* @param NSData
* @return
*/
+(NSString *) bytesToHex: (NSData *) bytes;

/**
* Converts byte array to hexa string.
* @param bytes
* @param maxLen
* @return
*/
+(NSString *) bytesToHex: (NSData *) bytes maxLen: (NSUInteger) maxLen;

+(uint64_t) fileSize: (NSString *) path error: (NSError **) err;
+(BOOL) fileExistsAndIsAfile: (NSString *) filePath;
+(BOOL) fileExistsAndIsAfile:(NSString *)filePath fmgr: (NSFileManager *) fmgr;
+(BOOL) directoryExists: (NSString *)dirPath;
+(BOOL) directoryExists: (NSString *)dirPath fmgr: (NSFileManager *) fmgr;

/**
* Ensures this path is considered as a directory. If slash is not the last character, one is appended.
* This is needed for conventions for NSFileManager. Paths without last slash are considered as paths to a file.
*/
+ (NSString *) ensureDirectoryPath: (NSString *) dirPath;
+ (NSString *) getFileBaseName: (NSString *) fileName;

/**
* Dedicated for comparing NSData structures. Returns NO also in case both are nil.
* This is used for comparing cryptographic data.
*/
+(BOOL) isDataSameAndNonNil: (NSData *) a b: (NSData *) b;

/**
* Attempts to create an unique file in a given directory.
* Randomly generated string is placed between prefix and suffix. Directory has to be writtable.
* There are several tries to find non-existing file and to create it.
*/
+(NSString *) createTemporaryFile: (NSString *) prefix suffix: (NSString *) suffix dir: (NSString *) dir;
+(NSString *) createTemporaryFileFrom: (NSString *) file dir: (NSString *) dir;
+(NSString *) createTemporaryFileFrom: (NSString *) file dir: (NSString *) dir
                        withExtension: (NSString *) extension;

+ (BOOL) removeFile: (NSString *) file;

+ (NSString *) guessMIMETypeFromExtension: (NSString *) extension;

/**
 * Returns usable locale object used by the application right now.
 */
+ (NSLocale *) getCurrentLocale;

/**
* Returns list of preferred languages of the client. Takes system & application language into consideration.
* If application language is set to auto, only system is considered.
* If application language is different, it is the first in the list.
*/
+ (NSArray *) getPreferredLanguages;

/**
* Returns current time zone in the format GMT+0100.
*/
+ (NSString *)getCurrentTimeZone;

/**
* Returns application version as an dictionary, prepared for JSON serialization.
* Stores current OS version, locale, timezone.
*/
+ (NSDictionary *)getAppVersion;

/**
* Returns application universal code sent during auth check task.
*/
+ (NSString *) getUniversalApplicationCode;

/**
* Serializes NSDictionary to JSON string.
*/
+ (NSString *) serializeToJSON: (NSDictionary *) dict error: (NSError **) pError;

/**
 * Adds given key to the dictionary if value is not nil.
 */
+ (void) addIfNonNil: (NSMutableDictionary *) dict key:(id<NSCopying>) key value:(id) value;
+ (void) addIfNonNil:(NSMutableDictionary *)dict key:(id <NSCopying>)key date:(NSDate *)date;

/**
* Dropf first n character from the input stream.
*/
+(int) dropFirstN: (NSInputStream *) is n: (NSUInteger) n c: (cancel_block) cancelBlock;

/**
 * Reads object, returns as number.
 */
+(NSNumber *) getAsNumber: (id) obj;

/**
 * If object is a string, it is returned, otherwise nil is returned.
 */
+(NSString *) getAsString: (id) obj;

/**
* Fetches free memory report on the device.
* Returns formatted string with memory usage report: @"Memory used: %u free: %u total: %u."
* Parameters are optional, if NULL, are ignored. If not, given value is written to the address contained in the parameter.
*/
+(NSString *)getFreeMemoryReport:(NSInteger *)memFree resident:(NSInteger *)memUsed suspend: (NSInteger *) memTotal;
+(NSString *) getSystemFreeMemoryReport: (NSInteger *) memFree memUsed: (NSInteger *) memUsed memTotal: (NSInteger *) memTotal;

/**
 * Generates current backtrace text report.
 */
+ (NSArray *)backtrace;

/**
 * Returns system configured DNS servers.
 */
+ (NSArray *)getSystemDNS: (BOOL) wantIpv4 wantIpv6: (BOOL) wantIpv6 numIpv4: (unsigned *)numIpv4 numIpv6: (unsigned *)numIpv6;

/**
 * Returns list of DNS servers.
 */
+ (NSArray *)getDNS: (BOOL) wantIpv4 wantIpv6: (BOOL) wantIpv6;

/**
 * Returns an array of strings of open file descriptors.
 */
+(NSArray *) lsof;

/**
 * Generates XMPP resource from user name.
 */
+(NSString *) generateResource:(NSString *) username;

/**
 * Builds telephone URL tel:// from input string.
 */
+(NSURL *) buildTelUrlFromString: (NSString *) telString;
+(NSURL *) buildSmsUrlFromString: (NSString *) telString;
@end