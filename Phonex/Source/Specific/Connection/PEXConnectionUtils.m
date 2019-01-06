//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXConnectionUtils.h"
#import "PEXSecurityCenter.h"

static NSString * S_SYSTEM_URL = @"https://system.phone-x.net:30444";
static NSString * S_SYSTEM_URL_CLIENT_CRT = @"https://system.phone-x.net:31444";

@implementation PEXConnectionUtils {

}

+ (NSString *) phonexSystemUrl
{
    return S_SYSTEM_URL;
}

+ (NSString *) phonexSystemUrlClientCrt
{
    return S_SYSTEM_URL_CLIENT_CRT;
}

+ (NSString *) systemUrlWithPath: (NSString * const) path
{
    return [S_SYSTEM_URL stringByAppendingFormat:@"/%@", path];
}

+ (NSString *) systemUrlClientCrtWithPath: (NSString * const) path
{
    return [S_SYSTEM_URL_CLIENT_CRT stringByAppendingFormat:@"/%@", path];
}

+ (NSString *) systemUrlWithAppend: (NSString * const) postFix
{
    return [S_SYSTEM_URL stringByAppendingString:postFix];
}
+ (NSString *) systemUrlClientCrtWithAppend: (NSString * const) postFix
{
    return [S_SYSTEM_URL_CLIENT_CRT stringByAppendingString:postFix];
}

+ (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSString * const authenticationMethod = challenge.protectionSpace.authenticationMethod;

    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [PEXSecurityCenter validateTrustForChallenge:challenge credential:NULL];
    }
    else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
    {
        [PEXSecurityCenter provideClientCertificateForChallenge:challenge
                                                     credential:NULL
                                                    privateData:[[PEXAppState instance] getPrivateData]];
    }
    else
    {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

+ (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSString * const authMethod = protectionSpace.authenticationMethod;

    const bool result = [authMethod isEqualToString:NSURLAuthenticationMethodServerTrust] ||
            [authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate];

    return result;
}

+ (int)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    const NSHTTPURLResponse * const httpResponse = (NSHTTPURLResponse*)response;
    const int code = [httpResponse statusCode];

    DDLogDebug(@"HTTP RESPONSE - Status code - %d", code);

    return code;
}

+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DDLogDebug(@"CONNECTION FAILED! Error - %@ %@",
            [error localizedDescription],
            [error userInfo][NSURLErrorFailingURLStringErrorKey]);
}

+ (NSData*) encodeDictionaryToHttpParameters:(NSDictionary*)dictionary
{
    NSMutableArray * const parts = [[NSMutableArray alloc] init];

    for (NSString * const key in dictionary)
    {
        NSString * const encodedValue = [dictionary[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * const encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * const part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }

    NSString * const encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}

@end