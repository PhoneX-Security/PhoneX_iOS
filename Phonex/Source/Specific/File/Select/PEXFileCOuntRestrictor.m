//
// Created by Matej Oravec on 24/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFileCountRestrictor.h"

@interface PEXFileCountRestrictor ()
{
@private
    int64_t _currentCount;
}

@property (nonatomic, assign) int64_t maxFilesCount;

@end

@implementation PEXFileCountRestrictor {

}

- (id) init
{
    self = [self initWithMaxCount:0];

    _currentCount = 0;

    return self;
}

- (id) initWithMaxCount: (const int64_t) maxCount
{
    self = [super init];

    self.maxFilesCount = maxCount;

    return self;
}

// SUPER OVERRIDE

- (void) selectionChanged
{
    _currentCount = self.selectedFiles.count;
}

- (PEXSelectionDescriptionStatus) overlaps
{
    return (_currentCount > self.maxFilesCount) ?
            PEX_SELECTION_DESC_STATUS_TOO_MANY_FILES : (_currentCount <= 0) ?
                    PEX_SELECTION_DESC_STATUS_TOO_FEW_FILES :
                    PEX_SELECTION_DESC_STATUS_OK;
}

- (PEXSelectionDescriptionInfo *) getCurrentStateDescription
{
    PEXSelectionDescriptionInfo * const result = [[PEXSelectionDescriptionInfo alloc] init];

    result.textDescription = [NSString stringWithFormat:@"%lld / %lld",
                                                        _currentCount,
                                                        self.maxFilesCount];

    result.overlaps = [self overlaps];

    return result;
}

@end