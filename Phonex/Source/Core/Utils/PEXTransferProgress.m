//
// Created by Dusan Klinec on 15.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTransferProgress.h"


@implementation PEXTransferProgress {

}

- (void)updateTxProgress:(NSNumber *)partial total:(double)total {

}

/**
* Progress update for operation & suboperation. Returns number of bytes processed.
* Used if total number is not available.
*
* @param opIdx
* @param subOpIdx
* @param cur
*/
-(void) updateTxProgress:(NSNumber *) cur { }

/**
* Resets current progress.
*/
-(void) setTotal: (NSNumber *) partial total: (long) total{ }

/**
* Can set total number of some units that need to be processed.
*/
-(void) setTotal: (long) total{ }

/**
* Set total number of operations.
* @param totalOps
*/
-(void) setTotalOps: (NSNumber *) totalOps {}

/**
* Set current operation.
* @param op
*/
-(void) setCurOp: (NSNumber *) op { }

/**
* Set total number of sub operations in current operation.
* @param totalSubOps
*/
-(void) setTotalSubOps: (NSNumber *) totalSubOps {}

/**
* Set current sub-operation.
* @param op
*/
-(void) setCurSubOp: (NSNumber *) subOp { }

/**
* Can set total number of some units that need to be processed.
*/
-(void) reset { }

@end