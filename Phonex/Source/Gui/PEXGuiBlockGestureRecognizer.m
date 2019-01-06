//
//  PEXGuiBlockGestureRecognizer.m
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiClickInterface.h"

@interface PEXGuiBlockGestureRecognizer ()
@property (nonatomic, copy) dispatch_block_t actionBlock;
@end

@implementation PEXGuiBlockGestureRecognizer

- (id) initWithBlock: (void(^)(void))handler
{
    self = [super initWithTarget:self action:@selector(executeTheAction)];

    self.action = handler;

    return self;
}

- (void) executeTheAction
{
    if (self.actionBlock) {
        self.actionBlock();
    }
}

- (void)clearActions {
    self.actionBlock = nil;
}

- (void)setAction:(dispatch_block_t)action {
    self.actionBlock = action;
}

- (BOOL)hasAction {
    return self.actionBlock != nil;
}

@end

@interface PEXGuiLongBlockGestureRecognizer ()
@property (nonatomic, copy) dispatch_block_t actionBlock;
@end

@implementation PEXGuiLongBlockGestureRecognizer
- (id) initWithBlock: (void(^)(void))handler
{
    self = [super initWithTarget:self action:@selector(executeTheAction:)];
    self.action = handler;

    return self;
}

- (void) executeTheAction:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan && self.actionBlock) {
        self.actionBlock();
    }
}

- (void)clearActions {
    [self setAction:nil];
}

- (void)setAction:(dispatch_block_t)action {
    self.actionBlock = action;
}

- (BOOL)hasAction {
    return self.actionBlock != nil;
}

- (void) executeTheAction {
    if (self.actionBlock) {
        self.actionBlock();
    }
}

@end