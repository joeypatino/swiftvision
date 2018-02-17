#import <UIKit/UIKit.h>

@class Contour;
@interface ContourEdge : NSObject
@property (nonatomic, assign, readonly) double score;
@property (nonatomic, assign, readonly) double distance;
@property (nonatomic, assign, readonly) double angle;
@property (nonatomic, assign, readonly) double overlap;
@property (nonatomic, strong, readonly) Contour *_Nullable contourA;
@property (nonatomic, strong, readonly) Contour *_Nullable contourB;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
