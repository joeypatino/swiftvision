#import <UIKit/UIKit.h>
#import "Contour.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
#import "CGRectOutline.h"
#import "ContourSpanKeyPoints.h"

typedef NS_ENUM(NSUInteger, ContourRenderingMode) {
    ContourRenderingModeOutline,
    ContourRenderingModeFill
};

@interface UIImageContours : NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image filteredBy:(nullable BOOL (^)(Contour * _Nonnull c))filter;
/// returns an image containing all the contours, rendered in a default color and mode.
- (UIImage * _Nullable)render NS_SWIFT_NAME(render());
/// returns an image containing all the contours, rendered in `color` and using the mode `mode`.
- (UIImage * _Nullable)render:(UIColor * _Nonnull)color mode:(ContourRenderingMode)mode NS_SWIFT_NAME(render(inColor:using:));
/// returns an image containing all the contours masks.
- (UIImage * _Nullable)renderMasks NS_SWIFT_NAME(renderMasks());
/// returns an image containing all the contours span keypoints.
- (UIImage * _Nullable)renderKeyPoints NS_SWIFT_NAME(renderKeyPoints());
@end

/// subscript support
@interface UIImageContours (SubscriptSupport)
- (Contour * _Nullable)objectAtIndexedSubscript:(NSInteger)idx;
@property (nonatomic, assign, readonly) NSInteger count;
@end
