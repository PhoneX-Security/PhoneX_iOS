//
// Created by Matej Oravec on 22/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AssetsLibrary/AssetsLibrary.h>

/**
* The class manages access to the ALAssetsLibrar::init method.
*
* It handles following scenarios which may cause an app crash
* - multiple instances in multiple threads
* - concurrent usage
* - release during usage of dependent asset
* - too fast init -> release -> init
*
* The instance is being hold for @LIBRARY_KEEP_ALIVE_SECONDS after assetslibrary user are set to 0
*/
@interface PEXAssetLibraryManager : NSObject

/**
* Thread exclusive access: blocking until is called releaseAssetLibrary.
* ReleaseAssetLibrary should be called ASAP.
* Increments assetsLibrary users
*/
-(ALAssetsLibrary *) getAssetLibrary;

/**
* Releases lock created by getAssetLibrary.
* Decrements assetsLibrary users.
* Must be called after getAssetLibrary.
*
* Right before calling this method, nil-out all the pointers to the instance returned by getAssetLibrary
*/
-(void) releaseAssetLibrary;

/**
* Increments assetsLibrary users
*/
- (void) increment;

/**
* Decrements assetsLibrary users
*/
- (void) decrement;

+ (PEXAssetLibraryManager *) instance;

@end