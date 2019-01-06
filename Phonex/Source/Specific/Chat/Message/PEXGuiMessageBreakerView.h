//
//  PEXGuiMessageBreakerView.h
//  Phonex
//
//  Created by Matej Oravec on 30/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PEXGuiMessageBreakerView : UICollectionReusableView

- (void) initGuiStuff;
- (void) setText: (NSString * const)text;

+ (CGFloat) staticHeight;

@end
