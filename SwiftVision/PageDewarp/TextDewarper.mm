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
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@property (nonatomic, strong) UIImage *_Nonnull inputImage;
@property (nonatomic, strong) UIImage *_Nonnull workingImage;
@end

// MARK: -
@implementation TextDewarper
- (instancetype)initWithImage:(UIImage *)image filteredBy:(BOOL (^)(Contour *c))filter {
    self = [super init];
    self.inputImage = image;
    self.workingImage = [image resizeTo:CGSizeMake(1080, 1920)];

    UIImage *mask = [[[self.workingImage
                        threshold:55
                        constant:25]
                       dilate:CGSizeMake(9, 1)]
                      erode:CGSizeMake(1, 3)];
    CGRectOutline outline = [self outlineWithSize:self.workingImage.size];
    UIImage *minMask = [mask elementwiseMinimum:[self.workingImage rectangle:outline]];
    self.contours = [minMask contoursFilteredBy:filter];
    self.spans = [minMask spansFromContours:self.contours];

    return self;
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
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
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

- (UIImage *)renderKeyPoints {
    return [self renderKeyPoints:[UIColor whiteColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderKeyPoints:(UIColor *)color mode:(ContourRenderingMode)mode {
    std::vector<std::vector<Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    DisparityModel *disparity = [[DisparityModel alloc] initWithImage:self.workingImage keyPoints:allSpanPoints];
    return [disparity apply:DewarpOutputVerticalQuadraticCurves | DewarpOutputVerticalCenterLines];
}

// MARK: -
- (CGRectOutline)outlineWithSize:(CGSize)size {
    int PAGE_MARGIN_X = 20;
    int PAGE_MARGIN_Y = 20;

    int xmin = PAGE_MARGIN_X;
    int ymin = PAGE_MARGIN_Y;
    int xmax = int(size.width) - PAGE_MARGIN_X;
    int ymax = int(size.height) - PAGE_MARGIN_Y;

    return CGRectOutlineMake(CGPointMake(xmin, ymin),
                             CGPointMake(xmax, ymin),
                             CGPointMake(xmax, ymax),
                             CGPointMake(xmin, ymax));
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
