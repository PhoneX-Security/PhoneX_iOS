//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXConnectionUtils : NSObject

+ (NSString *) phonexSystemUrl;
+ (NSString *) phonexSystemUrlClientCrt;
+ (NSString *) systemUrlWithPath: (NSString * const) path;
+ (NSString *) systemUrlClientCrtWithPath: (NSString * const) path;
+ (NSString *) systemUrlWithAppend: (NSString * const) postFix;
+ (NSString *) systemUrlClientCrtWithAppend: (NSString * const) postFix;

+ (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
+ (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
+ (int)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

+ (NSData*) encodeDictionaryToHttpParameters:(NSDictionary*)dictionary;

@end