#import <UIKit/UIKit.h>
// models
#import "Contour.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
#import "ContourSpanInfo.h"
// structs
#import "CGRectOutline.h"
#import "EigenVector.h"
#import "LineInfo.h"

typedef NS_ENUM(NSUInteger, ContourRenderingMode) {
    ContourRenderingModeOutline,
    ContourRenderingModeFill
};

@interface UIImageContours : NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image filteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter;
/// returns an image containing all the contours, rendered in a default color and mode.
- (UIImage *_Nullable)render NS_SWIFT_NAME(render());
/// returns an image containing all the contours, rendered in `color` and using the mode `mode`.
- (UIImage *_Nullable)render:(UIColor *_Nonnull)color mode:(ContourRenderingMode)mode NS_SWIFT_NAME(render(inColor:using:));
/// returns an image containing all the contours masks.
- (UIImage *_Nullable)renderMasks NS_SWIFT_NAME(renderMasks());
/// returns an image containing all the contours span keypoints.
- (UIImage *_Nullable)renderKeyPoints NS_SWIFT_NAME(renderKeyPoints());
/// returns an image containing all the contours span keypoints, rendered in `color` and using the mode `mode`.
- (UIImage *_Nullable)renderKeyPoints:(UIColor *_Nonnull)color mode:(ContourRenderingMode)mode NS_SWIFT_NAME(renderKeyPoints(inColor:using:));
/// returns the dewarped image
- (UIImage *_Nullable)renderDewarped NS_SWIFT_NAME(renderDewarped());
@end

/// subscript support
@interface UIImageContours (SubscriptSupport)
- (Contour *_Nullable)objectAtIndexedSubscript:(NSInteger)idx;
@property (nonatomic, assign, readonly) NSInteger count;
@end
