//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXServiceConstants.h"
#import "PEXPhonexSettings.h"
#import "PEXUtils.h"

NSString * PEX_SOAP_NAMESPACE              = @"http://phoenix.com/hr/schemas";
NSString * PEX_SOAP_NAMESPACE_ENVELOPE     = @"http://schemas.xmlsoap.org/soap/envelope";

NSString * PEX_SERVICE_NAME                = @"phoenix";
NSString * PEX_SERVICE_NAME_DEVEL          = @"phoenix-alpha";

#ifdef PEX_BUILD_DEBUG
#  define PEX_CONST_SERVICE_PORT         18443
#  define PEX_CONST_SERVICE_PORT_NO_CERT 18442
#else
// Do not edit these under any circumstances. On the production version, production
// ports have to be set.
#  define PEX_CONST_SERVICE_PORT         38443
#  define PEX_CONST_SERVICE_PORT_NO_CERT 38442
#endif

NSUInteger PEX_SERVICE_PORT           = PEX_CONST_SERVICE_PORT;
NSUInteger PEX_SERVICE_PORT_NO_CERT   = PEX_CONST_SERVICE_PORT_NO_CERT;
NSString * PEX_SERVICE_SCHEME         = @"https";

@implementation PEXServiceConstants {

}

+ (NSString *) getServiceEndpoint {
    return [NSString stringWithFormat:@"%@/phoenixService", PEX_SERVICE_NAME];
}

+ (NSString *) getServiceEndpointDevel {
    return [NSString stringWithFormat:@"%@/phoenixService", PEX_SERVICE_NAME_DEVEL];
}

+ (NSString *) getServiceWsdl {
    return [NSString stringWithFormat:@"%@/phoenixService/phoenix.wsdl", PEX_SERVICE_NAME];
}

+ (NSString *) getServiceWsdlDevel {
    return [NSString stringWithFormat:@"%@/phoenixService/phoenix.wsdl", PEX_SERVICE_NAME_DEVEL];
}

/**
* Returns URL to the data service.
* scheme + hostname + port + /
*
* @return
*/
+(NSString*) getServiceURL:(NSString *) domain{
    return [self getServiceURL:domain hasCert:YES];
}

/**
* Returns URL to the data service.
* scheme + hostname + port + /
*
* @return
*/
+(NSString*) getServiceURL: (NSString *) domain hasCert: (BOOL) hasCert{
    return [NSString stringWithFormat:@"%@://%@:%lu/", PEX_SERVICE_SCHEME, domain, (unsigned long)(hasCert ? PEX_SERVICE_PORT : PEX_SERVICE_PORT_NO_CERT)];
}

/**
* Determines whether user wants to use development data server.
* @param ctxt
* @return
*/
+(BOOL) useDevel{
    return NO;
}

/**
* Returns default service endpoint for SOAP calls.
* @param ctxt
* @return
*/
+(NSString *) getSOAPServiceEndpoint {
    if (![PEXUtils isDebug]){
        return [self getServiceEndpoint];
    }

    return [self useDevel] ? [self getServiceEndpointDevel] : [self getServiceEndpoint];
}

/**
* Returns default URL for SOAP call.
*
* @param domain
* @return
*/
+(NSString *) getDefaultURL: (NSString *) domain{
    return [NSString stringWithFormat:@"%@://%@:%lu/%@", PEX_SERVICE_SCHEME, domain, (unsigned long)PEX_SERVICE_PORT, [self getServiceEndpoint]];
}

/**
* Returns default URL for SOAP call.
* Takes USE_DEVEL_DATA_SERVER into consideration.
*
* @param domain
* @param ctxt
* @return
*/
+(NSString *) getDefaultURLDev: (NSString *) domain{
    if (![PEXUtils isDebug]){
        return [self getDefaultURL:domain];
    }

    return [self useDevel] ?
              [NSString stringWithFormat:@"%@://%@:%lu/%@", PEX_SERVICE_SCHEME, domain, (unsigned long)PEX_SERVICE_PORT, [self getServiceEndpointDevel]]
            : [self getDefaultURL:domain];
}

/**
* Returns default URL for REST call.
*
* @param domain
* @return
*/
+(NSString *) getDefaultRESTURL: (NSString *) domain{
    return [self getDefaultRESTURL:domain hasCert:YES];
}

/**
* Returns default URL for REST call.
*
* @param domain
* @return
*/
+(NSString *) getDefaultRESTURL: (NSString *) domain hasCert: (BOOL) hasCert{
    return [NSString stringWithFormat:@"%@://%@:%lu/%@", PEX_SERVICE_SCHEME, domain, (unsigned long)(hasCert ? PEX_SERVICE_PORT : PEX_SERVICE_PORT_NO_CERT), PEX_SERVICE_NAME];
}

/**
* Returns default URL for REST call.
* Takes USE_DEVEL_DATA_SERVER into consideration.
*
* @param domain
* @param ctxt
* @return
*/
+(NSString *) getDefaultRESTURLDev: (NSString *) domain{
    if (![PEXUtils isDebug]){
        return [self getDefaultRESTURL:domain];
    }

    return [self useDevel] ?
            [NSString stringWithFormat:@"%@://%@:%lu/%@", PEX_SERVICE_SCHEME, domain, (unsigned long)PEX_SERVICE_PORT, PEX_SERVICE_NAME_DEVEL]
            : [self getDefaultRESTURL:domain];
}

@end