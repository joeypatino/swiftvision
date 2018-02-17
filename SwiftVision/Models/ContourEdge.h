#import <UIKit/UIKit.h>

@class Contour;
@interface ContourEdge : NSObject
@property (nonatomic, assign, readonly) double score;
@property (nonatomic, strong, readonly) Contour *_Nullable contourA;
@property (nonatomic, strong, readonly) Contour *_Nullable contourB;
- (instancetype _Nonnull)initWithScore:(double)score contourA:(Contour *_Nonnull)contourA contourB:(Contour *_Nonnull)contourB;
@end
