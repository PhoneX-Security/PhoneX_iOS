//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoenixPortServiceSvc.h"
#import "PEXSubTask.h"
#import "PEXUserPrivate.h"

FOUNDATION_EXPORT NSString * PEX_EXTRA_SOAP_FAULT;

typedef enum {
    PEX_SOAP_ERROR_NONE,
    PEX_SOAP_ERROR_CANCELLED,
    PEX_SOAP_ERROR_TIMEDOUT,
    PEX_SOAP_ERROR_UNEXPECTED_RESPONSE,
    PEX_SOAP_ERROR_SOAP_FAULT,
    PEX_SOAP_ERROR_TASK_ERROR,
    PEX_SOAP_ERROR_INVALID_RESPONSE
} PEXSoapTaskErrorEnum;

@interface PEXSOAPTask : PEXSubTask <PhoenixPortSoap11BindingResponseDelegate> { }
/**
* SOAP source operation - needs to be filled in by the user before starting this task.
*/
@property (nonatomic) PhoenixPortSoap11BindingOperation * srcOperation;

/**
 * Response body from the SOAP response. Present only if desiredClass is set.
 */
@property (nonatomic) id responseBody;

/**
 * Raw SOAP response.
 */
@property (nonatomic) PhoenixPortSoap11BindingResponse * response;

/**
 * Operation passed to the finished callback.
 */
@property (nonatomic) PhoenixPortSoap11BindingOperation * operation;

/**
 * Contains SOAPFault object if present in the answer.
 */
@property (nonatomic) SOAPFault * soapFault;

/**
 * Result code of the waiting task.
 */
@property (nonatomic) int waitRes;

/**
 * Desired number of answers in the response.
 * If is -1, do not check number of answers.
 * Otherwise number of answers has to match this number.
 */
@property (nonatomic) int desiredAnswers;

/**
 * If non-nil, the body is required to contain the response of this class.
 */
@property (nonatomic) Class desiredBody;

/**
 * Timeout value for waiting for async task to complete.
 */
@property (nonatomic) int timeoutSec;

/**
* Flag says if this task was timed out.
*/
@property (nonatomic) BOOL timeoutDetected;
@property (nonatomic) PEXSoapTaskErrorEnum taskError;

/**
 * Number of milliseconds to wait for semaphore to signal.
 * The shorter this interval is, the more frequently is cancellation checked, but the more busy CPU is.
 */
@property (nonatomic) uint64_t semMilliWait;

/**
 * Whether to log SOAP XML.
 * Default: NO.
 */
@property (nonatomic) BOOL logXML;

/**
 * Conformance to protocol to catch SOAP response from underlying component.
 */
- (void) operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response;

/**
 * Prepares SOAP binding with the given identity.
 */
- (void) prepareSOAP: (PEXUserPrivate * ) privData;

/**
 * Returns current binding, used for operation initialization.
 * Has to be called after prepareSOAP.
 */
- (PhoenixPortSoap11Binding*) getBinding;
@end