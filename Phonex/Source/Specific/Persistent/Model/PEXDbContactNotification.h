//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbAppContentProvider;
@class PEXDbContentProvider;

extern NSString * const PEX_DBCONTACTNOTIFICATION_TABLE;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_ID;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_TYPE;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_DATE;
extern NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_SEEN;

@interface PEXDbContactNotification : PEXDbModelBase

@property (nonatomic) NSNumber * id;
@property (nonatomic) NSNumber * serverId;
@property (nonatomic) NSString * username;
@property (nonatomic) NSNumber * type;
@property (nonatomic) NSDate * date;
@property (nonatomic) NSNumber * seen;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(const PEXDbUri *) getURI;
+(const PEXDbUri *) getURIBase;

+ (NSString *) getDefaultSortOrder;
+ (instancetype) contactNotificationFromCursor: (PEXDbCursor * const) c;

+(BOOL) deleteRequestsFromUser: (NSString *) username cr: (PEXDbContentProvider *) cr;

- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToNotification:(PEXDbContactNotification *)notification;
- (NSUInteger)hash;
- (NSString *)description;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end