//
//  PEXGuiContentLoaderController.m
//  Phonex
//
//  Created by Matej Oravec on 22/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContentLoaderController.h"
#import "PEXGuiContentLoaderController_Protected.h"

#import "PEXDbAppContentProvider.h"
#import "PEXGuiFullSizeBusyView.h"
#import "PEXGuiStatementView.h"

@interface PEXGuiContentLoaderController ()
{
@private
    bool _wasEmpty;
}

@property (nonatomic) PEXGuiFullSizeBusyView * loadIndicator;
@property (nonatomic) PEXGuiStatementView * emptyIndicator;

@end

@implementation PEXGuiContentLoaderController

- (id) init
{
    self = [super init];

    self.contentLock = [[NSLock alloc] init];
    self.guiLock = [[NSLock alloc] init];

    return self;
}

- (void) initGuiComponents
{
    [super initContent];

    self.emptyIndicator = [[PEXGuiStatementView alloc] initWithFontSize:PEXVal(@"dim_size_medium")
                                                              fontColor:PEXCol(@"light_gray_high")
                                                                bgColor:PEXCol(@"white_normal")];
    [self.mainView addSubview:self.emptyIndicator];
}

- (void) initContent
{
    [super initContent];

    self.emptyIndicator.text = PEXStrU(@"L_empty");
}

- (void) initState
{
    self.emptyIndicator.alpha = 0.0f;
    _wasEmpty = false;
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // cancel list loading
    _cancel = true;

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void) viewWillAppear:(BOOL)animated
{
    self.loadIndicator = [[PEXGuiFullSizeBusyView alloc]
                          initWithColor: PEXCol(@"white_normal")];

    CGRect frame = [self getContentView].frame;
    self.loadIndicator.frame = frame;
    [self.mainView addSubview:self.loadIndicator];
    [self.mainView bringSubviewToFront:self.loadIndicator];

    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadContentAsync];
}

- (void) reloadContentAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                   ^(void)
                   {
                       [self.contentLock lock];
                       [PEXGVU executeWithoutAnimations:^{
                           if (_cancel) { [self.contentLock unlock]; return;}
                           [self clearContent];

                           if (_cancel) { [self.contentLock unlock]; return;}
                           [self preload];

                           if (_cancel) { [self.contentLock unlock]; return;}
                           [self loadContent];

                           if (_cancel) { [self.contentLock unlock]; return;}
                           [self postload];
                       }];
                       [self.contentLock unlock];

                       if (_cancel) return;
                       dispatch_sync(dispatch_get_main_queue(), ^{
                           [UIView animateWithDuration:PEXVal(@"dur_short")
                                            animations:^{ self.loadIndicator.alpha = 0.0f; }
                                            completion:^(BOOL finished){
                                                [self.loadIndicator removeFromSuperview];
                                                self.loadIndicator = nil;
                                                [self postloadIndicatorDismissed];
                                            }];
                       });
                   });
}

- (void) preload {/* NOOP */}
- (void) postload {/* NOOP */}
- (void) postloadIndicatorDismissed {/* NOOP */}

- (void) loadContent{/* NOOP */}
- (void) clearContent{/* NOOP */}

- (const UIView *) getContentView{return nil;}
- (int) getItemsCount { return 0; }

- (void) checkEmpty
{
    if ([self getItemsCount] > 0)
    {
        if (_wasEmpty)
        {
            _wasEmpty = false;
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self getContentView].alpha = 1.0f;
                self.emptyIndicator.alpha = 0.0f;
            });
        }
    }
    else if (!_wasEmpty)
    {
        _wasEmpty = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            // todo do not always / optimize
            [self alignEmptyIndicator];
            [self.mainView bringSubviewToFront:self.emptyIndicator];
            //[self getContentView].alpha = 0.0f;
            self.emptyIndicator.alpha = 1.0f;
        });
    }
}

- (void) alignEmptyIndicator
{
    self.emptyIndicator.frame = [self getContentView].frame;
    self.emptyIndicator.textAlignment = NSTextAlignmentCenter;
}

@end