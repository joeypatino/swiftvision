#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "functions.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "Contour+internal.h"
#import "NSArray+extras.h"

using namespace std;
using namespace cv;

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *inputImage;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@end

// MARK: -
@implementation UIImageContours
- (instancetype)initWithImage:(UIImage *)image filteredBy:(nullable BOOL (^)(Contour * _Nonnull c))filter {
    return [image contoursFilteredBy:filter];
}

- (instancetype)initWithContours:(NSArray <Contour *> *)contours spans:(NSArray <ContourSpan *> *)spans inImage:(UIImage *)image {
    self = [super init];
    self.inputImage = image;
    self.contours = contours;
    self.spans = spans;

    return self;
}

// MARK: -
- (NSInteger)count {
    return self.contours.count;
}

- (Contour *)objectAtIndexedSubscript:(NSInteger)idx {
    return self.contours[idx];
}

// MARK: -
- (UIImage *)renderMasks {
    Mat outImage = Mat::zeros(self.inputImage.size.height, self.inputImage.size.width, CV_8UC1);
    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        Mat mask = contour.mask;
    }

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)renderKeyPoints {
    return [self renderKeyPoints:[UIColor redColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderKeyPoints:(UIColor *)color mode:(ContourRenderingMode)mode {
    UIImage *renderedContours = [self render];
    cv::Mat display = [renderedContours mat];

    for (ContourSpan *span in self.spans) {
        UIColor *spanColor = span.color;

        for (NSArray <NSValue *> *spanPoints in span.spanPoints) {
            CGSize sz = self.inputImage.size;
            NSArray <NSValue *> *points = nsarray::norm2pix(sz, spanPoints);
            Mat mean = Mat();
            Mat eigen = Mat();
            vector<Point2f> vectorPoints = nsarray::convertToVector(points);
            Mat computePoints = Mat(vectorPoints).reshape(1);
            PCACompute(computePoints, mean, eigen, 1);

            float x = eigen.at<float>(0, 0);
            float y = eigen.at<float>(0, 1);
            NSArray <NSNumber *> *dps = nsarray::dotProduct(points, Point2f(x, y));

            Point2f meanf = mean.at<Point2f>(0, 0);
            Point2f eigenf = eigen.at<Point2f>(0, 0);
            Point2f dpm = geom::multi(meanf, eigenf);

            float dpsMin = [dps min].floatValue;
            float dpsMax = [dps max].floatValue;
            Point2f point0 = meanf + geom::multi(eigenf, dpsMin - geom::sum(dpm));
            Point2f point1 = meanf + geom::multi(eigenf, dpsMax - geom::sum(dpm));

            BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
            for (NSValue *point in points) {
                circle(display, geom::pointFrom(point.CGPointValue), 3, [self scalarColorFrom:color], filled ? -1 : 1, LINE_AA);
            }
            line(display, point0, point1, [self scalarColorFrom:spanColor], 1, LINE_AA);
        }
        //[self renderCorners:span.keyPoints.corners using:spanColor in:display];
    }
    return [[UIImage alloc] initWithCVMat:display];
}

- (void)renderCorners:(CGRectOutline)cornerOutline using:(UIColor *)color in:(cv::Mat)display {
    NSArray <NSValue *> *corners = nsarray::pointsFrom(cornerOutline);
    NSArray <NSValue *> *normalizedCornerPoints = nsarray::norm2pix(self.inputImage.size, corners);
    std::vector<cv::Point> vectorPoints = std::vector<cv::Point>();
    for (NSValue *point in normalizedCornerPoints) {
        vectorPoints.push_back(geom::pointFrom(point.CGPointValue));
    }
    polylines(display, vectorPoints, YES, [self scalarColorFrom:color]);
}

- (UIImage *)render {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    BOOL fillConvexPolys = false;
    Scalar contourColor = [self scalarColorFrom:color];

    Mat outImage = Mat::zeros(self.inputImage.size.height, self.inputImage.size.width, CV_8UC3);
    vector<vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        // start - debugging
        if (fillConvexPolys) {
            cv::Point vertices[4];
            [contour getBoundingVertices:vertices];
            fillConvexPoly(outImage, vertices, 4, [self scalarColorFrom:[UIColor whiteColor]]);
        }
        // end - debugging

        contours.push_back(contour.opencvContour);
    }

    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -
- (Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}
@end
