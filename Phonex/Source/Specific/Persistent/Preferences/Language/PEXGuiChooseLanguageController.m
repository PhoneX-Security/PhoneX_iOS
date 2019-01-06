//
//  PEXGuiChooseLanguageController.m
//  Phonex
//
//  Created by Matej Oravec on 14/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiChooseLanguageController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"

#import "PEXResStrings.h"
#import "PEXGuiDetailView.h"

#import "PEXGuiControllerDecorator.h"

#import "PEXGuiCircleView.h"

@interface PEXGuiChooseLanguageController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;
@property (nonatomic) NSString * selectedLanguage;

@end

@implementation PEXGuiChooseLanguageController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ChooseLanguage";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}


- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) selectLanguageView: (UIView * const) languageView
                   language: (NSString * const) language
{
    [self.selectorView removeFromSuperview];
    [languageView addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedLanguage = language;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self initLanguages];
    }];
}

- (void) initLanguages
{
    NSString * const currentLanguage = [[PEXAppPreferences instance]
            getStringPrefForKey:PEX_PREF_APPLICATION_LANGUAGE_KEY defaultValue:PEX_LANGUAGE_SYSTEM];

    const NSArray * const languages = [_PEXStr getLanguages];
    const NSUInteger lastIndex = languages.count;
    for (NSUInteger i = 0; i < lastIndex; ++i)
    {
        [self addLanguage:languages[i]
          currentLanguage:currentLanguage
                   modify:nil];
    }
}

- (void) addLanguage: (NSString * const) language
     currentLanguage: (NSString * const) currentLanguage
              modify: (SEL) selectorOnLanguageView
{
    PEXGuiDetailView * const languageView = [[PEXGuiDetailView alloc] init];
    if (selectorOnLanguageView)
        [languageView performSelector:selectorOnLanguageView];

    [languageView setName:language];
    [languageView setValue:[_PEXStr getLanguageDescription:language]];
    [self.linearView addView:languageView];
    [PEXGVU scaleHorizontally:languageView];

    __weak const PEXGuiChooseLanguageController * const weakSelf = self;
    __weak UIView * const weakLanguageView = languageView;
    [languageView addActionBlock:^{
        [weakSelf selectLanguageView:weakLanguageView language:language];
    }];

    if ([currentLanguage isEqualToString:language])
    {
        [self selectLanguageView:languageView language:language];
    }
}


- (NSString *) getSelectedLanguage
{
    return self.selectedLanguage;
}

- (void) initBehavior
{
    [super initBehavior];
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
        [_PEXStr getLanguages].count * [PEXGuiDetailView staticHeight];
    
    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}

@end
