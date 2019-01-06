//
//  PEXGuiFileSelectVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileSelectVisitor.h"

#import "PEXFilePickManager.h"
#import "PEXGuiOpenInActivity.h"
#import "PEXGuiPreviewActivity.h"


@interface PEXGuiFileSelectAndPreviewVisitor :
    PEXGuiFileSelectVisitor<PEXGuiOpenInActivityDelegate, PEXGuiPreviewDelegate>

@end
