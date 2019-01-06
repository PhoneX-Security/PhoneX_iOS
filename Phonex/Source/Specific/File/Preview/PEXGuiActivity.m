//
//  PEXGuiActivity.m
//  Phonex
//
//  Created by Matej Oravec on 10/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiActivity.h"
#import "PEXGuiShieldManager.h"

@implementation PEXGuiActivity

- (void)performActivity
{
    if (!self.activityController){
        [self activityDidFinish:YES];
        return;
    }

    //  Check to see if it's presented via popover
    if ([self.activityController respondsToSelector:@selector(dismissPopoverAnimated:)])
    {
        /*
        [self.activityController dismissPopoverAnimated:YES];
        [((UIPopoverController *)self.activityController).delegate
         popoverControllerDidDismissPopover:self.activityController];

        [self present];*/

        [NSException raise:@"iPad" format:@"iPad not yet supported"];
    }
    else if([self.activityController presentingViewController])
    {
        //  Not in popover, dismiss as if iPhone
        [self.activityController dismissViewControllerAnimated:YES completion:^(void)
        {
            [self present];
        }];
    }
    else
    {
        [self present];
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSUInteger count = 0;

    for (id activityItem in activityItems) {
        if ([self canPerformWithItem:activityItem])
            ++count;
    }

    return (count >= 1);
}

- (bool) canPerformWithItem: (const id) item { return false; }
- (void) present{}

@end
