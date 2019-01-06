//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * PEX_SOAP_NAMESPACE;
FOUNDATION_EXPORT NSString * PEX_SOAP_NAMESPACE_ENVELOPE;

FOUNDATION_EXPORT NSString * PEX_SERVICE_NAME;
FOUNDATION_EXPORT NSString * PEX_SERVICE_NAME_DEVEL;

FOUNDATION_EXPORT NSUInteger PEX_SERVICE_PORT;
FOUNDATION_EXPORT NSUInteger PEX_SERVICE_PORT_NO_CERT;
FOUNDATION_EXPORT NSString * PEX_SERVICE_SCHEME;

@interface PEXServiceConstants : NSObject

+ (NSString *) getServiceEndpoint;
+ (NSString *) getServiceEndpointDevel;
+ (NSString *) getServiceWsdl;
+ (NSString *) getServiceWsdlDevel;

/**
* Returns URL to the data service.
* scheme + hostname + port + /
*
* @return
*/
+(NSString*) getServiceURL:(NSString *) domain;

/**
* Returns URL to the data service.
* scheme + hostname + port + /
*
* @return
*/
+(NSString*) getServiceURL: (NSString *) domain hasCert: (BOOL) hasCert;

/**
* Determines whether user wants to use development data server.
* @param ctxt
* @return
*/
+(BOOL) useDevel;

/**
* Returns default service endpoint for SOAP calls.
* @param ctxt
* @return
*/
+(NSString *) getSOAPServiceEndpoint;

/**
* Returns default URL for SOAP call.
*
* @param domain
* @return
*/
+(NSString *) getDefaultURL: (NSString *) domain;

/**
* Returns default URL for SOAP call.
* Takes USE_DEVEL_DATA_SERVER into consideration.
*
* @param domain
* @return
*/
+(NSString *) getDefaultURLDev: (NSString *) domain;

/**
* Returns default URL for REST call.
*
* @param domain
* @return
*/
+(NSString *) getDefaultRESTURL: (NSString *) domain;
+(NSString *) getDefaultRESTURL: (NSString *) domain hasCert: (BOOL) hasCert;

/**
* Returns default URL for REST call.
* Takes USE_DEVEL_DATA_SERVER into consideration.
*
* @param domain
* @return
*/
+(NSString *) getDefaultRESTURLDev: (NSString *) domain;


@end