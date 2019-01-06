//
//  PEXGuiFilesNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 05/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileSelectNavigationController.h"
#import "PEXGuiFileNavigationController_Protected.h"

#import "PEXGuiImageView.h"

#import "PEXGuiFileSelectAndPreviewVisitor.h"
#import "PEXGuiContactsSelectController.h"

#import "PEXGuiFileSelectionBar.h"
#import "PEXGuiSelectContactsNavigationController.h"

#import "PEXSelectedFileContainer.h"
#import "PEXGuiFactory.h"
#import "PEXGuiFileCategoriesController.h"
#import "PEXGuiFileBySelection.h"
#import "PEXLicenceManager.h"
#import "PEXReport.h"
#import "PEXFileRestrictorManager.h"
#import "PEXService.h"


@interface PEXGuiFileSelectNavigationController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    @private
    bool _withContacts;
    bool _showSelected;
}
@property (nonatomic) PEXFilePickManager * manager;
@property (nonatomic) PEXGuiFileSelectionBar * selectionBar;
@property (nonatomic) PEXGrandSelectionManager * grandManager;

@property (nonatomic) PEXGuiController * showedController;
@property (nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation PEXGuiFileSelectNavigationController

- (id) initWithViewTitle: (NSString * const) title
           selectWithContacts: (const bool) withContacts
                 grandManager: (PEXGrandSelectionManager *) grandManager
{

    PEXFilePickManager * const manager = [[PEXFilePickManager alloc] init];

    // TODO
    // this will make some crazy stuff when the FIle selection
    // allows back and forth, e.g will be after som other selection/composition
    if (grandManager.selectedFileContainers != nil)
    {
        for (NSURL * const url in grandManager.selectedFileContainers) {
            PEXFileData * const data = ([PEXGuiFileUtils isAssetUrl:url]) ?
                    [PEXFileData assetFileDataFromUrl:url] :
                    [PEXFileData fileDataNonAssetFromPath:url.path];

            // does the file exist?
            if (data)
                [manager addFile:data];
        }
    }

    // Show only preselected files if any

    PEXGuiFileCategoriesController * const controller = [[PEXGuiFileCategoriesController alloc] init];

    // INIT
    self = [super initWithViewController:controller title:title];

    _showSelected = ([manager getSelectedFilesCount] > 0);
    _withContacts = withContacts;
    self.manager = manager;
    self.grandManager = grandManager;

    [self.grandManager addController:self];

    controller.navigation = self;

    return self;
}

- (void) showByPhotos
{
    [self showCategory:[[PEXGuiFileByPhotosController alloc] initWithVisitor:[[PEXGuiFileSelectVisitor alloc]
                                                             initWithManager: self.manager]]];
}

- (void) showByPhonex
{
    [self showCategory:[[PEXGuiFileByPhonexController alloc] initWithVisitor:[[PEXGuiFileSelectAndPreviewVisitor alloc]
                                                                              initWithManager: self.manager]]];
}

- (void) showBySelected
{
    [self showCategory:[[PEXGuiFileBySelection alloc] initWithVisitor:[[PEXGuiFileSelectAndPreviewVisitor alloc]
            initWithManager: self.manager] preselectedFiles:[self.manager getSelectedFiles]]];
}

- (void) showNewPhoto
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    imagePickerController.showsCameraControls = YES;
    self.imagePickerController = imagePickerController;

    [self.fullscreener presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"FileSelection";

    self.selectionBar = [[PEXGuiFileSelectionBar alloc] initWithRightActionImage:[[PEXGuiImageView alloc] initWithImage:
                         (_withContacts ? PEXImg(@"contact_book") : PEXImg(@"send"))]];

    [self.mainView addSubview:self.selectionBar];
}

- (void) initContent
{
    [super initContent];

    //[self setSize:0LL];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU moveToBottom:self.selectionBar];
    [PEXGVU scaleHorizontally:self.selectionBar];
}

- (void) secondaryButtonClicked
{
    [self.showedController dismissViewControllerAnimated:true completion:nil];
}

// USER WANTS TO DELETE SELECTED FILES
- (void) primaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_FILE_SELECT_DELETE_FILES];
    [self.showedController dismissViewControllerAnimated:true completion:^{

        NSArray * selectedFiles = [[self.manager getSelectedFiles] copy];
        for (const PEXFileData * file in selectedFiles)
        {
            // do not try to remove Photos assets
            if (!file.isAsset)
            {
                [self.manager removeFile:file];
                NSError * error;
                bool result = [[NSFileManager defaultManager] removeItemAtURL:file.url error:&error];
            }
        }

        // TODO this is pure garbage
        if (![self.showedCategoryController isKindOfClass:[PEXGuiFileByPhotosController class]])
            [self.showedCategoryController reloadContentAsync];
    }];
}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;

    [self.selectionBar.B_clearSelection addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_SELECTION_CLEAR];
        [weakSelf.manager clearSelection];
    }];

    [self.selectionBar.B_deleteSelection addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_SELECTION_DELETE];
        weakSelf.showedController = [PEXGuiFactory showBinaryDialog:weakSelf
                                                           withText:PEXStr(@"txt_delete_selected_files")
                                                           listener:weakSelf
                                                      primaryAction:PEXStrU(@"B_delete") secondaryAction:nil];
    }];

    // Limit checking & notification block.
    BOOL (^checkIfPassesLimitsBlock)() = ^BOOL {
        if (![self.manager notifyErrorIfOverlaps]) {
            return YES;
        }

        const int64_t availableFiles =
                [PEXFileRestrictorFactory getAvailableFileCountForPermissions:[PEXFileRestrictorFactory getFilesPermissions]];

        NSUInteger selectedFilesNum = self.manager.getSelectedFilesCount;
        if ((availableFiles != -1) && (availableFiles < (selectedFilesNum)))
        {
            [PEXGrandSelectionManager showNotEnoughFilesToSpend:availableFiles parent:self];
        }

        return NO;
    };

    [self.selectionBar.B_next addActionBlock:
     (_withContacts ?
      ^{
          [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_SELECTION_NEXT];
          if (!checkIfPassesLimitsBlock()){
              return;
          }

          // fill in file URIS from selected file data
          [self fillGrandManagerWithSelectedUrls];

          // show contacts:
          PEXContactSelectManager * const manager = [[PEXContactSelectManager alloc] init];

          PEXGuiContactsSelectController * const contactListController =
          [[PEXGuiContactsSelectController alloc] initWithManager:manager];

          PEXGuiSelectContactsNavigationController * const contactSelectNavgation =
          [[PEXGuiSelectContactsNavigationController alloc] initWithViewController:contactListController title:PEXStrU(@"L_select_contacts") manager:manager
             grandManager:self.grandManager];

          [contactSelectNavgation prepareOnScreen:self];
          [contactSelectNavgation show:self];
      } :
      ^{
          [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_SELECTION_NEXT];
          if (!checkIfPassesLimitsBlock()){
              return;
          }

          [self fillGrandManagerWithSelectedUrls];

          [self.grandManager finish];
      })
    ];
}

- (void) fillGrandManagerWithSelectedUrls
{
    NSMutableArray * const result = [[NSMutableArray alloc] init];

    for (PEXFileData * const fileData in [self.manager getSelectedFiles])
        [result addObject:[PEXSelectedFileContainer containerFromFileData:fileData]];

    self.grandManager.selectedFileContainers = result;
}

- (void) initState
{
    [super initState];

    [self.manager addListener:self];

    if (_showSelected)
        [self showBySelected];
}

- (void) setStaticSize
{
    [super setStaticSize];

    [self staticHeight: self.staticHeight + [PEXGuiFileSelectionBar staticHeight]];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.manager deleteListener:self];
    self.manager = nil;
    [self.grandManager removeController:self];
    self.grandManager = nil;

    [super dismissViewControllerAnimated:flag completion:completion];
}


// FILE SELECTION LISTENER

- (void) setRestrictors: (NSArray * const) restrictorResults
{
    [self.selectionBar setRestrictions:restrictorResults];
}

- (void) fileAdded: (const PEXFileData * const) asset at:(const NSUInteger)position
{
    [self selectionChanged];
}

- (void) fileRemoved: (const PEXFileData * const) asset at:(const NSUInteger)position
{
    [self selectionChanged];
}

- (void)notifyOverlapError
{
    [self.selectionBar notifyError];
}

- (void) clearSelection
{
    [self setRestrictors:self.manager.restrictorResults];
}

- (void) fillIn: (NSArray * const) files
{
    [self selectionChanged];
}

- (void)selectionChanged
{
    [self setRestrictors:self.manager.restrictorResults];
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSInteger counter = [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_APPLICATION_PHOTO_COUNTER
                                                              defaultValue:PEX_PREF_APPLICATION_PHOTO_COUNTER_DEFAULT];

    // Store image to a file.
    NSString * transferPath = [PEXGuiFileUtils getFileTransferPath];
    NSString * fileName = [NSString stringWithFormat:@"photo_%04ld.jpg", (long)counter];
    NSString * newPhotoPath = [transferPath stringByAppendingPathComponent:fileName];

    NSData *jpgData = UIImageJPEGRepresentation(image, 0.90);
    [jpgData writeToFile:newPhotoPath atomically:YES];
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_APPLICATION_PHOTO_COUNTER value:counter+1];

    // Add new file to the selection.
    PEXFileData * data = [PEXFileData fileDataNonAssetFromPath:newPhotoPath];

    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        [weakSelf.manager addFile:data];
    }];

    // Redirect to the stored
    [picker dismissViewControllerAnimated:YES completion:^{
        [PEXService executeOnMain:YES block:^{
            [weakSelf showByPhonex];
        }];
    }];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
}

@end
