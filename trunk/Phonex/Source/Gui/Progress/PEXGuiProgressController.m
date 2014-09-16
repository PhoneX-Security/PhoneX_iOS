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
#import "PEXTaskFakeEvents.h"

#import "PEXResColors.h"
#import "PEXResValues.h"
#import "PEXGuiViewUtils.h"

// TODO make general ... see taskProgressed:

@interface PEXGuiProgressController ()

@property (nonatomic) UILabel *L_Title;
@property (nonatomic) PEXGuiProgressBar *PV_Progress;
@property (nonatomic) PEXTask * task;

@end

@implementation PEXGuiProgressController

- (id) initWithTask: (PEXTask * const) task
{
    self = [super init];

    self.task = task;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.PV_Progress = [[PEXGuiProgressBar alloc] init];
    [self.mainView addSubview: self.PV_Progress];

    self.L_Title = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"fontSizeMedium") fontColor:PEXCol(@"blackLow")];
    [self.mainView addSubview:self.L_Title];
}

- (void) initContent
{
    [super initContent];

    self.L_Title.text = PEXDefaultStr;
    self.PV_Progress.progress = 0.0f;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU centerVertically:self.PV_Progress];
    [PEXGVU scaleHorizontally:self.PV_Progress withMargin:PEXVal(@"contentMarginLarge")];

    [PEXGVU move:self.L_Title above:self.PV_Progress withMargin:PEXVal(@"distanceNormal")];
    [PEXGVU centerHorizontally:self.L_Title];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.task addListener:self];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [PEXGVU setWidth:self.mainView to:[parent subviewMaxWidth]];
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:100];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       [self.task start];
                   });
}

// TASK STUFF

- (void) taskStarted: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self setTitle: @"Processing ..."];
                   });
}
- (void) taskEnded: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self setTitle: @"Ended"];
                   });
}

- (void) taskProgressed: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       self.PV_Progress.progress = [((PEXTaskFakeEventProgress *) event) progress];
                   });
}

- (void) taskCancelStarted: (const PEXTaskEvent * const) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self setTitle: @"Cancelling ..."];
                       [self.PV_Progress setCancelling];
                   });
}

- (void) taskCancelEnded: (const PEXTaskEvent * const) event
{
}

- (void) taskCancelProgressed: (const PEXTaskEvent * const) event
{
}

- (void) setTitle: (NSString * const) title
{
    self.L_Title.text = title;
    [PEXGVU centerHorizontally: self.L_Title];
}

@end
