//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "PEXGuiTonesController.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiCircleView.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiTone.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiMuteNotificationController.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiTone.h"

@interface PEXGuiTonesController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;
@property (nonatomic) PEXGuiTone * selectedTone;
@property (nonatomic) NSRecursiveLock * playerLock;
@property (nonatomic) AVAudioPlayer * currentPlayer;

@end

@implementation PEXGuiTonesController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.playerLock = [[NSRecursiveLock alloc] init];
        self.currentPlayer = nil;
    }

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ChooseTone";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}

- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self prepareContent];
    }];
}

- (void)prepareContent
{
    NSString * const currentToneId = [[PEXUserAppPreferences instance] getStringPrefForKey:self.prefKey defaultValue:nil];
    const NSUInteger lastIndex = self.toneList.count;
    for (NSUInteger i = 0; i < lastIndex; ++i) {
        [self addEntry:self.toneList[i]
               current:currentToneId
             isDefault:i==0];
    }
}

- (void) selectView: (UIView * const) periodView entry: (PEXGuiTone * const) tone
{
    [self.selectorView removeFromSuperview];
    [periodView addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedTone = tone;
}

- (void) selectAndPlayView: (UIView * const) periodView entry: (PEXGuiTone * const) tone
{
    [self.selectorView removeFromSuperview];
    [periodView addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedTone = tone;

    // Play the sound
    [self.playerLock lock];
    [self stopPlayingInternal];
    self.currentPlayer = [tone play];
    [self.playerLock unlock];
}

- (PEXGuiTone *)getSelectedTone {
    return self.selectedTone;
}

- (void) stopPlaying {
    [self.playerLock lock];
    [self stopPlayingInternal];
    [self.playerLock unlock];
}

- (void) stopPlayingInternal {
    if (self.currentPlayer == nil){
        return;
    }

    @try {
        [self.currentPlayer stop];
    } @catch(NSException * e){
        DDLogError(@"Exception when stoppping current player %@", e);
    }

    self.currentPlayer = nil;
}

- (void) addEntry: (PEXGuiTone * const) tone
          current: (NSString * const) current
        isDefault: (BOOL) isDefault
{
    PEXGuiMenuItemView * const view =
            [[PEXGuiMenuItemView alloc] initWithImage:nil
                                            labelText:tone.toneName];

    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    WEAKSELF;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [weakSelf selectAndPlayView: weakView entry:tone];
    }];

    if (isDefault || (current && tone && tone.toneId && [tone.toneId isEqualToString:current]))
    {
        [weakSelf selectView:weakView entry:tone];
    }
}

- (void) initBehavior
{
    [super initBehavior];
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
            [_PEXStr getLanguages].count * [PEXGuiDetailView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}


@end