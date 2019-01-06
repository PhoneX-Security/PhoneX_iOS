//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PEXSOAPSSLManager;


@interface PEXRestRequester : NSObject<NSURLSessionTaskDelegate>
@property(nonatomic) PEXSOAPSSLManager * tlsManager;

/**
 * Queue delegate calls will be called on.
 * By default it is the main queue.
 */
@property(nonatomic) NSOperationQueue * delegateQueue;
@property(nonatomic) NSError * opError;

/**
 * Initializes delegateQueue to the separate queue.
 */
- (void) defaultQueueInit;

/**
 * Initializes default trust verifier.
 * Uses AppState private data.
 */
- (void) defaultTrustInit;

/**
 * Returns default NSURLSessionConfiguration.
 */
- (NSURLSessionConfiguration *) defaultConfiguration;

/**
 * To be called when NSURLTask finishes.
 */
- (void) processFinished: (NSData *) data resp: (NSURLResponse *) response error: (NSError *) rerror;
- (bool) codeSatisfies: (const int) code;
- (NSString *) encodeString: (NSString *) str;
@end