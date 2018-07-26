#import <UIKit/UIKit.h>
// models
#import "Contour.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
// structs
#import "CGRectOutline.h"
#import "EigenVector.h"
#import "LineInfo.h"

typedef NS_ENUM(NSUInteger, ContourRenderingMode) {
    ContourRenderingModeOutline,
    ContourRenderingModeFill
};

@interface PageDewarp: NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image filteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter;
/// returns the dewarped image
- (UIImage *_Nullable)render NS_SWIFT_NAME(render());
/// returns an image containing all the contour
- (UIImage *_Nullable)renderContours NS_SWIFT_NAME(renderContours());
/// returns an image containing all the spans
- (UIImage *_Nullable)renderSpans NS_SWIFT_NAME(renderSpans());
/// returns an image containing all the contour outlines
- (UIImage *_Nullable)renderOutlines NS_SWIFT_NAME(renderOutlines());
/// returns an image containing all the contours masks.
- (UIImage *_Nullable)renderMasks NS_SWIFT_NAME(renderMasks());
/// returns an image containing all the contours span keypoints.
- (UIImage *_Nullable)renderKeyPoints NS_SWIFT_NAME(renderKeyPoints());

/// returns an image containing keypoint correspondences, before optimization
- (UIImage *_Nullable)renderPreCorrespondences NS_SWIFT_NAME(renderPreCorrespondences());
/// returns an image containing keypoint correspondences, after optimization
- (UIImage *_Nullable)renderPostCorrespondences NS_SWIFT_NAME(renderPostCorrespondences());

// the original input image
@property (nonatomic, strong) UIImage *_Nonnull inputImage;
// resized "working" copy of the image
@property (nonatomic, strong) UIImage *_Nonnull workingImage;
@end
