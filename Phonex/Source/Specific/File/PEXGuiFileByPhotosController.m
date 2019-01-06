//
//  PEXGuiPhotosController.m
//  Phonex
//
//  Created by Matej Oravec on 11/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileByPhotosController.h"
#import "PEXGuiFileController_Protected.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "PEXGuiFileView.h"
#import "PEXAssetLibraryManager.h"

@interface PEXGuiFileByPhotosController ()
{
    volatile ALAuthorizationStatus _authStatus;
}

@end

@implementation PEXGuiFileByPhotosController

- (id) initWithVisitor: (PEXGuiFileControllerVisitor * const) visitor;
{
    self = [super initWithVisitor:visitor];

    return self;
}

- (void) loadContent
{
    [self loadAssets];
}

- (void) postload
{
    // TODO with semaphore
    //wait because asset loading is async by iOS' assets design
    while (!_finished)
    {
        [NSThread sleepForTimeInterval:0.1];
    }

    [[PEXAssetLibraryManager instance] releaseAssetLibrary];


    // then load super
    [super postload];
}

- (void) loadAssets
{
    [[PEXAssetLibraryManager instance] increment];

    //self.assetsGroups = [[NSMutableArray alloc] init];
    //self.assets = [[NSMutableArray alloc] init];
    // library stuff
    ALAssetsLibrary * const library = [[PEXAssetLibraryManager instance] getAssetLibrary];

    // ASYNC ... see doc of the method
    // All except stream ... streams cause on iOS 8.3 glitches in form of 'empty' files shown in list
    [library enumerateGroupsWithTypes:ALAssetsGroupAll ^ ALAssetsGroupPhotoStream
     // see
     // http://stackoverflow.com/questions/18901984/alassetslibrary-error-too-many-contexts-no-space-in-contextlist/23931779#23931779
     // ALAGroupLibrary does some trouble
     /*ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
     ALAssetsGroupFaces | ALAssetsGroupSavedPhotos*/
     //RESULT BLOCK
                           usingBlock:^void(ALAssetsGroup * group, BOOL *stop)
     {
         if (_cancel)
         {
             *stop = true;
             [self loadingFinished];
         }
         else if (!*stop)
         {
             ALAssetsFilter *const onlyPhotosFilter = [ALAssetsFilter allAssets];
             [group setAssetsFilter:onlyPhotosFilter];
             // ONLY NONEMPTY ASSEST GROUPS
             if (group) {
                 if ([group numberOfAssets] > 0) {
                     [self loadAssetsFromGroup:group];
                 }
             }
             else {
                 // end of iteration
                 [self loadingFinished];
             }
         }
     }
     //FAILURE
                         failureBlock:^(NSError *error)
     {
         _authStatus = [ALAssetsLibrary authorizationStatus];
         [self loadingFinished];
     }];
}

- (void) loadingFinished
{
    _finished = true;
}

- (void) loadAssetsFromGroup: (const ALAssetsGroup * const) assetGroup
{
    __block volatile int i = 0;
    [self dataLoadStarted];
    [assetGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset * asset, NSUInteger index, BOOL *stop)
     {
         if (_cancel)
         {
            *stop = true;
             [self loadingFinished];
         }
         else if (!*stop)
         {
             ++i;
             if (asset) {
                 ALAsset *assetRefCopy = asset;

                 PEXGuiItemHelper * const helper = [[PEXGuiItemHelper alloc] init];
                 helper.date = [assetRefCopy valueForProperty:ALAssetPropertyDate];
                 helper.url = assetRefCopy.defaultRepresentation.url;

                 [self addFileHelper:helper];
             }
             else {
                 _authStatus = [ALAssetsLibrary authorizationStatus];
                 DDLogDebug(@"unable to load asset %ld at %d", (long)_authStatus, i);
             }
         }
     }];
    [self dataLoadFinished];
}

- (void) tweakView: (PEXGuiFileView * const)fileView
{
    [super tweakView:fileView];

    fileView.enabled = false;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [[PEXAssetLibraryManager instance] decrement];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)initGuiComponents {
    [super initGuiComponents];
    self.screenName = @"FilesPhotos";
}


@end
