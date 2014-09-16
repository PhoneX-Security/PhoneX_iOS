//
//  main.m
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXAppDelegate.h"
#import "PEXResStrings_JustOnce.h"
#import "PEXResValues_JustOnce.h"
#import "PEXResColors_JustOnce.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        
        [PEXResStrings initLanguage];
        [PEXResStrings initUnlocalizedStrings];
        [PEXResValues initValues];
        [PEXResColors initColors];
        
        // Set other style stuff like StatusBar STYLE
        
        
        NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString * versionBuildString = [NSString stringWithFormat:@"Version: %@ (%@)", appVersionString, appBuildString];
        NSLog(@"version and build: %@", versionBuildString);
                
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([PEXAppDelegate class]));
    }
}
