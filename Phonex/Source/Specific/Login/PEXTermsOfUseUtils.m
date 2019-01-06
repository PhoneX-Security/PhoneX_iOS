//
// Created by Matej Oravec on 02/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTermsOfUseUtils.h"


@implementation PEXTermsOfUseUtils {

}
+ (NSString *)urlToTersmOfUse
{
    NSString * currentLocale = [PEXResStrings getCurrentAppLanguage];

    if ([currentLocale isEqualToString:@"auto"])
    {
        currentLocale = [NSLocale preferredLanguages][0];
    }


    return [currentLocale isEqualToString:@"cs"] || [currentLocale isEqualToString:@"sk"] ?
            @"https://www.phone-x.net/cs/podpora/obchodni-a-licencni-podminky" :
            @"https://www.phone-x.net/en/support/terms-and-conditions";
}

@end