//
//  PEXGuiSelectContactsNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectContactsNavigationController.h"
#import "PEXGuiAppNavigationController_Protected.h"

#import "PEXGuiSelectionBar.h"

#import "PEXGuiImageView.h"
#import "PEXLicenceManager.h"
#import "PEXReport.h"
#import "PEXService.h"

@interface PEXGuiSelectContactsNavigationController ()

@property (nonatomic) PEXContactSelectManager * manager;
@property (nonatomic) PEXGuiSelectionBar * selectionBar;

@property (nonatomic) PEXGrandSelectionManager * grandManager;

@end


@implementation PEXGuiSelectContactsNavigationController

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title
                      manager: (PEXContactSelectManager * const) manager
                 grandManager: (PEXGrandSelectionManager * const) grandManager;
{
    self = [super initWithViewController:controller title:title];

    self.manager = manager;
    self.grandManager = grandManager;
    [self.grandManager addController:self];

    return self;
}

//- (PEXContactSelectManager)

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.selectionBar = [[PEXGuiSelectionBar alloc] initWithRightActionImage:[[PEXGuiImageView alloc] initWithImage:PEXImg(@"send") ]];

    [self.mainView addSubview:self.selectionBar];
}

- (void) initContent
{
    [super initContent];

    [self setCount:0u];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU moveToBottom:self.selectionBar];
    [PEXGVU scaleHorizontally:self.selectionBar];
}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;
    [self.selectionBar.B_clearSelection addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_SELECT_CLEAR];
        [weakSelf.manager clearSelection];
    }];


    [self.selectionBar.B_next addActionBlock:
      ^{
          [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_SELECT_NEXT];
          if ([[[PEXService instance] licenceManager] checkPermissionsAndShowGetPremiumInParent:weakSelf])
              return;

          weakSelf.grandManager.recipients = [weakSelf.manager getSelected];
          [weakSelf.grandManager finish];
      }
     ];
}

- (void) initState
{
    [super initState];

    [self.manager addListener:self];
}

- (void) setStaticSize
{
    [super setStaticSize];

    [self staticHeight: self.staticHeight + [PEXGuiSelectionBar staticHeight]];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.manager deleteListener:self];
    self.manager = nil;
    [self.grandManager removeController:self];
    self.grandManager = nil;

    [super dismissViewControllerAnimated:flag completion:completion];
}

// LISTENER


- (void) contactAdded: (const PEXDbContact * const) contact
{
    [self contactsModified];
}

- (void) contactRemoved: (const PEXDbContact * const) contact
{
    [self contactsModified];
}

- (void) clearSelection
{
    [self setCount:0u];
}

- (void) fillIn: (NSArray * const) files
{
    [self contactsModified];
}

- (void) contactsModified
{
    [self setCount:[self.manager getSelectedCount]];
}

- (void) setCount: (const NSUInteger) count
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.selectionBar setPrimaryLabelText:[NSString stringWithFormat:@"%d", (int)count]];
        [self.selectionBar setEnabled:count != 0u];
    });
}

@end
