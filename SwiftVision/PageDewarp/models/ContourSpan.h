#import <UIKit/UIKit.h>

@class Contour;
@class ContourSpanInfo;
@interface ContourSpan: NSObject
/// the image that this span belongs to
@property (nonatomic, strong, readonly) UIImage *_Nonnull image;
/// the contours in this span.
@property (nonatomic, strong, readonly) NSArray <Contour *> *_Nonnull contours;
/// the starting and ending points of this span
@property (nonatomic, assign, readonly) struct LineInfo line;
/// the keypoints sampled along this span
@property (nonatomic, strong, readonly) NSArray <NSValue *> *_Nonnull keyPoints;
/// The color to render this Span
@property (nonatomic, strong, readonly) UIColor *_Nonnull color;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
