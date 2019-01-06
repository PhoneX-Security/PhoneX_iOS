//
// Created by Matej Oravec on 21/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPackageGenerator.h"
#import "PEXPackage.h"
#import "PEXPackageItem.h"


@implementation PEXPackageGenerator {

}

+ (NSArray *) ownedTarifs
{
    PEXPackage * p1 = [PEXPackageGenerator packageCalls];
    PEXPackage * p2 = [PEXPackageGenerator packageCalls];

    PEXPackage * p3 = [PEXPackageGenerator packageTansferNontransferable];
    PEXPackage * p5 = [PEXPackageGenerator packageTansferTarif];

    return @[p1, p2, p3, p5];
}

+ (NSArray *) availableTarifs
{
    PEXPackage * p1 = [PEXPackageGenerator packageCalls];
    PEXPackage * p2 = [PEXPackageGenerator packageCallsNontransferable];
    PEXPackage * p3 = [PEXPackageGenerator packageCallsTarif];

    PEXPackage * p4 = [PEXPackageGenerator packageTansfer];
    PEXPackage * p5 = [PEXPackageGenerator packageTansferNontransferable];
    PEXPackage * p6 = [PEXPackageGenerator packageTansferTarif];

    return @[p1, p2, p3, p4, p5, p6];
}

+ (PEXPackage *) packageCalls
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(60);
    item.descriptor = PEX_PACKAGE_ITEM_CALL_SECONDS;
    item.life = PEX_PACKAGE_ITEM_CONSUMABLE;
    item.anchor = PEX_PACKAGE_ITEM_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

+ (PEXPackage *) packageCallsNontransferable
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(60);
    item.descriptor = PEX_PACKAGE_ITEM_CALL_SECONDS;
    item.life = PEX_PACKAGE_ITEM_CONSUMABLE;
    item.anchor = PEX_PACKAGE_ITEM_NON_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

+ (PEXPackage *) packageCallsTarif
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(60);
    item.descriptor = PEX_PACKAGE_ITEM_CALL_SECONDS;
    item.life = PEX_PACKAGE_ITEM_TARIF;
    item.anchor = PEX_PACKAGE_ITEM_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

+ (PEXPackage *) packageTansfer
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(100);
    item.descriptor = PEX_PACKAGE_ITEM_FILES_COUNT;
    item.life = PEX_PACKAGE_ITEM_CONSUMABLE;
    item.anchor = PEX_PACKAGE_ITEM_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

+ (PEXPackage *) packageTansferNontransferable
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(100);
    item.descriptor = PEX_PACKAGE_ITEM_FILES_COUNT;
    item.life = PEX_PACKAGE_ITEM_CONSUMABLE;
    item.anchor = PEX_PACKAGE_ITEM_NON_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

+ (PEXPackage *) packageTansferTarif
{
    PEXPackage * const pexPackage = [[PEXPackage alloc] init];
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];

    item.value = @(100);
    item.descriptor = PEX_PACKAGE_ITEM_FILES_COUNT;
    item.life = PEX_PACKAGE_ITEM_TARIF;
    item.anchor = PEX_PACKAGE_ITEM_TRANSFERABLE;

    pexPackage.items = @[item];
    return pexPackage;
}

@end