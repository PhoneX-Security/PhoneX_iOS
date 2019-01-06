//
// Created by Matej Oravec on 18/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPackageHumanDescription.h"
#import "PEXPackage.h"
#import "PEXPackageItem.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiFileUtils.h"
#import "PEXGuiCallController.h"
#import "PEXUtils.h"
#import "PEXPEXGuiCertificateTextBuilder.h"


@implementation PEXPackageHumanDescription {

}

- (void) applyPackage: (const PEXPackage * const) package
{
    NSString * labelText = PEXStr(@"L_package");
    NSString * descriptionText = PEXStr(@"L_package_details_unavailable");
    NSString * detailText = PEXStr(@"L_package_details_unavailable");

    if (package.items.count)
    {
        NSMutableString * const constructedLabel = [[NSMutableString alloc] init];
        NSMutableString * const constructedDescription = [[NSMutableString alloc] init];
        NSMutableString * const constructedDetail = [[NSMutableString alloc] init];

        for (const PEXPackageItem * const packageItem in package.items)
        {
            if (![packageItem.value isEqualToNumber:@(-1)])
                [PEXPackageHumanDescription appendApproprietText:packageItem to:constructedLabel];
        }

        labelText = constructedLabel;
    }

    // Subscription period
    if (package.productType == PEXPackageSubscription
            && package.durationType != PEXPackageDurationNone
            && package.durationLength != nil
            && [package.durationLength integerValue] > 0)
    {
        NSInteger duration = [package.durationLength integerValue];
        if (package.durationType == PEXPackageDurationMonth){
            if (duration == 1){
                self.localizedDuration = PEXStr(@"L_month");
            } else {
                self.localizedDuration = [NSString stringWithFormat:@"%d %@", (int)duration, PEXStr(@"L_months")];
            }

        } else if (package.durationType == PEXPackageDurationYear){
            if (duration == 1){
                self.localizedDuration = PEXStr(@"L_year");
            } else {
                self.localizedDuration = [NSString stringWithFormat:@"%d %@", (int)duration, PEXStr(@"L_years")];
            }

        } else if (package.durationType == PEXPackageDurationWeek){
            if (duration == 1){
                self.localizedDuration = PEXStr(@"L_week");
            } else {
                self.localizedDuration = [NSString stringWithFormat:@"%d %@", (int)duration, PEXStr(@"L_weeks")];
            }

        }

    } else {
        self.localizedDuration = nil;
    }

    self.shortLabel = package.localizedTitle;
    self.shortDescription = package.localizedDescription;
    self.superDetail = package.localizedDescription;
    self.localizedPrice = package.localizedPrice;

    if ([PEXUtils isEmpty:self.shortLabel]){
        DDLogError(@"Empty product short label from licence server");
        self.shortLabel = package.product.localizedTitle;
    }

    if ([PEXUtils isEmpty:self.shortDescription]){
        DDLogError(@"Empty product description from licence server");
        self.shortDescription = package.product.localizedDescription;
    }

    if ([PEXUtils isEmpty:self.superDetail] && package.product != nil){
        self.superDetail = package.product.localizedDescription;
    }
}

+ (NSString *)getApproprietText: (const PEXPackageItem * const) packageItem
{
    NSMutableString * const result = [[NSMutableString alloc] init];
    [self appendApproprietText:packageItem to:result];
    return result;
}

+ (void) buildPackageDescription: (NSArray *) packages builder: (PEXGuiDetailsTextBuilder * const) builder {
    NSUInteger count = packages.count;
    for (NSUInteger i = 0; i < count; ++i)
    {
        PEXPackageItem * item = packages[i];
        const int64_t value = item.value.longLongValue;

        // Label
        [builder appendValue:[PEXPackageHumanDescription appendPackageText:item] first:i==0];
        [builder appendValue:@": " first:YES];

        // Unlimited
        if (value == -1) {
            [builder appendValue:PEXStr(@"L_unlimited") first:YES];
            continue;
        }

        // Zero - color
        UIColor * color = NULL;
        if (value == 0){
            color = PEXCol(@"red_normal");
        }

        // Inidivual unit rendering
        switch (item.descriptor)
        {
            case PEX_PACKAGE_ITEM_CALL_SECONDS: {
                [builder appendValue:[PEXGuiCallController getTimeIntervalStringFromTime:value]
                               first:YES
                            fontSize:nil
                           fontColor:color];
                break;
            }
            case PEX_PACKAGE_ITEM_FILES_COUNT: {
                [builder appendValue:[self filesTextByCount:value]
                               first:YES
                            fontSize:nil
                           fontColor:color];
                break;
            }

            case PEX_PACKAGE_ITEM_MESSAGES_COUNT:
            {
                [builder appendValue:[@(value) stringValue]
                               first:YES
                            fontSize:nil
                           fontColor:color];
                break;
            }

            default:
                break;
        }
    }
}

+ (NSString *) appendPackageText: (const PEXPackageItem * const) packageItem
{
    NSMutableString * const result = [[NSMutableString alloc] init];
    [self appendPackageText:packageItem to:result];
    return result;
}

+ (void) appendPackageText: (const PEXPackageItem * const) packageItem
                        to: (NSMutableString * const) constructedLabel
{
    switch (packageItem.descriptor)
    {
        case PEX_PACKAGE_ITEM_CALL_SECONDS: {
            [constructedLabel appendString:PEXStrU(@"L_calls")];
            break;
        }
        case PEX_PACKAGE_ITEM_FILES_COUNT: {
            [constructedLabel appendString:PEXStrU(@"L_files")];
            break;
        }

        case PEX_PACKAGE_ITEM_MESSAGES_COUNT: {
            [constructedLabel appendString:PEXStrU(@"L_messages")];
            break;
        }

        default:
        case PEX_PACKAGE_ITEM_UNKNOWN:break;
    }
}

+ (void) appendApproprietText: (const PEXPackageItem * const) packageItem
                           to: (NSMutableString * const) constructedLabel
{
    switch (packageItem.descriptor)
    {
        case PEX_PACKAGE_ITEM_CALL_SECONDS: {
            const int64_t value = packageItem.value.longLongValue;
            [self appendNamed:PEXStrU(@"L_calls")
                        value: value == -1 ? PEXStr(@"L_unlimited") :
                                [PEXGuiCallController getTimeIntervalStringFromTime:value]
                           to:constructedLabel];
            break;
        }
        case PEX_PACKAGE_ITEM_FILES_COUNT:
        {
            [self appendNamed:PEXStrU(@"L_files")
                        value:[self filesTextByCount:packageItem.value.longLongValue]
                           to:constructedLabel];
            break;
        }

        case PEX_PACKAGE_ITEM_MESSAGES_COUNT:
        {
            const int64_t value = packageItem.value.longLongValue;
            [self appendNamed:PEXStrU(@"L_messages")
                        value:value == -1 ? PEXStr(@"L_unlimited") : [@(value) stringValue]
                    to:constructedLabel];
        }
            break;

        case PEX_PACKAGE_ITEM_UNKNOWN:break;
    }
}

+ (NSString *) filesTextByCount: (const int64_t) count
{
    NSString * result = PEXStr(@"L_unlimited");

    if (count != -1)
    {
        NSString * const sufix = (count == 1) ? PEXStr(@"L_file") :
                (count > 4) || (count == 0)  ? PEXStr(@"L_files_more_than_four") : PEXStr(@"L_files");

        //result = [NSString stringWithFormat:@"%lld %@", count, sufix];
        result = [NSString stringWithFormat:@"%lld", count];
    }

    return result;
}

+ (void) appendNamed: (NSString * const) name value: (NSString * const) valueDesc to: (NSMutableString * const) appender
{
    if (appender.length)
        [appender appendString:@" + "];

    [appender appendString:[NSString stringWithFormat:@"%@: %@",
                                                      name,
                                                      valueDesc]];
}

@end