//
//  PEXGuiProgressController.m
//  Phonex
//
//  Created by Matej Oravec on 26/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiProgressController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiControllerDecorator.h"

#import "PEXGuiClassicLabel.h"
#import "PEXGuiProgressBar.h"
#import "PEXTask.h"

#import "PEXGuiActivityIndicatorView.h"

@interface PEXGuiProgressController ()

@property (nonatomic) UILabel *L_Title;
@property (nonatomic) PEXGuiProgressBar *PV_Progress;
@property (nonatomic) PEXTask * task;
@property (nonatomic) PEXGuiActivityIndicatorView * activityIndicatorView;

@end

@implementation PEXGuiProgressController

- (void)setTheTask: (PEXTask * const) task
{
    self.task = task;
}

- (id) init
{
    self = [super init];

    self.showProgressBar = true;

    return self;
}

- (id) initWithTask: (PEXTask * const) task
{
    self = [self init];

    self.task = task;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.PV_Progress = [[PEXGuiProgressBar alloc] init];
    [self.mainView addSubview: self.PV_Progress];

    self.L_Title = [[PEXGuiBaseLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium") fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview:self.L_Title];

    self.activityIndicatorView=[[PEXGuiActivityIndicatorView alloc] init];
    [self.mainView addSubview:self.activityIndicatorView];

    [self.PV_Progress setHidden:!self.showProgressBar];
}

- (void) initContent
{
    [super initContent];

    self.L_Title.text = PEXStr(@"L_processing");
    self.PV_Progress.progress = 0.0f;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU centerVertically:self.PV_Progress];
    [PEXGVU scaleHorizontally:self.PV_Progress withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU move:self.L_Title above:self.PV_Progress withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU scaleHorizontally:self.L_Title withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU move:self.activityIndicatorView below:self.PV_Progress withMargin:PEXVal(@"dim_size_medium")];
    [PEXGVU centerHorizontally:self.activityIndicatorView];
}

- (void) initBehavior
{
    [super initBehavior];

    self.L_Title.textAlignment = NSTextAlignmentCenter;
    [self.task addListener:self];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [PEXGVU setWidth:self.mainView to:[parent subviewMaxWidth]];
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:PEXVal(@"progress_dialog_height")];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.activityIndicatorView startAnimating];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        [self.task start];
    });
}

// TASK STUFF

- (void) showTaskStarted: (const PEXTaskEvent * const) event
{
    [self setTitle:PEXStr(@"L_processing")];
}
- (void) taskStarted: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskStarted:event];
                   });
}

- (void) showTaskEnded: (const PEXTaskEvent * const) event {}
- (void) taskEnded: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskEnded:event];
                   });
}

- (void) showTaskProgressed: (const PEXTaskEvent * const) event {}
- (void) taskProgressed: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskProgressed:event];
                   });
}

// TODO always set cancelling?
- (void) showTaskCancelStarted: (const PEXTaskEvent * const) event {[self.PV_Progress setCancelling];}
- (void) taskCancelStarted: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskCancelStarted:event];
                   });
}

- (void) showTaskCancelEnded: (const PEXTaskEvent * const) event {}
- (void) taskCancelEnded: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskCancelEnded:event];
                   });
}

- (void) showTaskCancelProgressed: (const PEXTaskEvent * const) event {}
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self showTaskCancelProgressed:event];
                   });
}

- (void) setTitle: (NSString * const) title
{
    self.L_Title.text = title;
    [PEXGVU centerHorizontally: self.L_Title];
}

- (void) setProgress: (const float) progress
{
    self.PV_Progress.progress = progress;
}

@end
