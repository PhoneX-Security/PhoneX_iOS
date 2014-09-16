//
//  PEXGuiDialogBinaryVisitor_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 05/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryVisitor.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"

@interface PEXGuiDialogBinaryVisitor ()

@property (nonatomic, weak) PEXGuiDialogBinaryController * binaryController;

- (void) finishSecond;

@end
