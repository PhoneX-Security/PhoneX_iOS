//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFileSelectRestrictor.h"

@implementation PEXSelectionDescriptionInfo

@end

@implementation PEXFileSelectRestrictor {

}

- (void)setSelectedFiles:(NSArray *)selectedFiles
{
    _selectedFiles = selectedFiles;
    [self selectionChanged];
}

- (PEXSelectionDescriptionStatus) overlaps {
    return PEX_SELECTION_DESC_STATUS_ERROR;
}

- (void)selectionChanged {
    // NOOP
}

- (PEXSelectionDescriptionInfo *)getCurrentStateDescription {
    return nil;
}


@end