//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMessageArchiveExecutor.h"

#import "PEXGuiMessageArchiveSelectionController.h"
#import "PEXMessageArchiver.h"

@interface PEXMessageArchiveExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiMessageArchiveSelectionController * chooseController;

@end

@implementation PEXMessageArchiveExecutor {

}

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void)show
{
    self.chooseController = [[PEXGuiMessageArchiveSelectionController alloc] init];
    self.topController = [self.chooseController showInWindowWithTitle:self.parent
                                                                        title:PEXStrU(@"L_message_archive")
                                                           withBinaryListener:self];
    [super show];
}

- (void)secondaryButtonClicked
{
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    NSNumber * const selectedValue = [self.chooseController getSelectedValue];

    NSNumber * const previous = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                             defaultValue:PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT];

    // if the previous is nil and selected not nil
    // than the second clause returns dalse
    if ((previous != selectedValue) || ![previous isEqualToNumber: selectedValue])
    {
        [[PEXUserAppPreferences instance] setNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                                        value:selectedValue];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PEXMessageArchiver instance] setTimerInSeconds:selectedValue];
        });
    }

    [self dismissWithCompletion:nil];
}

@end