//
// Created by Matej Oravec on 01/11/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiHorizontalPanRecognizerHelper.h"

@interface PEXGuiHorizontalPanRecognizerHelper ()
{
    // init with
    CGFloat _maxPan;
    CGFloat _halfPan;
    CGFloat _closed;
    CGFloat _open;

    CGPoint _panLastDelta;
    CGFloat _viewLastX;
    bool _moveIt;

}

@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) UIView<UIGestureRecognizerDelegate> *view;

@end

@implementation PEXGuiHorizontalPanRecognizerHelper {

}

- (id) initWithView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>  * const) view
             maxPan: (const CGFloat) maxPan
{
    self = [super init];

    _maxPan = maxPan;
    _open = -maxPan;
    _halfPan = maxPan / 2.0f;
    _closed = 0.0f;
    _viewLastX = 0.0f;

    self.view = view;
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panThisCell:)];
    self.panRecognizer.delegate = self.view;
    [view addGestureRecognizer:self.panRecognizer];

    return self;
}

- (void)panThisCell:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {

        case UIGestureRecognizerStateBegan:
            _panLastDelta = [recognizer translationInView:self.view];
            break;

        case UIGestureRecognizerStateChanged: {
            CGPoint currentPanDelta = [recognizer translationInView:self.view];

            const CGFloat absY = fabsf(currentPanDelta.y);

            // show it as sideways pan condition:
            if ((fabsf(currentPanDelta.x) > absY) && (absY < (self.view.frame.size.height / 2.0f)))
            {
                const CGFloat diff = currentPanDelta.x - _panLastDelta.x;

                if ((diff > 0.0f) && (self.view.frame.origin.x + diff > _closed))
                {
                    [PEXGVU set:self.view x:_closed];
                    _moveIt = false;
                }
                else if ((diff < 0.0f) && (self.view.frame.origin.x + diff < _open))
                {
                    [PEXGVU set:self.view x:_open];
                    _moveIt = false;
                }
                else
                {
                    [PEXGVU moveHorizontally:self.view by:diff];
                    _moveIt = true;
                }
            }
                // if not then if it was moved then move it back to its original place
            else
            {
                if (_moveIt) {
                    [self animateToPosition:_viewLastX];
                }
                _moveIt = false;
            }

            _panLastDelta = currentPanDelta;
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self panFinished];
            break;
        case UIGestureRecognizerStateCancelled:
            [self panFinished];
            break;
        default:
            break;
    }
}

- (void) panFinished
{
    if (_moveIt)
    {
        if (self.view.frame.origin.x > -_halfPan)
            [self animateToPosition:_closed];
        else
            [self animateToPosition:_open];
    }
}

- (void) animateToPosition: (const CGFloat) x
{
    _viewLastX = x;
    [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
        [PEXGVU set:self.view x:x];
    }];
}

- (void) reset
{
    [PEXGVU set:self.view x:_closed];
}

@end