#import <UIKit/UIKit.h>

@class Contour;
@class DisparityModel;
@interface ContourSpan: NSObject
/// the image that this span belongs to
@property (nonatomic, strong, readonly) UIImage *_Nonnull image;
/// the contours in this span.
@property (nonatomic, strong, readonly) NSArray <Contour *> *_Nonnull contours;
/// The color to render this Span
@property (nonatomic, strong, readonly) UIColor *_Nonnull color;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
