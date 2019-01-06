//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTransferProgressWithBlock.h"


@implementation PEXTransferProgressWithBlock {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.progressBlock = nil;
    }

    return self;
}

- (instancetype)initWithProgressBlock:(UpdateProgressBlock)progressBlock {
    self = [self init];
    if (self) {
        self.progressBlock = progressBlock;
    }

    return self;
}

+ (instancetype)blockWithProgressBlock:(UpdateProgressBlock)progressBlock {
    return [[self alloc] initWithProgressBlock:progressBlock];
}

- (void)updateTxProgress:(NSNumber *)cur {
    if (_progressBlock == nil || cur == nil){
        return;
    }

    _progressBlock(nil, [cur doubleValue]);

    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_UPDATE_PROGRESS, nil, cur);
    }
}

- (void)updateTxProgress:(NSNumber *)partial total:(double)total {
    if (_progressBlock == nil){
        return;
    }

    _progressBlock(partial, total);

    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_UPDATE_PROGRESS, partial, @(total));
    }
}

/**
* Can set total number of some units that need to be processed.
*/
-(void) setTotal: (long) total{
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_TOTAL, nil, @(total));
    }
}

/**
* Resets current progress.
*/
-(void) setTotal: (NSNumber *) partial total: (long) total {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_TOTAL, partial, @(total));
    }
}

/**
* Set total number of operations.
* @param totalOps
*/
-(void) setTotalOps: (NSNumber *) totalOps {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_TOTAL_OPS, nil, totalOps);
    }
}

/**
* Set current operation.
* @param op
*/
-(void) setCurOp: (NSNumber *) op {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_CUR_OP, nil, op);
    }
}

/**
* Set total number of sub operations in current operation.
* @param totalSubOps
*/
-(void) setTotalSubOps: (NSNumber *) totalSubOps {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_TOTAL, nil, totalSubOps);
    }
}

/**
* Set current sub-operation.
* @param op
*/
-(void) setCurSubOp: (NSNumber *) subOp {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_SET_CUR_SUB_OPS, nil, subOp);
    }
}

/**
* Can set total number of some units that need to be processed.
*/
-(void) reset {
    // General block.
    if (_generalBlock != nil){
        _generalBlock(PEX_FT_PROGRESSUPD_RESET, nil, nil);
    }
}


@end