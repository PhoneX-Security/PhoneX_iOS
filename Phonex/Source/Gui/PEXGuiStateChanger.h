//
//  PEXGuiStateChanger.h
//  Phonex
//
//  Created by Matej Oravec on 06/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXGuiStateChanger <NSObject>

-(void) setStateNormal;
-(void) setStateHighlight;

@end
