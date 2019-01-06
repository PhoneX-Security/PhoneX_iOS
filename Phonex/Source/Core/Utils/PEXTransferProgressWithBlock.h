//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTransferProgress.h"

typedef enum {
    PEX_FT_PROGRESSUPD_UPDATE_PROGRESS,
    PEX_FT_PROGRESSUPD_SET_TOTAL,
    PEX_FT_PROGRESSUPD_SET_TOTAL_OPS,
    PEX_FT_PROGRESSUPD_SET_CUR_OP,
    PEX_FT_PROGRESSUPD_SET_TOTAL_SUB_OPS,
    PEX_FT_PROGRESSUPD_SET_CUR_SUB_OPS,
    PEX_FT_PROGRESSUPD_RESET
} PEXFtProgressType;

typedef void (^TransferProgressBlock)(PEXFtProgressType progType, NSNumber * a, NSNumber * b);
typedef void (^UpdateProgressBlock)(NSNumber * partial, double total);
typedef void (^SetTotalBlock1)(NSNumber * partial, double total);
typedef void (^SetTotalBlock2)(double total);
typedef void (^NumBlock)(NSNumber * total);

@interface PEXTransferProgressWithBlock : PEXTransferProgress
@property (nonatomic, copy) UpdateProgressBlock progressBlock;
@property (nonatomic, copy) TransferProgressBlock generalBlock;

- (instancetype)initWithProgressBlock:(UpdateProgressBlock)progressBlock;
+ (instancetype)blockWithProgressBlock:(UpdateProgressBlock)progressBlock;

/**
* Resets current progress.
*/
-(void) setTotal: (NSNumber *) partial total: (long) total;

/**
* Can set total number of some units that need to be processed.
*/
-(void) setTotal: (long) total;

/**
* Set total number of operations.
* @param totalOps
*/
-(void) setTotalOps: (NSNumber *) totalOps;

/**
* Set current operation.
* @param op
*/
-(void) setCurOp: (NSNumber *) op;

/**
* Set total number of sub operations in current operation.
* @param totalSubOps
*/
-(void) setTotalSubOps: (NSNumber *) totalSubOps;

/**
* Set current sub-operation.
* @param op
*/
-(void) setCurSubOp: (NSNumber *) subOp;

/**
* Can set total number of some units that need to be processed.
*/
-(void) reset;

@end