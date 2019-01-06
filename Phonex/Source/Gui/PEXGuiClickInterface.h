//
//  PEXGuiBlockGestureRecognizer.h
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

@protocol PEXGuiBlockExecutor<NSObject>

-(void) addActionBlock:(void(^)(void))block;
-(void) addLongActionBlock:(void(^)(void))block;
- (void) clearActions;

@optional
-(void) setActionBlock:(void(^)(void))block;
-(void) setLongActionBlock:(void(^)(void))block;

@end

@protocol PEXGuiSelectorExecutor<NSObject>

-(void) addAction:(id)target action:(SEL)action;
- (void) clearActions;

@end

@interface PEXGuiBlockGestureRecognizer : UITapGestureRecognizer

- (id) initWithBlock: (dispatch_block_t) handler;
- (void) clearActions;
- (void) setAction: (dispatch_block_t) action;
- (BOOL) hasAction;
- (void) executeTheAction;
@end

@interface PEXGuiLongBlockGestureRecognizer : UILongPressGestureRecognizer

- (id) initWithBlock: (void(^)(void))handler;
- (void) clearActions;
- (void) setAction: (dispatch_block_t) action;
- (BOOL) hasAction;
- (void) executeTheAction;
@end
