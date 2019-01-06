//
//  PEXGuiNotifiedTabView.h
//  Phonex
//
//  Created by Matej Oravec on 05/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiTabView.h"

#import "PEXGuiNotificationCounterView.h"

@interface PEXGuiNotifiedTabView : PEXGuiTabView

//TODO move both to protected
@property (nonatomic) PEXGuiNotificationCounterView * counter;
- (void) registerCounter;
- (void) unregisterCounter;

- (id)initWithImage:(UIView* const) image labelText:(NSString * const) label highlightImage:(UIView * const) hightlightImage;

@end
