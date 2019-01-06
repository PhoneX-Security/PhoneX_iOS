//
//  PEXGuiImageClickableView.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiImageClickableView.h"

@interface PEXGuiImageClickableView ()
{
    bool _enabled;
}

@property(nullable, nonatomic, copy) NSMutableArray<__kindof UIGestureRecognizer *> * tapRecognizers;
@property(nullable, nonatomic, copy) NSMutableArray<__kindof UIGestureRecognizer *> * longRecognizers;
@property(nonatomic) NSRecursiveLock * recLock;
@end

@implementation PEXGuiImageClickableView

- (id)init
{
    self = [super init];

    _enabled = false;
    self.userInteractionEnabled = YES;
    self.tapRecognizers = [[NSMutableArray alloc] init];
    self.longRecognizers = [[NSMutableArray alloc] init];
    self.recLock = [[NSRecursiveLock alloc] init];

    return self;
}

#include "DisableableStub.h"
#include "AnimationOnClickStub.h"

-(void) addAction:(id)target action:(SEL)action
{
    [self.recLock lock];
    @try {
        UITapGestureRecognizer * rec = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
        rec.numberOfTapsRequired = 1;

        [self addTapRecognizerInternal:rec isLong:NO];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addActionBlock:(void(^)(void))block
{
    [self.recLock lock];
    @try {
        PEXGuiBlockGestureRecognizer *rec = [[PEXGuiBlockGestureRecognizer alloc] initWithBlock:block];
        rec.numberOfTapsRequired = 1;

        [self addTapRecognizerInternal:rec isLong:NO];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addLongActionBlock:(void(^)(void))block
{
    [self.recLock lock];
    @try {
        PEXGuiLongBlockGestureRecognizer * rec = [[PEXGuiLongBlockGestureRecognizer alloc] initWithBlock: block];
        rec.numberOfTapsRequired = 1;

        [self addTapRecognizerInternal:rec isLong:YES];
    } @finally {
        [self.recLock unlock];
    }
}

-(void) addTapRecognizerInternal: (UIGestureRecognizer * const) recognizer isLong:(BOOL) longClick
{
    if (!recognizer){
        DDLogError(@"Null recognizer");
        return;
    }

    if (longClick){
        [self.longRecognizers addObject:recognizer];
    } else {
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
