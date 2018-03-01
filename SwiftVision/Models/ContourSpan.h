#import <UIKit/UIKit.h>

@class Contour;
@class ContourSpanKeyPoints;
@interface ContourSpan : NSObject
/// the image that this span belongs to
@property (nonatomic, strong, readonly) UIImage *_Nonnull image;
/// the contours in this span.
@property (nonatomic, retain, readonly) NSArray <Contour *> *_Nonnull contours;
/// keypoint information for the span
@property (nonatomic, retain, readonly) ContourSpanKeyPoints * _Nullable keyPoints;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image contours:(NSArray <Contour *> *_Nonnull)contours NS_DESIGNATED_INITIALIZER;
@end
