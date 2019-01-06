//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiMessageTextComposerView.h"


@interface PEXGuiMessageTextComposerView ()
{
    bool _empty;
    bool _editing;
}

@property (nonatomic) UIColor * normalTextColor;
@property (nonatomic) UIColor * placeholderTextColor;

@end

@implementation PEXGuiMessageTextComposerView {

}

/*  TODO unite with the styles

FOR STYLE SEE PEXGuiTextField

AND PEXGuiMessageTextBodyView


*/

- (id)init
{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBeginEditing)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEndEditing)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];

    self.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
    self.backgroundColor = PEXCol(@"white_normal");
    self.normalTextColor= PEXCol(@"black_normal");
    self.placeholderTextColor = PEXCol(@"light_gray_normal");

    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [PEXCol(@"light_gray_high") CGColor];
    self.tintColor = PEXCol(@"black_normal");

    [self padding];

    //specific
    self.keyboardAppearance = [PEXTheme getKeyboardAppearance];
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeyDefault;

    self.editable = YES;
    [self resignFirstResponder];
    self.scrollEnabled = YES;
    [self setUserInteractionEnabled:YES];

    _editing = false;
    self.text = @"";

    return self;
}

- (void) padding
{
    [self setPadding:PEXVal(@"dim_size_medium")];
}

- (void) setPadding: (const CGFloat) padding
{
    self.textContainerInset = UIEdgeInsetsMake(padding, padding, padding, padding);
}

// TODO RESEARCH STATE MADNESS (empty, editing) and possible simplification

- (void)didBeginEditing
{
    if (_empty)
    {
        [super setText:@""];
        self.textColor = self.normalTextColor;
    }
    _editing = true;
    _empty = false;
}

- (void)didEndEditing
{
    if ([self textIsEmpty])
        [self setEmpty];
    else
        _empty = false;

    _editing = false;
}

- (void) setEmpty
{
    [super setText:self.placeholder];
    self.textColor = self.placeholderTextColor;
    _empty = true;
}

- (NSString *) text
{
    return (_empty ? @"" : [super text]);
}

- (bool) textIsEmpty
{
    return [[super text] isEqualToString:@""];
}

- (void) setText:(NSString *)text
{
    if ([text isEqualToString:@""] && !_editing)
    {
        [self setEmpty];
    }
    else
    {
        self.textColor = self.normalTextColor;
        _empty = false;
        [super setText:text];
    }
}

- (void) warningFlash
{
    UIColor * color = self.backgroundColor;
    [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
        self.backgroundColor = PEXCol(@"red_normal");

    } completion:^(BOOL finished){
        [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
            self.backgroundColor = color;
        }
         ];
    }];
}

@end