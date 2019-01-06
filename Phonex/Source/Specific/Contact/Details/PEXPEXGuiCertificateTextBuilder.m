//
// Created by Matej Oravec on 08/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPEXGuiCertificateTextBuilder.h"


@implementation PEXGuiDetailsTextBuilder

- (id) init
{
    self = [super init];

    self.result = [[NSMutableAttributedString alloc] init];

    return self;
}

// TODO this is garbage

- (PEXGuiDetailsTextBuilder *)appendFirstLabel: (NSString * const)text
{
    return [self appendLabel:text first:YES];
}

- (PEXGuiDetailsTextBuilder *)appendFirstValue: (NSString * const)text
{
    return [self appendValue:text first:YES];
}

- (PEXGuiDetailsTextBuilder *) appendLabel: (NSString * const)text
{
    return [self appendLabel:text first:NO];
}

- (PEXGuiDetailsTextBuilder *) appendValue: (NSString * const) text
{
    return [self appendValue:text first:NO];
}

- (PEXGuiDetailsTextBuilder *)appendLabel:(NSString *const)text first:(BOOL)first {
    return [self appendLabel:text first:first fontSize:nil fontColor:NULL];
}

- (PEXGuiDetailsTextBuilder *)appendValue:(NSString *const)value first:(BOOL)first {
    return [self appendValue:value first:first fontSize:nil fontColor:NULL];
}

- (PEXGuiDetailsTextBuilder *)appendLabel:(NSString *const)text
                                    first:(BOOL)first
                                 fontSize:(NSNumber *)fontSize
                                fontColor:(UIColor *)fontColor
{
    return [self append:text
                  first:first
                isLabel:YES
               fontSize:fontSize
              fontColor:fontColor == NULL ? PEXCol(@"light_gray_low") : fontColor];
}

- (PEXGuiDetailsTextBuilder *)appendValue:(NSString *const)value
                                    first:(BOOL)first
                                 fontSize:(NSNumber *)fontSize
                                fontColor:(UIColor *)fontColor
{
    return [self append:value
                  first:first
                isLabel:NO
               fontSize:fontSize == nil ? @(PEXVal(@"dim_size_medium")) : fontSize
              fontColor:fontColor == NULL ? PEXCol(@"black_normal") : fontColor];
}

- (PEXGuiDetailsTextBuilder *)append:(NSString *const)text
                               first:(BOOL)first
                             isLabel:(BOOL)isLabel
                            fontSize:(NSNumber *)fontSize
                           fontColor:(UIColor *)fontColor
{
    NSMutableAttributedString * temp = nil;
    if (first){
        temp = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", text]];

    } else {
        temp = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:isLabel ? @"\n\n%@" : @"\n%@", text]];

    }

    if (fontSize != nil) {
        [temp addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:[fontSize floatValue]]
                     range:NSMakeRange(0, temp.length)];
    }

    if (fontColor != NULL) {
        [self setColor:temp color:fontColor];
    }

    [self.result appendAttributedString:temp];

    return self;
}

-(void) setColor: (NSMutableAttributedString * const) attributedString color: (UIColor *) color {
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:color
                             range:NSMakeRange(0, attributedString.length)];
}


@end
