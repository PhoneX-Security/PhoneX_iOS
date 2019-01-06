//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiMessageTextComposerView : UITextView<UITextViewDelegate>

@property (nonatomic) NSString * placeholder;

- (void) warningFlash;

@end