#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, DewarpOutput) {
    DewarpOutputNone                    = 0,        // <- does nothing, returns input image
    DewarpOutputDewarped                = 1 << 0,   // <- returns a dewarped image
    DewarpOutputVerticalQuadraticCurves = 1 << 1,   // <- returns the input image with debugging overlays
    DewarpOutputVerticalCenterLines     = 1 << 2    // <- returns the input image with debugging overlays
};

@interface DisparityModel: NSObject
@property (nonatomic, assign, readonly) std::vector<std::vector<cv::Point2d>> keyPoints;
@property (nonatomic, strong, readonly) UIImage *_Nonnull inputImage;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image keyPoints:(std::vector<std::vector<cv::Point2d>>)keyPoints NS_DESIGNATED_INITIALIZER;
- (UIImage *_Nullable)apply;
- (UIImage *_Nullable)apply:(DewarpOutput)options;
@end
