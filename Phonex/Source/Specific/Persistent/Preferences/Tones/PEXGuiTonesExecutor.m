//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiDialogBinaryListener.h"
#import "PEXGuiTonesExecutor.h"
#import "PEXGuiTonesController.h"
#import "PEXService.h"
#import "PEXGuiTone.h"

@interface PEXGuiTonesExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiTonesController *selectController;

@property(nonatomic) NSArray * toneList;

@property (nonatomic) NSString * prefKey;
@end

@implementation PEXGuiTonesExecutor

- (id)initWithParentController:(PEXGuiController *const)parent toneList:(NSArray *)toneList prefKey:(NSString *)prefKey
{
    self = [super init];

    self.parent = parent;
    self.prefKey = prefKey;
    self.toneList = toneList;

    return self;
}

- (void)show
{
    self.selectController = [[PEXGuiTonesController alloc] init];
    self.selectController.prefKey = self.prefKey;
    self.selectController.toneList = self.toneList;

    self.topController = [self.selectController showInWindowWithTitle:self.parent
                                                              title:PEXStrU(@"L_tone_select")
                                                 withBinaryListener:self];
    [super show];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self.parent viewDidReveal];
    [super dismissWithCompletion:completion];
}

- (void)secondaryButtonClicked
{
    [self.selectController stopPlaying];
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    [self.selectController stopPlaying];
    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:nil async:YES block:^{
        PEXGuiTone * const selected = [weakSelf.selectController getSelectedTone];
        [[PEXUserAppPreferences instance] setStringPrefForKey:self.prefKey value:selected.toneId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dismissWithCompletion:nil];
        });
    }];
}

@end