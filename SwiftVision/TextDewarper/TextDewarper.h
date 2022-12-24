#import <UIKit/UIKit.h>
// models
#import "Contour.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
#import "TextDewarperConfiguration.h"

typedef NS_ENUM(NSUInteger, ContourRenderingMode) {
    ContourRenderingModeContour,
    ContourRenderingModeOutline,
    ContourRenderingModeFill
};

@interface TextDewarper: NSObject
/**
 * Creates a new TextDewarper engine for the input image..
 * For best results input image be a preprocessed binary image
 */
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image configuration:(TextDewarperConfiguration *_Nonnull)configuration filteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter;
- (instancetype _Nonnull)init NS_UNAVAILABLE;

/// returns the dewarped image
- (UIImage *_Nullable)dewarp NS_SWIFT_NAME(dewarp());

// returns thresholded input image
- (UIImage *_Nullable)renderThresholded NS_SWIFT_NAME(renderThresholded());
// returns dilated input image
- (UIImage *_Nullable)renderDilated NS_SWIFT_NAME(renderDilated());
// returns eroded input image
- (UIImage *_Nullable)renderEroded NS_SWIFT_NAME(renderEroded());
// returns input mask image
- (UIImage *_Nullable)renderInputMask NS_SWIFT_NAME(renderInputMask());

// returns pre-processed image (threshold, dilate, erode)
- (UIImage *_Nullable)renderProcessed NS_SWIFT_NAME(renderProcessed());
/// returns an image containing all the contour outlines
- (UIImage *_Nullable)renderOutlines NS_SWIFT_NAME(renderOutlines());
/// returns an image containing all the contours masks.
- (UIImage *_Nullable)renderMasks NS_SWIFT_NAME(renderMasks());
/// returns an image containing all the text spans contours.
- (UIImage *_Nullable)renderContours NS_SWIFT_NAME(renderContours());
/// returns an image containing all the text spans
- (UIImage *_Nullable)renderSpans NS_SWIFT_NAME(renderSpans());
/// returns an image containing all the text spans centerpoints.
- (UIImage *_Nullable)renderKeyPoints NS_SWIFT_NAME(renderKeyPoints());
/// returns an image containing all the text line quadratic curves.
- (UIImage *_Nullable)renderTextLineCurves NS_SWIFT_NAME(renderTextLineCurves());

// the original input image
@property (nonatomic, strong, readonly) UIImage *_Nonnull inputImage;
// resized "working" copy of the image
@property (nonatomic, strong, readonly) UIImage *_Nonnull workingImage;
@end
