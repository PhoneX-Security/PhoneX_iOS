//
//  PEXGuiCLickableView.m
//  Phonex
//
//  Created by Matej Oravec on 02/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiClickableView.h"
#import "PEXGuiClickableView_Protected.h"

@interface PEXGuiClickableView ()

//@property (nonatomic, copy) ActionBlock actionBlock;
@property(nullable, nonatomic) NSMutableArray * tapRecognizers;
@property(nullable, nonatomic) NSMutableArray * longRecognizers;
@property(nonatomic) NSRecursiveLock * recLock;
@end

@implementation PEXGuiClickableView

- (id) init
{
    self = [super init];

    self.enabled = true;
    self.userInteractionEnabled = YES;
    self.tapRecognizers = [[NSMutableArray alloc] init];
    self.longRecognizers = [[NSMutableArray alloc] init];
    self.recLock = [[NSRecursiveLock alloc] init];
    return self;
}

- (void) addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    [super addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.enabled = self.enabled;
}

#include "DisableableStub.h"

-(void) addAction:(id)target action:(SEL)action
{
    [self.recLock lock];
    @try {
        UITapGestureRecognizer * rec = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
        rec.numberOfTapsRequired = 1;

        [self addTapRecognizerInternal:rec isLong:NO isSet:NO];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addActionBlock:(void(^)(void))block
{
    [self addActionBlock:block removePrevious:NO];
}

-(void) setActionBlock:(void(^)(void))block
{
    [self addActionBlock:block removePrevious:YES];
}

-(void) addActionBlock:(void(^)(void))block removePrevious: (BOOL) removePrevious {
    [self.recLock lock];
    @try {
        PEXGuiBlockGestureRecognizer *rec = [[PEXGuiBlockGestureRecognizer alloc] initWithBlock:block];
        rec.numberOfTapsRequired = 1;

        [self addTapRecognizerInternal:rec isLong:NO isSet:removePrevious];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addLongActionBlock:(void(^)(void))block
{
    [self addLongActionBlock:block removePrevious:NO];
}

-(void) setLongActionBlock:(void(^)(void))block
{
    [self addLongActionBlock:block removePrevious:YES];
}

-(void) addLongActionBlock:(void(^)(void))block removePrevious: (BOOL) removePrevious {
    [self.recLock lock];
    @try {
        PEXGuiLongBlockGestureRecognizer * rec = [[PEXGuiLongBlockGestureRecognizer alloc] initWithBlock: block];
        rec.minimumPressDuration = 0.5;

        [self addTapRecognizerInternal:rec isLong:YES isSet:removePrevious];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addTapRecognizerInternal: (UIGestureRecognizer * const) recognizer isLong:(BOOL) longClick isSet: (BOOL) set
{
    if (!recognizer){
        DDLogError(@"Null recognizer");
        return;
    }

    if (longClick){
        if (set){
            for (UIGestureRecognizer * const recognizer2del in self.longRecognizers) {
                [self removeGestureRecognizer:recognizer2del];
            }
            [self.longRecognizers removeAllObjects];
        }

        [self.longRecognizers addObject:recognizer];
    } else {
        if (set){
            for (UIGestureRecognizer * const recognizer2del in self.tapRecognizers) {
                [self removeGestureRecognizer:recognizer2del];
            }
            [self.tapRecognizers removeAllObjects];
        }

        [self.tapRecognizers addObject:recognizer];
        for(UIGestureRecognizer * longRec in self.longRecognizers){
            if (longRec) {
                [recognizer requireGestureRecognizerToFail:longRec];
            }
        }
    }

    [self addGestureRecognizer:recognizer];
}

- (void) clearActions
{
    [self.recLock lock];
    @try {
        for (UIGestureRecognizer * const recognizer in self.gestureRecognizers) {
            [self removeGestureRecognizer:recognizer];
        }
        [self.longRecognizers removeAllObjects];
        [self.tapRecognizers removeAllObjects];
    } @finally {
        [self.recLock unlock];
    }
}

@end
