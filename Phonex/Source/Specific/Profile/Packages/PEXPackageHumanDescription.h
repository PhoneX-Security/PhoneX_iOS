//
// Created by Matej Oravec on 18/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPackage;
@class PEXPackageItem;
@class PEXGuiDetailsTextBuilder;


@interface PEXPackageHumanDescription : NSObject

@property (nonatomic) NSString * shortLabel;
@property (nonatomic) NSString * shortDescription;
@property (nonatomic) NSString * superDetail;
@property (nonatomic) NSString * localizedPrice;
@property (nonatomic) NSString * localizedDuration;

- (void) applyPackage: (const PEXPackage * const) package;

+ (void) buildPackageDescription: (NSArray *) packages builder: (PEXGuiDetailsTextBuilder * const) builder;

+ (NSString *)getApproprietText: (const PEXPackageItem * const) packageItem;
+ (void) appendApproprietText: (const PEXPackageItem * const) packageItem
                           to: (NSMutableString * const) constructedLabel;

@end