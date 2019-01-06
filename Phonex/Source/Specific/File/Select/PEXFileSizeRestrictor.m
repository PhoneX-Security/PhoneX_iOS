//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFileSizeRestrictor.h"
#import "PEXFileData.h"
#import "PEXGuiFileUtils.h"

@interface PEXFileSizeRestrictor ()
{
@private
    uint64_t _selectedSize;
}

@property (nonatomic, assign) uint64_t maxSizeInBytes;

@end

@implementation PEXFileSizeRestrictor {

}

- (id) init
{
    self = [self initWithMaxSizeInBytes:0ULL];

    _selectedSize = 0;

    return self;
}

- (id) initWithMaxSizeInBytes: (const uint64_t) maxSize
{
    self = [super init];

    self.maxSizeInBytes = maxSize;

    return self;
}

- (void) calculateSelectedSize
{
    uint64_t result = 0LL;

    if (self.selectedFiles)
    {
        for (const PEXFileData *const file in self.selectedFiles)
            result += file.size;
    }

    _selectedSize = result;
}

- (uint64_t) getSelectedFilesSize
{
    return _selectedSize;
}

// SUPER OVERRIDE

- (void) selectionChanged
{
    [self calculateSelectedSize];
}

- (PEXSelectionDescriptionStatus) overlaps
{
    return (_selectedSize > self.maxSizeInBytes) ?
            PEX_SELECTION_DESC_STATUS_TOO_LARGE : (_selectedSize <= 0) ?
                    PEX_SELECTION_DESC_STATUS_TOO_SMALL :
                    PEX_SELECTION_DESC_STATUS_OK;
}

- (PEXSelectionDescriptionInfo *) getCurrentStateDescription
{
    PEXSelectionDescriptionInfo * const result = [[PEXSelectionDescriptionInfo alloc] init];

    result.textDescription = [NSString stringWithFormat:@"%@ / %@",
                    [[PEXGuiFileUtils bytesToRepresentation:_selectedSize] description],
                    [[PEXGuiFileUtils bytesToRepresentation:self.maxSizeInBytes] description]];

    result.overlaps = [self overlaps];

    return result;
}

@end