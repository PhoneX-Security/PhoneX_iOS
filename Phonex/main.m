
//
//  main.m
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXAppDelegate.h"
#import "PEXResStrings_JustOnce.h"
#import "PEXResValues_JustOnce.h"
#import "PEXResColors_JustOnce.h"
#import "PEXTheme_JustOnce.h"
#import "PEXCryptoUtils.h"
#import "PEXDatabase.h"
#import "PEXService.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        int resCode = 0;
        @try {
            //Preferences
            [PEXAppPreferences initInstance];

            //Theme
            [PEXTheme initTheme];

            // Resource init
            [PEXResStrings initStrings];
            [PEXResValues initValues];
            [PEXResColors initColors];

            // Singletons init
            [PEXUnmanagedObjectHolder initInstance];
            [PEXAppState initInstance];
            [PEXDateUtils initInstance];
            [PEXCryptoUtils initOpenSSL];
            [PEXDatabase initInstance];

            resCode = UIApplicationMain(argc, argv, nil, NSStringFromClass([PEXAppDelegate class]));
        } @catch(NSException * e){
            // Last minute logging.
            [PEXService uncaughtException:e fromUncaughtHandler:NO];
            @throw;
        }

        return resCode;
    }
}
