//
//  PEXGuiDialogBinaryController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 18/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryController.h"
#import "PEXGuiDialogUnaryController_Protected.h"

#import "PEXGuiDialogBinaryVisitor.h"

@interface PEXGuiDialogBinaryController ()

@property (nonatomic) PEXGuiButtonDialogFirst * B_second;
@property (nonatomic) PEXGuiDialogBinaryVisitor * binaryVisitor;

@end
