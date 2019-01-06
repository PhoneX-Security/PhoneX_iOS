//
//  PEXGuiNotificationCounterView.m
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiNotificationCounterView.h"
#import "PEXGuiClassicLabel.h"

typedef enum PEXNotificationType_t {
    // Pseudo value
    PEX_NOTIFTYPE_MIN = 0,

    // Real values
    PEX_NOTIFTYPE_MESSAGE = 1,
    PEX_NOTIFTYPE_CALL,
    PEX_NOTIFTYPE_CONTACT,
    PEX_NOTIFTYPE_LICENCE,
    PEX_NOTIFTYPE_RECOVERY,
    PEX_NOTIFTYPE_ALL,

    // Pseudo value
    PEX_NOTIFTYPE_MAX,
}PEXNotificationType_t;

@interface PEXGuiNotificationCounterView () {
    NSInteger _counters[PEX_NOTIFTYPE_MAX];
}

@property (nonatomic) PEXGuiClassicLabel * L_count;

@end

@implementation PEXGuiNotificationCounterView

- (id) init
{
    self = [super initWithDiameter:PEXVal(@"dim_size_large")];

    self.backgroundColor = PEXCol(@"orange_normal");
    self.L_count = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                      fontColor:PEXCol(@"white_normal")];
    [self addSubview:self.L_count];
    for(int i=0; i<PEX_NOTIFTYPE_MAX; i++){
        _counters[i] = 0;
    }
    [self setCount:0 type:PEX_NOTIFTYPE_ALL];

    return self;
}

- (void) messageRepeatNotify:(const int)count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
    [self blob];
                   });
}

- (void) messageNotifications: (const int) count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
    [self setCount:count type:PEX_NOTIFTYPE_MESSAGE];
                   });
}

- (void) allRepeatNotify
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self blob];
                   });
}

- (void) callLogNotifications: (const int) count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self setCount:count type:PEX_NOTIFTYPE_CALL];
                   });
}

- (void)contactNotificationCountChanged:(const int)count {

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [self setCount:count type:PEX_NOTIFTYPE_CONTACT];
    });
}

- (void)licenceUpdateNotifications:(const int)count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [self setCount:count type:PEX_NOTIFTYPE_LICENCE];
    });
}

- (void)recoveryMailNotificationCountChanged:(const int)count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [self setCount:count type:PEX_NOTIFTYPE_RECOVERY];
    });
}

- (void) allNotifications: (const int) count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self setCount:count type:PEX_NOTIFTYPE_ALL];
                   });
}

- (void) allRepeatNotify: (const int) count
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self blob];
                   });
}

- (void) setCount: (const int) count type: (int) type
{
    if (type <= PEX_NOTIFTYPE_MIN || type >= PEX_NOTIFTYPE_MAX){
        [NSException raise:@"IllegalArgument" format:@"Unkown notification type"];
    }

    _counters[type] = count;
    NSInteger totalCount = 0;
    for(int i=0; i<PEX_NOTIFTYPE_MAX; i++){
        totalCount += _counters[i];
    }

    if (totalCount > 0)
    {
        self.hidden = NO;
        self.L_count.text = (totalCount < 99) ? [NSString stringWithFormat:@"%ld", (long)totalCount] : @"99";
        [PEXGVU center:self.L_count];
        [self blob];
    }
    else
    {
        self.hidden = YES;
    }
}

- (void) blob
{
    // there is some problem with resizing animation in center

                       [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
                           self.backgroundColor = PEXCol(@"orange_low");
                       } completion:^(BOOL finished){
                           [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
                               self.backgroundColor = PEXCol(@"orange_normal");
                           }];
                       }];
}


@end
