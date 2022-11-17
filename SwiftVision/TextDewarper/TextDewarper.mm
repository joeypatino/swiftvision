#import <opencv2/opencv.hpp>
#import "TextDewarper.h"
// models
#import "DisparityModel.h"
// private
#import "Contour+internal.h"
#import "ContourSpan+internal.h"
// extras
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Contour.h"
#import "UIColor+extras.h"
#import "vectors.hpp"

using namespace std;
using namespace cv;

@interface TextDewarper ()
@property (nonatomic, strong) TextDewarperConfiguration *configuration;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@property (nonatomic, strong) UIImage *_Nonnull inputImage;
@property (nonatomic, strong) UIImage *_Nonnull workingImage;
@end

// MARK: -
@implementation TextDewarper
- (instancetype)initWithImage:(UIImage *)image configuration:(TextDewarperConfiguration *)configuration filteredBy:(BOOL (^)(Contour *c))filter {
    self = [super init];
    self.inputImage = image;
    self.workingImage = [image resizeTo:CGSizeMake(1440, 1920)];
    self.configuration = configuration;

    UIImage *processedImage = [self renderProcessed];
    self.contours = [processedImage contoursFilteredBy:filter usingConfiguration:self.configuration];
    self.spans = [processedImage spansFromContours:self.contours usingConfiguration:self.configuration];

    return self;
}

// MARK: - returns dewarped image
- (UIImage *)renderProcessed {
    CGRectOutline outline = [self outlineWithSize:self.workingImage.size insets:self.configuration.inputMaskInsets];
    UIImage *processedImage = [[[[self.workingImage invert] threshold:7 constant:8] dilate:CGSizeMake(8, 3)] erode:CGSizeMake(6, 2)];
    UIImage *mask = [processedImage rectangle:outline];
    return [processedImage elementwiseMinimum:mask];
}

// MARK: - returns dewarped image
- (UIImage *)dewarp {
    std::vector<std::vector<cv::Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    DisparityModel *disparity = [[DisparityModel alloc] initWithImage:self.workingImage keyPoints:allSpanPoints];
    return [disparity apply];
}

// MARK: - Debug
- (UIImage *)renderMasks {
   return [self render:[UIColor blackColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderOutlines {
    return [self render:[UIColor redColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)renderKeyPoints {
    return [self renderKeyPoints:ContourRenderingModeFill];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    cv::Mat outImage = [self.workingImage mat];

    vector<vector<cv::Point>> contours;
    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        contours.push_back(contour.opencvContour);
    }

    cv::Scalar contourColor = [self scalarColorFrom:color];
    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    cv::drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)renderKeyPoints:(ContourRenderingMode)mode {
    cv::Mat display = [self.workingImage mat];
    for (ContourSpan *span in self.spans) {
        for (int i = 0; i < span.keyPoints.size(); i++) {
            cv::Point2d pt = span.keyPoints[i];
            BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
            cv::circle(display, pt, 6, [self scalarColorFrom:span.color], filled ? -1 : 1, LINE_AA);
        }
    }
    return [[UIImage alloc] initWithCVMat:display];
}

- (UIImage *)renderTextLineCurves {
    std::vector<std::vector<Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    DisparityModel *disparity = [[DisparityModel alloc] initWithImage:self.workingImage keyPoints:allSpanPoints];
    return [disparity apply:DewarpOutputVerticalQuadraticCurves | DewarpOutputVerticalCenterLines];
}

// MARK: -
- (CGRectOutline)outlineWithSize:(CGSize)size insets:(UIEdgeInsets)insets {
    int xmin = 0;
    int ymin = 0;
    int xmax = int(size.width);
    int ymax = int(size.height);

    return CGRectOutlineMake(CGPointMake(xmin+insets.left, ymin+insets.top),
                             CGPointMake(xmax-insets.right, ymin+insets.top),
                             CGPointMake(xmax-insets.right, ymax-insets.bottom),
                             CGPointMake(xmin+insets.left, ymax-insets.bottom));
}

// MARK: - Render helpers
- (cv::Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

- (std::vector<vector<Point2d>>)allSamplePoints:(NSArray <ContourSpan *> *)spans {
    Size2d size = Size2d(self.workingImage.size.width, self.workingImage.size.height);
    std::vector<vector<Point2d>> allPoints;
    for (ContourSpan *span in spans) {
        std::vector<Point2d> samplePoints;
        for (int i = 0; i < span.spanPoints.size(); i++) {
            Point2f p = span.spanPoints.at(i);
            samplePoints.push_back(p);
        }
        allPoints.push_back(vectors::norm2pix(size, samplePoints));
    }
    return allPoints;
}
@end
