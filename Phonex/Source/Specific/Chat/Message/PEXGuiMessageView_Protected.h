#import "PEXGuiMessageView.h"

#import "PEXGuiMessageTextBodyView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiClickableView.h"

@class PEXGuiImageView;

#define PEX_PARGIN PEXVal(@"dim_size_small")

@interface PEXGuiMessageView ()
@property (nonatomic) UIView * V_bodyContainer;
@property (nonatomic) PEXGuiClassicLabel *timeView;
@property (nonatomic) PEXGuiClassicLabel *statusView;
@property (nonatomic) PEXGuiImageView * readAck;
@property (nonatomic) UILabel * L_seen;
@property (nonatomic) NSDate * seenDateSet;

@property (nonatomic) PEXGuiBlockGestureRecognizer * clickRecognizer;
@property (nonatomic) PEXGuiLongBlockGestureRecognizer * longClickRecognizer;

- (void) initGuiStuff;
- (void) updateMessage: (const PEXDbMessage * const) message;

- (void) layoutGeneralHorizontalOutgoing;
- (void) layoutGeneralHorizontalIncoming;

- (void) setStatusInternal: (const PEXDbMessage * const) message;

@end