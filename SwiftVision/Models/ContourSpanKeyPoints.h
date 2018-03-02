#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface ContourSpanKeyPoints: NSObject
@property (nonatomic, assign, readonly) CGRectOutline corners;
@property (nonatomic, strong, readonly) NSArray <NSArray <NSNumber *> *> *_Nonnull xCoordinates;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull yCoordinates;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
