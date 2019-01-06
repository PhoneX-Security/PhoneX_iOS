//
// Created by Matej Oravec on 30/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiLinearRollingView.h"

@interface PEXGuiLinearScrollingView ()

@property (nonatomic) PEXGuiLinearRollingView * container;

@property (nonatomic) NSLock * lock;

@end

@implementation PEXGuiLinearScrollingView {

}

- (id) init
{
    self = [super init];

    self.showsVerticalScrollIndicator = YES;

    self.container = [[PEXGuiLinearRollingView alloc] init];
    [super addSubview:self.container];
    self.lock = [[NSLock alloc] init];

    return self;
}

- (int) count
{
    return self.container.count;
}

- (void) setFrame: (CGRect)frame
{
    [super setFrame:frame];
    self.contentSize = CGSizeMake(self.frame.size.width, self.contentSize.height);
    [PEXGVU setWidth:self.container to:self.frame.size.width];
}

- (NSUInteger) addView:(UIView * const) view
{
    //[self.lock lock];
    const NSUInteger result = [self.container addView:view];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (NSUInteger) addView:(UIView * const) view toPosition: (const NSUInteger) position;
{
    //[self.lock lock];
    const NSUInteger result = [self.container addView:view toPosition:position];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (UIView *) removeFirstView
{
    //[self.lock lock];
    UIView * const result = [self.container removeFirstView];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (UIView *) removeLastView
{
    //[self.lock lock];
    UIView * const result = [self.container removeLastView];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (UIView *) removeViewAtPosition:(const NSUInteger) index;
{
    //[self.lock lock];
    UIView * const result = [self.container removeViewAtPosition:index];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (UIView *) removeView:(UIView * const) view
{
    //[self.lock lock];
    UIView * const result = [self.container removeView:view];
    [self contentResized];
    //[self.lock unlock];
    return result;
}

- (void) contentResized
{
    self.contentSize = CGSizeMake(self.frame.size.width, self.container.frame.size.height);
}

- (void)viewRemoved:(const UIView *const)view fromPosition:(const NSUInteger)index {
}
- (void)viewAdded:(UIView *const)view toPosition:(const NSUInteger)index {
}

- (void) moveView: (UIView * const) view to: (const NSUInteger) to
{
    [self.container moveView:view to:to];
}

- (void) moveFrom: (const NSUInteger) from to: (const NSUInteger) to
{
    [self.container moveFrom:from to:to];
}

- (void) viewMoved: (UIView * const) view from: (const NSUInteger) from to: (const NSUInteger) to{

}

- (void) viewResized: (UIView * const) view byDiffY: (const CGFloat) diff
{
    [self.container viewResized:view byDiffY:diff];
    self.contentSize = CGSizeMake(self.frame.size.width, self.container.frame.size.height);
}


- (void) clear
{
    //[self.lock lock];
    [self.container clear];
    [self contentResized];
    //[self.lock unlock];
}

- (void) cleared{}


@end