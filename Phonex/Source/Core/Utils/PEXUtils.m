//
// Created by Dusan Klinec on 25.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "PEXUtils.h"
#import "NSData+PEXGzip.h"
#import "PEXDbCursor.h"
#import "PEXStringUtils.h"
#import "PEXAppVersionUtils.h"
#import "PEXCancelledException.h"
#import "NSTimeZone+PEXOffset.h"
#import "PEXOpenUDID.h"
#import "PEXMessageDigest.h"
#import <MobileCoreServices/UTType.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <sys/socket.h>
#include <sys/un.h>
#import <netinet/in.h>
#include <resolv.h>

#import <sys/types.h>
#import <fcntl.h>
#import <errno.h>
#import <sys/param.h>

#include <dns.h>
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<sys/socket.h>
#include<arpa/inet.h>
#include<netinet/in.h>
#include<unistd.h>


static const NSUInteger GZIPChunkSize = 16384;

@implementation PEXUtils {

}

+ (BOOL)isEmpty:(NSString *)string {
    return string == nil || string.length == 0 || [string isKindOfClass:[NSNull class]];
}

+ (BOOL)isEmptyArr:(NSArray *)arr {
    return arr == nil || arr.count == 0 || [arr isKindOfClass:[NSNull class]];
}

+ (BOOL)isEmptyData:(NSData *)dat {
    return dat == nil || dat.length == 0 || [dat isKindOfClass:[NSNull class]];
}

+ (NSString *)getStringMaxLen:(NSString *)input length:(int)length {
    if (input == nil || input.length <= length){
        return input;
    }

    return [input substringWithRange:NSMakeRange(0, length)];
}

+ (BOOL)areNSNumbersEqual:(NSNumber *)a b:(NSNumber *)b {
    if (a==nil){
        return b==nil;
    }
    if (b==nil){
        return NO;
    }

    return [a isEqualToNumber:b];
}

+ (BOOL)areNSStringsEqual:(NSString *)a b:(NSString *)b {
    if (a==nil){
        return b==nil;
    }
    if (b==nil){
        return NO;
    }

    return [a isEqualToString:b];
}

+ (BOOL)doErrorMatch:(NSError *)err domain:(NSString *)domain {
    if (err == nil){
        return NO;
    }

    return [self areNSStringsEqual:err.domain b:domain];
}

+ (BOOL)doErrorMatch:(NSError *)err domain:(NSString *)domain code:(NSInteger)code {
    if (err == nil || ![self areNSStringsEqual:err.domain b:domain]){
        return NO;
    }

    return err.code == code;
}

+ (NSError *)getErrorFromArray: (NSArray *) errorsArray domain: (NSString *)domain {
    if (errorsArray == nil || errorsArray.count == 0){
        return nil;
    }

    for(NSError * err in errorsArray){
        if (err == nil) continue;
        if ([PEXUtils areNSStringsEqual:err.domain b:domain]){
            return err;
        }
    }

    return nil;
}

+ (NSError *)getErrorFromArray:(NSArray *) errorsArray domain:(NSString *) domain code:(NSInteger)code {
    if (errorsArray == nil || errorsArray.count == 0){
        return nil;
    }

    for(NSError * err in errorsArray){
        if (err == nil) continue;
        if ([PEXUtils areNSStringsEqual:err.domain b:domain] && err.code == code){
            return err;
        }
    }

    return nil;
}

+ (BOOL) isErrorWithConnectivity: (NSError *) err {
    return err != nil && [PEXUtils doErrorMatch:err domain:NSURLErrorDomain];
}

+ (NSData *)getDataFromStream:(NSOutputStream *)os {
    NSData * dat = [os propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    return dat;
}

+ (void)setError:(NSError **)err domain:(NSString *)domain {
    if (err == NULL){
        return;
    }

    *err = [NSError errorWithDomain:domain code:0 userInfo:@{}];
}

+ (void)setError:(NSError **)err domain:(NSString *)domain code:(NSInteger)code {
    if (err == NULL){
        return;
    }

    *err = [NSError errorWithDomain:domain code:code userInfo:@{}];
}

+ (void)setError:(NSError **)err domain:(NSString *)domain code:(NSInteger)code subCode:(NSInteger)subCode {
    if (err == NULL){
        return;
    }

    *err = [NSError errorWithDomain:domain code:code userInfo:@{PEXExtraSubCode : @(subCode)}];
}

+ (NSData *)compressGzip:(NSData *)input {
    if (input == nil) {
        return nil;
    }

    return [input gzippedData];
}

+ (NSData *)decompressGzip:(NSData *)input {
    if (input == nil){
        return nil;
    }

    return [input gunzippedData];
}

+ (uint64_t)currentTimeMillis {
    return (uint64_t) [@([[NSDate date] timeIntervalSince1970] * 1000.0) longLongValue];
}

+ (uint64_t)millisFromDate:(NSDate *)date {
    if (date == nil){
        return 0ull;
    }

    return (uint64_t) ([date timeIntervalSince1970] * 1000.0);
}

+ (NSDate *)dateFromMillis:(uint64_t)milli {
    return [NSDate dateWithTimeIntervalSince1970:(milli / 1000.0)];
}

+ (NSString *)generateDbPlaceholders:(int)count {
    NSMutableString * ret = [[NSMutableString alloc] init];
    if (count == 0) {
        return ret;
    }

    [ret appendString:@"?"];
    for (NSUInteger i = 1; i < count; ++i){
        [ret appendString:@",?"];
    }

    return ret;
}

+ (void)closeSilentlyCursor:(PEXDbCursor *)c {
    [self closeSilentlyCursor:c logException:NO logTag:nil];
}

+ (void)closeSilentlyCursor:(PEXDbCursor *)c logException:(BOOL)logException logTag:(NSString *)logTag {
    if (c == nil){
        return;
    }

    @try{
        [c close];
    } @catch(NSException * e){
        if (logException){
            DDLogError(@"Cursor [%@] closing exception=%@", logTag == nil ? @"nil" : logTag, e);
        }
    }
}

+ (void)closeSilently:(NSStream *)c {
    [self closeSilently:c logException:NO logTag:nil];
}

+ (void)closeSilently:(NSStream *)c logException:(BOOL)logException logTag:(NSString *)logTag {
    if (c == nil){
        return;
    }

    @try{
        [c close];
    } @catch(NSException * e){
        if (logException){
            DDLogError(@"Cursor [%@] closing exception=%@", logTag == nil ? @"nil" : logTag, e);
        }
    }
}

+ (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block {
    if (!block) {
        return;
    } else if ([NSThread isMainThread]) {
        block();
    } else if (async) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)executeOnQueue:(dispatch_queue_t)queue async:(BOOL)async block:(dispatch_block_t)block {
    if (!block) {
        return;
    } else if (async) {
        dispatch_async(queue, block);
    } else {
        dispatch_sync(queue, block);
    }
}

+ (BOOL)areSameDay:(NSDate *)dateA b:(NSDate *)dateB {
    NSUInteger day1 = [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitEra forDate:dateA];
    NSUInteger day2 = [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitEra forDate:dateB];
    return day1 == day2;
}


+ (BOOL)isToday:(NSDate *)date {
    return [self areSameDay:date b:[NSDate date]];
}

+ (NSString *)dateDiffFromNowFormatted:(NSDate *)date compact: (BOOL) compact {
    if (date == nil){
        return nil;
    }

    NSDate * dt = [NSDate date];
    NSTimeInterval interval = [dt timeIntervalSince1970] - [date timeIntervalSince1970];
    return [self timeIntervalFormatted:interval compact:compact];
}

+ (NSString *)timeIntervalFormatted:(NSTimeInterval)interval compact:(BOOL)compact {
    NSInteger iter = (NSInteger) interval;
    BOOL negative = interval < 0;
    NSString * prefix = compact ? @"" : @" ";
    if (negative){
        prefix = @"-";
        iter *= -1;
        interval *= -1.0;
    }

    int millis = (int)(interval * 1000.0) % 1000;
    int seconds = (iter % 60);
    int minutes = (iter / 60) % 60;
    int hours = (iter / 60 / 64) % 24;
    int days = (iter /60 / 60 / 24);

    if (compact){
        if (days == 0 && hours == 0 && minutes == 0){
            return [NSString stringWithFormat:@"%@%02d.%03ds", prefix, seconds, millis];
        } else if (days == 0 && hours == 0){
            return [NSString stringWithFormat:@"%@%02d:%02d.%03d", prefix, minutes, seconds, millis];
        } else if (days == 0){
            return [NSString stringWithFormat:@"%@%02d:%02d:%02d.%03d", prefix, hours, minutes, seconds, millis];
        }
    }

    return [NSString stringWithFormat:@"%@%02d %02d:%02d:%02d.%03d", prefix, days, hours, minutes, seconds, millis];
}

+ (int)compareDate:(NSDate *)a b:(NSDate *)b {
    uint64_t am = a == nil ? 0 : [self millisFromDate:a];
    uint64_t bm = b == nil ? 0 : [self millisFromDate:b];
    if (a == b){
        return 0;
    }

    return a < b ? -1 : 1;
}

+ (BOOL)isDate:(NSDate *)a olderThan:(NSTimeInterval)b {
    NSTimeInterval intA = a == nil ? 0 : [a timeIntervalSince1970];
    NSTimeInterval cur = [[NSDate date] timeIntervalSince1970];
    return intA < (cur - b);
}

+ (BOOL)isEnterprise {
#if defined(PEX_BUILD_ENT)
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isDebug {
#ifdef PEX_BUILD_DEBUG
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isRadioConnectivityFast:(NSString*)radioAccessTechnology {
    if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
        return YES;
    }

    return YES;
}

/**
* Converts byte array to hex coded string.
* @param NSData
* @return
*/
+(NSString *) bytesToHex: (NSData *) bytes {
    if (bytes == nil) return @"";
    return [self bytesToHex:bytes maxLen:[bytes length]];
}

/**
* Converts byte array to hexa string.
* @param bytes
* @param maxLen
* @return
*/
+(NSString *) bytesToHex: (NSData *) bytes maxLen: (NSUInteger) maxLen {
    if (bytes == nil) return @"";
    const NSUInteger ln = bytes.length;
    const NSUInteger cn = MIN(maxLen, ln);
    uint8_t const * dbytes = [bytes bytes];

    NSMutableString * sb = [[NSMutableString alloc] initWithCapacity:5*cn];
    for ( NSUInteger j = 0; j < cn; j++ ){
        [sb appendFormat:@"0x%02x ", dbytes[j] & 0xff];
    }

    return [NSString stringWithString:sb];
}

+(uint64_t) fileSize: (NSString *) path error: (NSError **) err{
    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSDictionary * dict = [fmgr attributesOfItemAtPath: path error: err];
    return [dict fileSize];
}

+ (BOOL)fileExistsAndIsAfile:(NSString *)filePath {
    return [self fileExistsAndIsAfile:filePath fmgr: [NSFileManager defaultManager]];
}

+ (BOOL)fileExistsAndIsAfile:(NSString *)filePath fmgr: (NSFileManager *) fmgr {
    if (filePath == nil || fmgr == nil) return NO;
    BOOL isADirectory = NO;

    BOOL exists = [fmgr fileExistsAtPath:filePath isDirectory:&isADirectory];
    return exists && !isADirectory;
}

+ (BOOL) directoryExists: (NSString *)dirPath {
    return [self directoryExists:dirPath fmgr: [NSFileManager defaultManager]];
}

+ (BOOL) directoryExists: (NSString *)dirPath fmgr: (NSFileManager *) fmgr{
    if (dirPath == nil || fmgr == nil) return NO;
    BOOL isADirectory = NO;

    if (![dirPath hasSuffix:@"/"]) {
        dirPath = [dirPath stringByAppendingString:@"/"];
    }

    BOOL exists = [fmgr fileExistsAtPath:dirPath isDirectory:&isADirectory];
    return exists && isADirectory;
}

+ (NSString *) ensureDirectoryPath: (NSString *) dirPath{
    if (![dirPath hasSuffix:@"/"]) {
        dirPath = [dirPath stringByAppendingString:@"/"];
    }

    return dirPath;
}

+ (NSString *) getFileBaseName: (NSString *) fileName {
    return [[fileName lastPathComponent] stringByDeletingPathExtension];
}

+ (BOOL)isDataSameAndNonNil:(NSData *)a b:(NSData *)b {
    if (a == nil || b == nil) return NO;
    return [a isEqualToData:b];
}

+(NSString *) createTemporaryFileFrom: (NSString *) file dir: (NSString *) dir {

    return [self createTemporaryFileFrom:file dir:dir withExtension:file.pathExtension];
}

+(NSString *) createTemporaryFileFrom: (NSString *) file dir: (NSString *) dir
                        withExtension: (NSString *) extension
{
    NSString * baseName  = [PEXUtils getFileBaseName:file];
    NSString * suffix    = [PEXStringUtils isEmpty:extension] ? @"" : [NSString stringWithFormat:@".%@", extension];
    return  [self createTemporaryFile:baseName suffix:suffix dir:dir];
}

+(NSString *) createTemporaryFile: (NSString *) prefix suffix: (NSString *) suffix dir: (NSString *) dir {
    NSFileManager * fmgr = [NSFileManager defaultManager];
    BOOL isDirectory = NO;

    dir = [self ensureDirectoryPath:dir];
    if (![fmgr fileExistsAtPath:dir isDirectory:&isDirectory]
            || !isDirectory
            || ![fmgr isWritableFileAtPath:dir]){
        DDLogError(@"Temporary directory does not exist or is not writable");
        return nil;
    }

    NSString * newFileName = nil;
    NSString * newFilePath = nil;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    for(NSUInteger i = 0; i < 25; i++){
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString * newDate = [dateFormatter stringFromDate:[NSDate date]];
        NSString * uuid    = [[NSUUID UUID] UUIDString];
        NSString * rndPart = i == 0 ? [NSString stringWithFormat:@"_%@", newDate]
                : [NSString stringWithFormat:@"_%@_%@", newDate, [uuid substringToIndex:8]];

        newFileName = [NSString stringWithFormat:@"%@%@%@", prefix, rndPart, suffix];
        newFilePath = [NSString pathWithComponents:@[dir,newFileName]];

        if (![self fileExistsAndIsAfile:newFilePath fmgr:fmgr]){
            BOOL success = [fmgr createFileAtPath:newFilePath contents:[NSData data] attributes:nil];
            if (success){
                break;
            }
        }

        newFilePath = nil;
    }

    return newFilePath;
}

+ (BOOL)removeFile:(NSString *)file {
    if ([PEXStringUtils isEmpty:file]){
        return NO;
    }

    NSFileManager * fmgr = [NSFileManager defaultManager];
    return [fmgr removeItemAtPath:file error:nil];
}

+ (NSString *) guessMIMETypeFromExtension: (NSString *) extension {
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    if (uti != NULL)
    {
        CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime != NULL)
        {
            NSString *type = [NSString stringWithString:(__bridge NSString *)mime];
            CFRelease(mime);
            return type;
        }
    }
    return @"application/octet-stream";
}

+ (NSLocale *) getCurrentLocale {
    NSString * curAppLang = [PEXResStrings getCurrentAppLanguage];
    if (![PEXUtils isEmpty:curAppLang] && ![PEX_LANGUAGE_SYSTEM isEqualToString:curAppLang]){
        NSLocale * tmpLoc = [NSLocale localeWithLocaleIdentifier:curAppLang];
        if (tmpLoc != nil){
            return tmpLoc;
        }
    }

    NSArray * langs = [NSLocale preferredLanguages];
    if (langs == nil){
        return [NSLocale currentLocale];
    }

    return langs[0];
}

+ (NSArray *) getPreferredLanguages {
    NSArray * langs = [NSLocale preferredLanguages];
    if (langs == nil){
        langs = [[NSArray alloc] init];
    }

    // Get language set in the application, merge with the system language list.
    NSString * curAppLang = [PEXResStrings getCurrentAppLanguage];
    if (![PEXUtils isEmpty:curAppLang] && ![PEX_LANGUAGE_SYSTEM isEqualToString:curAppLang]){
        NSMutableArray * newLang = [NSMutableArray arrayWithCapacity:[langs count] + 1];
        [newLang addObject:curAppLang];

        for(NSString * sysLang in langs){
            if ([curAppLang isEqualToString:sysLang]){
                continue;
            }

            [newLang addObject:sysLang];
        }

        langs = [NSArray arrayWithArray:newLang];
    }

    return langs;
}

+ (NSString *)getCurrentTimeZone {
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    return [NSString stringWithFormat:@"GMT%@", [timeZone offsetString]];
}

+ (NSDictionary *)getAppVersion {
    NSString * const appVersionString = [PEXAppVersionUtils fullVersionString];
    NSString * const systemVersionString = [[UIDevice currentDevice] systemVersion];

    NSDictionary* info = @{
            @"v"    : @(1),
            @"p"    : @"iOS",
            @"oscd" : systemVersionString,
            @"info" : @"PhoneX",
            @"bld"  : @([PEXUtils isDebug]),
            @"ent"  : @([PEXUtils isEnterprise]),
            @"ac"   : appVersionString,
            @"locales" : [self getPreferredLanguages],
            @"tz"   : [self getCurrentTimeZone],
            @"tzn"  : [[NSTimeZone localTimeZone] name],
            @"tzoff": @([[NSTimeZone localTimeZone] secondsFromGMT])};

    return info;
}

+ (NSString *)getUniversalApplicationCode {
    NSError * err = nil;
    NSDictionary * info = [self getAppVersion];
    NSString * jsonReturn = [self serializeToJSON:info error:&err];
    if (err != nil){
        DDLogError(@"Error during building JSON entity from: %@", info);
        return nil;
    }

    if (jsonReturn == nil){
        DDLogError(@"JSON entity empty from: %@", info);
        return nil;
    }

    return jsonReturn;
}

+ (NSString *) serializeToJSON: (NSDictionary *) dict error: (NSError **) pError; {
    NSError * err = nil;
    NSData * jsonData = nil;
    NSString * jsonReturn = nil;

    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
        jsonReturn = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    } @catch(NSException *e){
        DDLogError(@"Exception in JSON entity encoding: %@", e);
        return nil;
    }

    if (err != nil){
        DDLogError(@"Error during building JSON entity");
        if (pError != nil){
            *pError = err;
        }

        return nil;
    }

    if (jsonData == nil || jsonReturn == nil){
        DDLogError(@"JSON entity empty");
        return nil;
    }

    return jsonReturn;
}

+ (void)addIfNonNil:(NSMutableDictionary *)dict key:(id <NSCopying>)key value:(id)value {
    if (dict == nil || value == nil || key == nil){
        return;
    }

    dict[key] = value;
}

+ (void)addIfNonNil:(NSMutableDictionary *)dict key:(id <NSCopying>)key date:(NSDate *)date {
    if (dict == nil || date == nil || key == nil){
        return;
    }

    dict[key] = @([date timeIntervalSince1970]);
}

/**
* Dropf first n character from the input stream.
*/
+(int) dropFirstN: (NSInputStream *) is n: (NSUInteger) n c: (cancel_block) cancelBlock {
    if (n <= 0){
        return 0;
    }

    const int buffSize = n >= 2048 ? 2048 : n;
    const NSMutableData * buff = [NSMutableData dataWithLength:buffSize];
    uint8_t * bytes = [buff mutableBytes];

    NSInteger numBytes;
    NSInteger offReadTotal = n;
    while (offReadTotal > 0 && (numBytes = [is read:bytes maxLength: (NSUInteger) (offReadTotal >= buffSize ? buffSize : offReadTotal)]) > 0) {
        offReadTotal -= numBytes;

        // Cancelled ?
        if (cancelBlock != nil && cancelBlock()) {
            break;
        }
    }

    // If cancelled, throw exception to inform caller about unusual situation.
    if (cancelBlock != nil && cancelBlock()) {
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Cancelled"];
    }

    if (offReadTotal != 0){
        [NSException raise:PEXRuntimeException format:@"Could not read exactly %d bytes", (int) n];
    }

    return n;
}

+ (NSNumber *)getAsNumber:(id)obj {
    if (obj == nil){
        return nil;
    }

    if ([obj isKindOfClass:[NSNumber class]]){
        return (NSNumber *)obj;
    }

    if ([obj isKindOfClass:[NSString class]]){
        if ([@"" isEqualToString:(NSString *) obj]){
            return nil;
        }

        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        return [f numberFromString:(NSString *) obj];
    }

    @throw [NSException exceptionWithName:@"UnknownNumberObject" reason:@"Unknown number object" userInfo:@{}];
}

+ (NSString *)getAsString:(id)obj {
    if (obj == nil){
        return nil;
    }

    if ([obj isKindOfClass:[NSString class]]){
        return (NSString *)obj;
    }

    return nil;
}

+(NSString *)getFreeMemoryReport:(NSInteger *)virtual resident:(NSInteger *)resident suspend: (NSInteger *) suspend {
    @try {
        struct task_basic_info info;
        mach_msg_type_number_t size = sizeof( info );
        kern_return_t kerr = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size );

        if (kerr != KERN_SUCCESS){
            return @"Could not obtain statistics";
        }

        if (virtual != NULL) {
            *virtual = info.virtual_size;
        }

        if (resident != NULL) {
            *resident = info.resident_size;
        }

        if (suspend != NULL) {
            *suspend = info.suspend_count;
        }

        return [NSString stringWithFormat:@"Memory virtual: %ld (%.2f MB) resident: %ld (%.2f MB) suspendCount: %ld, "
                                                  "userTime: %d.%d, systemTime: %d.%d",
                        (long)info.virtual_size, info.virtual_size/1024.0/1024.0,
                        (long)info.resident_size, info.resident_size/1024.0/1024.0,
                        (long)info.suspend_count,
                        info.user_time.seconds,info.user_time.microseconds/1000,
                        info.system_time.seconds, info.system_time.microseconds/1000];

    } @catch(NSException * e){
        DDLogError(@"Could not obtain VM memory report, exception: %@", e);
    }

    return nil;
}

+(NSString *) getSystemFreeMemoryReport: (NSInteger *) memFree memUsed: (NSInteger *) memUsed memTotal: (NSInteger *) memTotal {
    @try {
        mach_port_t host_port;
        mach_msg_type_number_t host_size;
        vm_size_t pagesize;

        host_port = mach_host_self();
        host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
        host_page_size(host_port, &pagesize);

        vm_statistics_data_t vm_stat;

        if (host_statistics(host_port, HOST_VM_INFO, (host_info_t) &vm_stat, &host_size) != KERN_SUCCESS) {
            DDLogError(@"Failed to fetch VM memory statistics");
            return nil;
        }

        /* Stats in bytes */
        natural_t mem_used = (vm_stat.active_count +
                vm_stat.inactive_count +
                vm_stat.wire_count) * pagesize;
        natural_t mem_free = vm_stat.free_count * pagesize;
        natural_t mem_total = mem_used + mem_free;

        if (memFree != NULL) {
            *memFree = mem_free;
        }

        if (memUsed != NULL) {
            *memUsed = mem_used;
        }

        if (memTotal != NULL) {
            *memTotal = mem_total;
        }

        return [NSString stringWithFormat:@"Memory used: %u (%.2f MB) free: %u (%.2f MB) total: %u (%.2f MB).",
                        mem_used, mem_used/1024.0/1024.0,
                        mem_free, mem_free/1024.0/1024.0,
                        mem_total, mem_total/1024.0/1024.0];

    } @catch(NSException * e){
        DDLogError(@"Could not obtain VM memory report, exception: %@", e);
    }

    return nil;
}

+ (NSArray *)backtrace {
    @try {
        void *callstack[128];
        int frames = backtrace(callstack, 128);
        if (frames <= 0){
            DDLogWarn(@"Could not extract backtrace, frames: %d", frames);
            return @[];
        }

        char **strs = backtrace_symbols(callstack, frames);
        if (strs == NULL){
            DDLogWarn(@"Backtrace symbols not extracted, NULL returned");
            return @[];
        }

        NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity: (NSUInteger) frames];
        for (int i = 0; i < frames; i++) {
            [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
        }

        free(strs);
        return backtrace;

    }@catch(NSException * e){

        DDLogError(@"Irony, exception in exception handler, %@", e);
    }

    return @[];
}

+ (NSArray *)getSystemDNS: (BOOL) wantIpv4 wantIpv6: (BOOL) wantIpv6 numIpv4: (unsigned *)numIpv4 numIpv6: (unsigned *)numIpv6{
    // Get native iOS System Resolvers
    res_state res = malloc(sizeof(struct __res_state));
    if (res == NULL){
        DDLogError(@"Could not allocate memory for DNS resolution");
        return @[];
    }

    union res_9_sockaddr_union *addr_union = NULL;
    NSMutableArray * dns = [[NSMutableArray alloc] initWithCapacity:4];
    @try {
        int status = res_ninit(res);
        if (status == 0) {

            addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
            res_getservers(res, addr_union, res->nscount);

            for (int i = 0; i < res->nscount; i++) {
                if (addr_union[i].sin.sin_family == AF_INET) {
                    char ip[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                    NSString *dnsIP = [NSString stringWithUTF8String:ip];
                    if (![@"0.0.0.0" isEqualToString:dnsIP]) {
                        [dns addObject:dnsIP];
                        if (numIpv4!=NULL){
                            *numIpv4+=1;
                        }
                    }
                    DDLogVerbose(@"IPv4 DNS IP: %@", dnsIP);

                } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                    char ip[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
                    NSString *dnsIP = [NSString stringWithUTF8String:ip];
                    [dns addObject:dnsIP];
                    if (numIpv6!=NULL){
                        *numIpv6+=1;
                    }
                    DDLogVerbose(@"IPv6 DNS IP: %@", dnsIP);

                }
            }
        }
        res_nclose(res);


//        for (int i = 0; i < res->nscount; i++) {
//            sa_family_t family = res->nsaddr_list[i].sin_family;
//            int port = ntohs(res->nsaddr_list[i].sin_port);
//            if (family == AF_INET && wantIpv4) { // IPV4 address
//                char str[INET_ADDRSTRLEN]; // String representation of address
//                inet_ntop(AF_INET, &(res->nsaddr_list[i].sin_addr.s_addr), str, INET_ADDRSTRLEN);
//
//                NSString const * curDns = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
//                if (![@"0.0.0.0" isEqualToString:curDns]) {
//                    [dns addObject:curDns];
//                    if (numIpv4!=NULL){
//                        *numIpv4+=1;
//                    }
//                }
//
//            } else if (family == AF_INET6 && wantIpv6) { // IPV6 address
//                char str[INET6_ADDRSTRLEN]; // String representation of address
//                inet_ntop(AF_INET6, &(res->nsaddr_list[i].sin_addr.s_addr), str, INET6_ADDRSTRLEN);
//                [dns addObject:[NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
//                if (numIpv6!=NULL){
//                    *numIpv6+=1;
//                }
//            }
//        }


    } @catch(NSException * e){
        DDLogError(@"Exception in DNS resolution: %@", e);

    } @finally {
        if (res != NULL) {
            res_ndestroy(res);
            free(res);
        }

        if (addr_union != NULL){
            free(addr_union);
        }
    }

    return dns;
}

+ (NSArray *)getDNS: (BOOL) wantIpv4 wantIpv6: (BOOL) wantIpv6 {
    unsigned numIpv4 = 0, numIpv6 = 0;
    NSMutableArray * systemDns = [[self getSystemDNS:wantIpv4 wantIpv6:wantIpv6 numIpv4:&numIpv4 numIpv6:&numIpv6] mutableCopy];
    NSMutableSet * dnsSet = [[NSMutableSet alloc] initWithArray:systemDns];

    // Helper
    void (^addDns)(NSString *) = ^void(NSString * curDns) {
        if (![dnsSet containsObject:curDns]){
            [dnsSet addObject:curDns];
            [systemDns addObject:curDns];
        }
    };

    // No system DNS detected -> it may be ipv6-only network (Apple testing)
    if (numIpv4 == 0 && numIpv6 == 0){
        // Return empty list -> use gethostbyname() resolver, simple.
        // TURN does not work with the simple one, but async one returns A records also.
        // Maybe NAT64 has some issues with SRV records.
        return @[];
    }

    // If there are only ipv6 resolvers, it might be NAT64 -> problematic with SRV.
    // Here is probably the same problem as we had in STUN resolving... Invalid logic.
    // -> Do nothing.
    if (numIpv4 == 0) {
        return @[];
    }

    // Some DNS were detected
    // Do not add IPV4 if there were only IPV6 detected.
    if (wantIpv4 && numIpv6 == 0){
        addDns(@"8.8.8.8");
        addDns(@"8.8.4.4");
    }

    // Do not add IPV6 if there were only ipv4 detected.
    if (wantIpv6 && numIpv6 != 0){
        // DNS64 - https://developers.google.com/speed/public-dns/docs/dns64
        //addDns(@"2001:4860:4860::6464");
        //addDns(@"2001:4860:4860::64");

        // Classical IPV6
        //addDns(@"2001:4860:4860::8888");
        //addDns(@"2001:4860:4860::8844");
    }

    return systemDns;
}

+(NSString *) getFamily: (sa_family_t) fa {
    NSString * family;
    if (fa == AF_UNIX) {
        family = @"unix";
    } else if (fa == AF_INET){
        family = @"inet";
    } else if (fa == AF_INET6){
        family = @"inet6";
    } else {
        family = [NSString stringWithFormat:@"%u", (unsigned)fa];
    }

    return family;
}

+(NSArray *) getFileDescriptorFlags: (int) flags{
    NSMutableArray * flagsArray = [[NSMutableArray alloc] init];
    if (flags == O_RDONLY) [flagsArray addObject:@"O_RDONLY"];
    if (flags & O_WRONLY) [flagsArray addObject:@"O_WRONLY"];
    if (flags & O_RDWR) [flagsArray addObject:@"O_RDWR"];
    if (flags & O_CREAT) [flagsArray addObject:@"O_CREAT"];
    if (flags & O_EXCL) [flagsArray addObject:@"O_EXCL"];
    if (flags & O_NOCTTY) [flagsArray addObject:@"O_NOCTTY"];
    if (flags & O_TRUNC) [flagsArray addObject:@"O_TRUNC"];
    if (flags & O_APPEND) [flagsArray addObject:@"O_APPEND"];
    if (flags & O_ASYNC) [flagsArray addObject:@"O_ASYNC"];
    if (flags & O_NONBLOCK) [flagsArray addObject:@"O_NONBLOCK"];
    if (flags & O_DSYNC) [flagsArray addObject:@"O_DSYNC"];
    if (flags & O_SYNC) [flagsArray addObject:@"O_SYNC"];
    if (flags & FNDELAY) [flagsArray addObject:@"FNDELAY"];
    return flagsArray;
}

+(NSString *) getSocketOptions: (int) fd {
    int optval = 0, res = 0;
    socklen_t optlen;

    // Flags:
    BOOL reuseAddr = NO;
    BOOL accepts = NO;
    int type = 0;
    NSString * sockType = nil;

    errno = 0;
    optlen = sizeof(optval);
    res = getsockopt(fd, SOL_SOCKET, SO_TYPE, &optval, &optlen);
    if (res == -1 && errno == EBADF){
        return nil;
    }

    if (res == 0 && optval) {
        type = optval;
        if (type == SOCK_STREAM){
            sockType = @"TCP";
        } else if (type == SOCK_DGRAM){
            sockType = @"UDP";
        } else if (type == SOCK_RAW){
            sockType = @"RAW";
        } else {
            sockType = [NSString stringWithFormat:@"%d", type];
        }
    } else {
        return nil;
    }

    optlen = sizeof(optval);
    res = getsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, &optlen);
    if (res == 0 && optval) {
        reuseAddr = YES;
    }

    optlen = sizeof(optval);
    res = getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &optval, &optlen);
    if (res == 0 && optval) {
        accepts = YES;
    }

    return [NSString stringWithFormat:@"%@ listen:%d, reuse:%d", sockType, accepts, reuseAddr];
}

+(NSString *) getSocketEndDesc: (int) res sa: (struct sockaddr*) sa len: (socklen_t) len{
    if (res != 0){
        if (errno == ENOTSOCK){
            return @"no-sock";
        }

        return nil;
    }

    struct sockaddr_un *sun = NULL;
    struct sockaddr_in *sin = NULL;
    NSString * family = [self getFamily:sa->sa_family];
    switch (sa->sa_family) {
        case AF_UNIX:
            sun = (struct sockaddr_un *) sa;

            return [NSString stringWithFormat:@"%@ %s", family, sun->sun_path];
            break;
        case AF_INET:
            sin = (struct sockaddr_in *) sa;

            return [NSString stringWithFormat:@"%@ %s:%u", family, inet_ntoa(sin->sin_addr), (unsigned)ntohs(sin->sin_port)];
            break;
        default:

            return [NSString stringWithFormat:@"%@", family];
            break;
    }
}

+(NSArray *) lsof {
    int flags, flags2;
    int fd;
    char buf[MAXPATHLEN+1] ;
    int n = 1;
    NSMutableArray * toRet = [[NSMutableArray alloc] init];

    for (fd = 0; fd < (int) FD_SETSIZE; fd++) {
        NSString *fdDesc = nil;
        NSArray *flagsArray = @[];
        errno = 0;

        // Get file descriptor flags.
        flags = fcntl(fd, F_GETFD, 0);
        if (flags != -1) {
            flagsArray = [self getFileDescriptorFlags:flags];

            // If fd is a file, obtain file name.
            memset(buf, 0x0, MAXPATHLEN + 1);
            flags2 = fcntl(fd, F_GETPATH, buf);
            if (flags2 != -1) {
                fdDesc = [NSString stringWithFormat:@"%s", buf];
            }
        } else if (flags == -1 && errno == EBADF){
            continue;
        }

        // Maybe a socket?
        if ([PEXUtils isEmpty:fdDesc]){
            int res = 0;
            NSString * local;
            NSString * remote;
            struct sockaddr sa;

            struct sockaddr_storage storage;
            socklen_t sa_size;

            // Socket options
            NSString * sockOpts = [self getSocketOptions:fd];

            // Local
            errno = 0;
            sa_size = sizeof(sa);
            res = getsockname(fd, &sa, &sa_size);
            local = [self getSocketEndDesc:res sa:&sa len:sa_size];

            // Remote
            errno = 0;
            sa_size = sizeof(sa);
            res = getpeername(fd, &sa, &sa_size);
            remote = [self getSocketEndDesc:res sa:&sa len:sa_size];

            if (local != nil || remote != nil || sockOpts != nil){
                fdDesc = [NSString stringWithFormat:@"%@; %@ -> %@", sockOpts, local, remote];
            }
        }

        // Do we have valid info?
        if (![PEXUtils isEmpty:fdDesc]) {
            [toRet addObject:[NSString stringWithFormat:@"#%02d fd%02d; %@; flags: %04X: %@",
                                                        n, fd, fdDesc, flags, [flagsArray componentsJoinedByString:@", "]]];
            ++n;
        }
    }

    return toRet;
}

+(NSString *) generateResource:(NSString *) username {
    NSString * toHash = [NSString stringWithFormat:@"%@||%@", username, [PEXOpenUDID value]];
    NSString * hashed = [PEXMessageDigest bytes2hex: [PEXMessageDigest sha256Message:toHash]];
    if ([PEXUtils isEmpty:hashed]){
        DDLogError(@"Could not create XMPP resource ID");
        return nil;
    }

    return [NSString stringWithFormat:@"phxio_%@", [hashed substringToIndex:10]];
}

+ (NSURL *)buildTelUrlFromString:(NSString *)telString {
    NSString * str = [telString stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"tel://%@", str]];
}

+ (NSURL *)buildSmsUrlFromString:(NSString *)telString {
    NSString * str = [telString stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"sms://%@", str]];
}

@end