//
// Created by Matej Oravec on 08/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiDetailsTextBuilder : NSObject

@property (nonatomic) NSMutableAttributedString * result;

- (PEXGuiDetailsTextBuilder *) appendFirstLabel: (NSString * const) text;
- (PEXGuiDetailsTextBuilder *) appendFirstValue: (NSString * const)text;
- (PEXGuiDetailsTextBuilder *) appendLabel: (NSString * const) text;
- (PEXGuiDetailsTextBuilder *) appendValue: (NSString * const) value;

- (PEXGuiDetailsTextBuilder *) appendLabel: (NSString * const) text first: (BOOL) first;
- (PEXGuiDetailsTextBuilder *) appendValue: (NSString * const) value first: (BOOL) first;

- (PEXGuiDetailsTextBuilder *) appendLabel: (NSString * const) text
                                     first: (BOOL) first
                                  fontSize: (NSNumber *) fontSize
                                 fontColor: (UIColor *) fontColor;

- (PEXGuiDetailsTextBuilder *) appendValue: (NSString * const) value
                                     first: (BOOL) first
                                  fontSize: (NSNumber *) fontSize
                                 fontColor: (UIColor *) fontColor;;

- (PEXGuiDetailsTextBuilder *)append:(NSString *const)text
                               first:(BOOL)first
                             isLabel:(BOOL)isLabel
                            fontSize:(NSNumber *)fontSize
                           fontColor:(UIColor *)fontColor;

@end