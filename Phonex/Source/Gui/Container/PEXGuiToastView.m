//
// Created by Dusan Klinec on 09.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiToastView.h"


@interface PEXGuiToastView ()
@property (strong, nonatomic, readonly) UILabel *textLabel;
@property (strong, nonatomic) dispatch_block_t completion;
@end

@implementation PEXGuiToastView
@synthesize textLabel = _textLabel;

float const ToastHeight = 50.0f;
float const ToastGap = 10.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, 5.0f, self.frame.size.width - 10.0f, self.frame.size.height - 10.0f)];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.numberOfLines = 2;
        _textLabel.font = [UIFont systemFontOfSize:13.0f];
        _textLabel.lineBreakMode = NSLineBreakByCharWrapping;
        [self addSubview:_textLabel];

    }
    return _textLabel;
}

- (void)setText:(NSString *)text
{
    _text = text;
    self.textLabel.text = text;
}

+ (void)showToastInParentView: (UIView *)parentView
                     withText:(NSString *)text
                 withDuration:(float)duration
               withCompletion:(dispatch_block_t) completion
{
    //Count toast views are already showing on parent. Made to show several toasts one above another
    int toastsAlreadyInParent = 0;
    for (UIView *subView in [parentView subviews]) {
        if ([subView isKindOfClass:[PEXGuiToastView class]])
        {
            toastsAlreadyInParent++;
        }
    }

    CGRect parentFrame = parentView.frame;

    float yOrigin = parentFrame.size.height - (70.0f + ToastHeight * toastsAlreadyInParent + ToastGap * toastsAlreadyInParent);

    CGRect selfFrame = CGRectMake(parentFrame.origin.x + 20.0f, yOrigin, parentFrame.size.width - 40.0f, ToastHeight);
    PEXGuiToastView *toast = [[PEXGuiToastView alloc] initWithFrame:selfFrame];

    toast.backgroundColor = [UIColor darkGrayColor];
    toast.alpha = 0.0f;
    toast.layer.cornerRadius = 4.0;
    toast.text = text;
    toast.completion = completion;

    [parentView addSubview:toast];

    [UIView animateWithDuration:0.4 animations:^{
        toast.alpha = 0.9f;
        toast.textLabel.alpha = 0.9f;
    }completion:^(BOOL finished) {
        if(finished){

        }
    }];


    [toast performSelector:@selector(hideSelf:) withObject:toast afterDelay:duration];
}

- (void)hideSelf: (PEXGuiToastView *) toast
{
    [UIView animateWithDuration:0.4 animations:^{
        self.alpha = 0.0;
        self.textLabel.alpha = 0.0;
    }completion:^(BOOL finished) {
        if(finished){
            [self removeFromSuperview];
            if (toast && toast.completion){
                toast.completion();
            }
        }
    }];
}
@end