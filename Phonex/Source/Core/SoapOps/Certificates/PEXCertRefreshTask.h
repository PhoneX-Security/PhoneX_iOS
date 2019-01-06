//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"
#import "PEXSubTask.h"
#import "PEXTaskFinishedEvent.h"

@class PEXCertRefreshTaskState;
@class PEXUserPrivate;
@class PEXCertRefreshParams;
@class PEXDbContentProvider;
@class PEXCertRefreshResult;
@class PEXCertificate;
@class PEXDbUserCertificate;
@class hr_certificateWrapper;
@class hr_getCertificateRequest;
@protocol PEXCanceller;
@class PEXX509;

/**
* How often should be performed valid certificate re-check? (default 3 minutes)
*/
FOUNDATION_EXPORT double CERTIFICATE_OK_RECHECK_PERIOD;

/**
* How often should be performed invalid certificate re-check? (default 10 seconds)
*/
FOUNDATION_EXPORT double CERTIFICATE_NOK_RECHECK_PERIOD;

/**
* Minimum timeout for push certificate notifications (default 2 minutes).
*/
FOUNDATION_EXPORT double CERTIFICATE_PUSH_TIMEOUT;

/**
* Maximal number of push updates for one contact in 24 hours.
*/
FOUNDATION_EXPORT long CERTIFICATE_PUSH_MAX_UPDATES;

/**
* Certificate refresh task.
* Suitable for certificate refresh for one destination server. Multiple servers are not supported yet.
* TODO: refactor SOAP destination.
*/
@interface PEXCertRefreshTask : NSObject <PEXTaskListener>

/**
* Task state.
* Contains request, response, progress.
*/
@property(nonatomic) PEXCertRefreshTaskState * state;

/**
* User private data used for SOAP call.
*/
@property(nonatomic) PEXUserPrivate * privData;

/**
* Content provider to use.
* If nil, is initialized to a default one.
*/
@property(nonatomic) PEXDbContentProvider * cr;

/**
* If NO, no progress monitoring will be performed.
*/
@property(nonatomic) BOOL doProgressMonitoring;

/**
* Canceller object.
*/
@property(nonatomic) id<PEXCanceller> canceller;

/**
* Domain destination for SOAP call.
*/
@property(nonatomic) NSString * domain;

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;
+ (instancetype)taskWithPrivData:(PEXUserPrivate *)privData;

/**
* Initialize task with private data and params.
*/
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData params: (PEXCertRefreshParams *) params;

/**
* Initialize task with private data and array of parameters.
*/
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData paramsArray: (NSArray *) params;

/**
* Initializes custom NSProgress for the whole refresh process.
* Overall progress has 2 children: {callProgress, processProgress}.
* Use this if you are interested in a monitoring of the whole process.
*/
-(void)prepareOverallProgress;

/**
* Initializes NSProgress for SOAP call monitoring.
* Use this if you are interested in the SOAP call progress monitoring only (no processing).
*/
-(void)prepareCallProgress;
-(NSProgress *)getOverallProgress;
-(NSProgress *)getCallProgress;

/**
* Send cancellation signal to the processing.
* Cancels all 3 progress objects if they exist.
*/
-(void) cancelRefresh;

/**
* Determines whether certificate re-check is needed.
* If yes, certificate is pre-loaded to the internal state of this
* object to continue with certificate refresh.
*
* Certificate may be old, missing or invalid.
*
* @return
*/
-(BOOL) isCertRefreshNeeded: (NSArray *) params results: (NSMutableDictionary *) results;

/**
* Constructs certificate refresh request from the local state.
* If there is 0 certificates to refresh, nil is returned since SOAP call is pointless.
*/
-(hr_getCertificateRequest *) prepareRequestFromState;

/**
* Blocking SOAP call with defined GetCertificateRequest.
* Response, error codes are stored in internal state.
*/
-(void) soapRequest: (hr_getCertificateRequest *) certRequest;

/**
* Prepares progress objects.
*/
-(void) prepareState;

/**
* Certificate request is constructed from parameters stored in internal state and soapRequest is called.
*/
-(void) doRequest;

/**
* Processes one certificate record from the server.
* Updates status in-memory certificate records, if there are such.
* Updates certificate database.
*
* Uses internal state.
*/
-(void) processOneResponseRecord: (hr_certificateWrapper *) wr;

/**
* Process certificate fetch response stored in the state.
*/
-(void) doProcessResponse;

/**
* Wrapper for the whole certificate refresh process.
* Used when async nature, cancellation and detailed progress monitoring is not important.
*/
-(void) refreshCertificates;

-(PEX_TASK_FINIHED_STATE) getFinishedState;
-(BOOL) didLoadedValidCertificateForUser: (NSString *) user;
-(PEXCertRefreshResult *) getResultForUser: (NSString *) user;
-(PEXCertificate *) getResultCertificate: (NSString *) user;
-(PEXDbUserCertificate *) getResultDBCertForUser: (NSString *) user;

@end