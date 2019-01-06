//
//  PEXGuiPinLockController.m
//  Phonex
//
//  Created by Matej Oravec on 01/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPinLockController.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiPinLockMainView.h"
#import "PEXGuiPinLockButton.h"
#import "PEXGuiLinearScalingView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiCircleView.h"
#import "PEXReport.h"

static const int INPUT_LENGTH = 4;
static const int DIGITS = 10;

@interface PEXGuiPinLockController ()
{
    @private
    bool _visibleDismissButton;
    volatile bool _finished;
    volatile int _inputIndex;
}

@property (nonatomic) NSMutableArray * numberViews;
@property (nonatomic) PEXGuiPinLockButton * B_delete;
@property (nonatomic) PEXGuiPinLockButton * B_callDismiss;

@property (nonatomic) PEXGuiLinearContainerView * B_rowOne;
@property (nonatomic) PEXGuiLinearContainerView * B_rowTwo;
@property (nonatomic) PEXGuiLinearContainerView * B_rowThree;
@property (nonatomic) PEXGuiLinearContainerView * B_rowFour;

@property (nonatomic) PEXGuiClassicLabel * L_warning;
@property (nonatomic) UIView * V_upperBackground;
@property (nonatomic) NSMutableArray * circleViews;

@property (nonatomic) NSMutableString * result;
@property (nonatomic) NSLock * inputLock;

@end

@implementation PEXGuiPinLockController

- (id) init
{
    self = [super init];

    self.result = [[NSMutableString alloc] init];
    self.inputLock = [[NSLock alloc] init];
    _visibleDismissButton = false;

    return self;
}

- (id) initWithDismissButton
{
    self = [self init];

    _visibleDismissButton = true;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"PinLock";

    self.V_upperBackground = [[UIView alloc] init];
    [self.mainView addSubview:self.V_upperBackground];

    self.L_warning = [[PEXGuiClassicLabel alloc] init];
    [self.V_upperBackground addSubview:self.L_warning];

    self.circleViews = [[NSMutableArray alloc] initWithCapacity:INPUT_LENGTH];
    for (int i = 0; i < INPUT_LENGTH; ++i)
    {
        PEXGuiCircleView * const circleView = [[PEXGuiCircleView alloc] initWithDiameter:PEXVal(@"dim_size_medium")];
        [self.circleViews addObject:circleView];
        [self.V_upperBackground addSubview:circleView];
    }

    // BUTTONS

    self.numberViews = [[NSMutableArray alloc] initWithCapacity:DIGITS];

    self.B_rowFour = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
    [self.mainView addSubview:self.B_rowFour];

    self.B_callDismiss = [[PEXGuiPinLockButton alloc] initWithText:PEXStrU(@"L_clear")];
    [self.B_rowFour addView:self.B_callDismiss];

    PEXGuiPinLockButton * const B_zero =
        [[PEXGuiPinLockButton alloc] initWithText:@"0"];
    [self.B_rowFour addView:B_zero];
    [self.numberViews addObject:B_zero];

    self.B_delete = [[PEXGuiPinLockButton alloc] initWithText:PEXStrU(@"L_delete")];
    [self.B_rowFour addView:self.B_delete];

    [self generateNumberButtonsFrom:1 to:3 in:&_B_rowOne];
    [self generateNumberButtonsFrom:4 to:6 in:&_B_rowTwo];
    [self generateNumberButtonsFrom:7 to:9 in:&_B_rowThree];
}

- (void) generateNumberButtonsFrom: (const int) from
                                to: (const int) to
                                in: (PEXGuiLinearContainerView * __strong *) container
{
    *container = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
    [self.mainView addSubview:*container];
    const int upperBound = to + 1;
    for (int i = from; i < upperBound; ++i)
    {
        PEXGuiPinLockButton * const button =
            [[PEXGuiPinLockButton alloc] initWithText:[NSString stringWithFormat:@"%d", i]];
        [self.numberViews addObject:button];
        [*container addView:button];
    }
}

- (void) initContent
{
    [super initContent];

    self.V_upperBackground.backgroundColor = PEXCol(@"white_normal");
}

- (void) initBehavior
{
    [super initBehavior];

    __weak PEXGuiPinLockController * const weakSelf = self;

    NSArray * const numberViews = self.numberViews;
    const int size = numberViews.count;
    for (int i = 0; i < size; ++i)
    {
        [((PEXGuiPinLockButton *) numberViews[i]) addActionBlock:^{
            [PEXReport logUsrButton:PEX_EVENT_BTN_PIN_NUM];
            const int j = i;
            [weakSelf addNumber:j];
        }];
    }

    [self.B_delete addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_PIN_DELETE];
        [weakSelf deleteNumber];
    }];

    [self.B_callDismiss addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_PIN_DISMISS];
        [weakSelf.inputLock lock];
        [weakSelf enable:false];
        [weakSelf.pinLockListener dismissCalled];
        [weakSelf.inputLock unlock];
    }];
}

- (void) setText: (NSString * const) text
{
    self.L_warning.text = text;
    [PEXGVU centerHorizontally:self.L_warning];
}

- (void) inactiveate: (UIView * const) view
{
    view.backgroundColor = PEXCol(@"light_gray_high");
}

- (void) activeate: (UIView * const) view
{
    view.backgroundColor = PEXCol(@"orange_normal");
}

- (void) addNumber: (const int) number
{
    // more buttons at once can be clicked
    bool notify = false;
    NSString * result;

    [self.inputLock lock];
    if ((!_finished) && (_inputIndex < INPUT_LENGTH))
    {
        [self.result appendString:[NSString stringWithFormat: @"%d", number]];
        [self activeate:self.circleViews[_inputIndex]];
        ++_inputIndex;

        if (_inputIndex == INPUT_LENGTH)
        {
            [self enable:false];
            _finished = true;
            notify = true;
            result = [self.result copy];
        }
    }
    [self.inputLock unlock];

    if (notify)
        [self.pinLockListener pinLockSet:result];
}

- (void) deleteNumber
{
    [self.inputLock lock];

    if (!_finished && (_inputIndex > 0))
    {
        --_inputIndex;
        [self.result deleteCharactersInRange:NSMakeRange(_inputIndex, 1)];
        [self inactiveate:self.circleViews[_inputIndex]];
    }

    [self.inputLock unlock];
}

- (void) clear
{
    [self.inputLock lock];

    _finished = false;
    [self clearOnlyInMutex];

    [self.inputLock unlock];
}

- (void) clearInternal
{
    [self.inputLock lock];

    [self clearOnlyInMutex];

    [self.inputLock unlock];
}

- (void) clearOnlyInMutex
{
    if (!_finished)
    {
        _inputIndex = 0;
        [self.result setString:@""];
        for (UIView * const view in self.circleViews)
        {
            [self inactiveate:view];
        }

        [self enable:true];
    }
}

- (void) enable: (const bool) enable
{
    for (PEXGuiPinLockButton * const view in self.numberViews)
    {
        [view setEnabled:enable];
    }

    [self.B_callDismiss setEnabled:enable];
    [self.B_delete setEnabled:enable];
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat upperBgHeight = (2 * PEXVal(@"dim_size_large")) + // paddings
                                  (2 * PEXVal(@"dim_size_medium")) + // warning text size + default circle size
                                  PEXVal(@"dim_size_small");

    [PEXGVU setHeight:self.V_upperBackground to:upperBgHeight];
    [PEXGVU scaleHorizontally:self.V_upperBackground];
    [PEXGVU moveToTop:self.V_upperBackground];

    [PEXGVU centerHorizontally:self.L_warning];
    [PEXGVU moveToTop:self.L_warning withMargin:PEXVal(@"dim_size_large")];

    const CGFloat delimiterX = PEXVal(@"dim_size_tiny");
    const int halfCount = INPUT_LENGTH / 2;
    const CGFloat neededAtLeast = (halfCount * PEXVal(@"dim_size_medium")) +
                                  (halfCount * delimiterX);
    const CGFloat halfLength = neededAtLeast +  ((INPUT_LENGTH % 2) == 0 ?
                                                             0 :
                                                             (PEXVal(@"dim_size_medium") / 2.0f));
    UIView * const firstCircle = self.circleViews[0];
    [PEXGVU move:firstCircle below:self.L_warning withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU set:firstCircle x:(self.V_upperBackground.frame.size.width / 2.0f) - halfLength];

    for (int i = 1; i < INPUT_LENGTH; ++i)
    {
        UIView * const circle = self.circleViews[i];
        [PEXGVU move:circle below:self.L_warning withMargin:PEXVal(@"dim_size_small")];
        [PEXGVU move:circle rightOf:self.circleViews[i - 1] withMargin:delimiterX];
    }

    // NUMBERS

    const CGFloat height = self.mainView.frame.size.height;
    const CGFloat rowHeight = ((height - upperBgHeight) / 4.0f) - 1.0f;

    [PEXGVU setHeight:self.B_rowFour to:rowHeight];
    [PEXGVU scaleHorizontally:self.B_rowFour];
    [PEXGVU moveToBottom:self.B_rowFour];

    [PEXGVU setHeight:self.B_rowThree to:rowHeight];
    [PEXGVU scaleHorizontally:self.B_rowThree];
    [PEXGVU move:self.B_rowThree above:self.B_rowFour withMargin:1.0f];

    [PEXGVU setHeight:self.B_rowTwo to:rowHeight];
    [PEXGVU scaleHorizontally:self.B_rowTwo];
    [PEXGVU move:self.B_rowTwo above:self.B_rowThree withMargin:1.0f];

    [PEXGVU setHeight:self.B_rowOne to:rowHeight];
    [PEXGVU scaleHorizontally:self.B_rowOne];
    [PEXGVU move:self.B_rowOne above:self.B_rowTwo withMargin:1.0f];
}

- (void) initState
{
    [super initState];

    [self.B_callDismiss setHidden: !_visibleDismissButton];

    [self clear];
}

- (UIView *) getMainView
{
    return [[PEXGuiPinLockMainView alloc] init];
}


@end
