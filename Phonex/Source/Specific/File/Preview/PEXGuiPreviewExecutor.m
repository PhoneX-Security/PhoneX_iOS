//
// Created by Matej Oravec on 16/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPreviewExecutor.h"
#import "PEXQlItem.h"

#import "PEXGuiFileUtils.h"

@interface PEXGuiPreviewExecutor ()

@property (nonatomic) UIViewController * superController;
@property (nonatomic) NSArray * qlItems;
@property (nonatomic) QLPreviewController * qlController;
@property (nonatomic) id<PEXGuiPreviewDelegate> listener;

@end

@implementation PEXGuiPreviewExecutor

+ (bool) canPerformWithQlItem: (const id) item
{
    bool result = [item conformsToProtocol:@protocol(QLPreviewItem)] &&
            [QLPreviewController canPreviewItem:item] &&
            ![PEXGuiFileUtils isAssetUrl:((PEXQlItem *)item).url];

    // we cannot preview assets
    if (result)
        result = [[NSFileManager defaultManager] fileExistsAtPath:((PEXQlItem *)item).url.path];

    return result;
}

- (id) initWithListener: (id<PEXGuiPreviewDelegate>) listener superController: (UIViewController * const) superController
{
    self = [super init];

    self.listener = listener;
    self.superController = superController;

    return self;
}

// get from extractQlItems
- (void)prepareWithActivityItems:(NSArray *)qlItems
{
    self.qlItems = qlItems;
}

+ (NSArray *)extractQlItems:(NSArray *)fileUrls
{
    NSMutableArray * const qlItems = [[NSMutableArray alloc] initWithCapacity:fileUrls.count];

    for (NSURL * const url in fileUrls)
    {
        // Preview only those we can
        // e.g. Listing non-existing file the app crashes
        const PEXQlItem * const item = [[PEXQlItem alloc] initWithFileUrl:url];
        if ([PEXGuiPreviewExecutor canPerformWithQlItem:item])
            [qlItems addObject:[[PEXQlItem alloc] initWithFileUrl:url]];
    }

    return qlItems;
}

- (void) present
{
    self.qlController = [[QLPreviewController alloc]init];
    self.qlController.delegate = self;
    self.qlController.dataSource = self;

    [self.qlController.navigationItem setRightBarButtonItem:nil];
    self.qlController.currentPreviewItemIndex = 0;

    [PEXGVU presentModalTransparent:self.qlController onParent:self.superController];
}

#pragma QLPreviewControllerDelegate

- (void)previewControllerWillDismiss:(QLPreviewController *)controller
{
    // DO NOTHING
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    [self.listener previewDidDismiss];
}

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item
{
    return [PEXGuiPreviewExecutor canPerformWithQlItem:item];
}

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item
               inSourceView:(UIView **)view
{
    return self.superController.view.frame;
}

- (UIImage *)previewController:(QLPreviewController *)controller transitionImageForPreviewItem:(id <QLPreviewItem>)item
                   contentRect:(CGRect *)contentRect
{
    // TODO?
    return nil;
}

#pragma QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.qlItems.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return self.qlItems[index];
}

@end