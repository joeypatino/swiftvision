#import <opencv2/opencv.hpp>
#include <numeric>
#import "PageDewarp.h"
// models
#import "ContourSpanInfo.h"
// private
#import "Contour+internal.h"
#import "ContourSpan+internal.h"
#import "ContourSpanInfo+internal.h"
// extras
#import "functions.h"
#import "NSArray+extras.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Contour.h"
#import "UIColor+extras.h"
// structs
#import "EigenVector.h"
#import "LineInfo.h"
#import "CGRectOutline.h"
// optimization
#import "Optimizer.hpp"
#import "KeyPointCostFunction.hpp"
#import "CornerPointCostFunction.hpp"

static inline struct EigenVector
EigenVectorMake(cv::Point2f x, cv::Point2f y) {
    struct EigenVector eigen;
    eigen.x = geom::convertTo(x);
    eigen.y = geom::convertTo(y);
    return eigen;
}

using namespace std;
using namespace cv;

@interface PageDewarp ()
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@property (nonatomic, assign) EigenVector eigenVector;

@end

// MARK: -
@implementation PageDewarp
- (instancetype)initWithImage:(UIImage *)image filteredBy:(BOOL (^)(Contour *c))filter {
    self = [super init];
    UIImage *mask = [[[image threshold:55 constant:25] dilate:CGSizeMake(9, 1)] erode:CGSizeMake(1, 3)];

    self.inputImage = image;
    self.contours = [mask contoursFilteredBy:filter];;
    self.spans = [mask spansFromContours:self.contours];;
    self.eigenVector = [self generateEigenVectorFromSpans:self.spans];

    return self;
}

// MARK: - render dewarped image
- (UIImage *)render {
    cv::Mat display = [self.inputImage mat];

    std::vector<std::vector<cv::Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    ContourSpanInfo *spanInfo = [self generateSpanInfoWithSpanPoints:allSpanPoints andEigenVector:self.eigenVector];
    std::vector<double> params = [spanInfo defaultParameters];
    std::vector<cv::Point2d> keyPointIndexes = [spanInfo keyPointIndexesForSpanCounts:spanInfo.spanCounts];
    std::vector<cv::Point2d> dstpoints = [spanInfo destinationPoints:allSpanPoints];

    Ptr<KeyPointCostFunction> fn = Ptr<KeyPointCostFunction>(new KeyPointCostFunction(dstpoints, keyPointIndexes));
    Optimizer opt = Optimizer(fn, params);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f\n", res.dur);
    printf("final objective is %f\n", res.fun);

    [self optimizeCorner:spanInfo.corners.botRight dims:spanInfo.roughDimensions params: res.x];

    return [[UIImage alloc] initWithCVMat:display];
}

- (void)optimizeCorner:(CGPoint)p dims:(CGSize)roughDims params:(std::vector<double>)x {

    vector<Point2d> dstpoints = {Point2d(p.x, p.y)};
    vector<double> params = {roughDims.width, roughDims.height};

    Ptr<CornerPointCostFunction> fn = Ptr<CornerPointCostFunction>(new CornerPointCostFunction(dstpoints));
    Optimizer opt = Optimizer(fn, params);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f\n", res.dur);
    printf("final objective is %f\n", res.fun);

}

// MARK: - Debug
- (UIImage *)renderMasks {
   return [self render:[UIColor blackColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderContours {
    Mat display = [self.inputImage mat];
    vector<vector<cv::Point>> contours;
    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        contours.push_back(contour.opencvContour);
    }
    for (int i = 0; i < contours.size(); i++) {
        Contour *contour = self.contours[i];
        Scalar color = [self scalarColorFrom:contour.color];
        cv::drawContours(display, contours, i, color, -1);
    }

    Mat output = [self.inputImage mat];
    cv::addWeighted(display, 0.7, output, 0.3, 0, output);
    for (Contour *contour in self.contours) {
        Scalar color = [self scalarColorFrom:[UIColor whiteColor]];
        circle(output, geom::convertTo(contour.center), 3, color, 1, LINE_AA);
        cv::line(output, geom::convertTo(contour.clxMin), geom::convertTo(contour.clxMax), color, 1, LINE_AA);
    }

    return [[UIImage alloc] initWithCVMat:output];
}

- (UIImage *)renderOutlines {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    Mat outImage = [self.inputImage mat];
    vector<vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        contours.push_back(contour.opencvContour);
    }

    Scalar contourColor = [self scalarColorFrom:color];
    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)renderKeyPoints {
    return [self renderKeyPoints:[UIColor whiteColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderKeyPoints:(UIColor *)color mode:(ContourRenderingMode)mode {
    cv::Mat display = [self.inputImage mat];

    for (ContourSpan *span in self.spans) {
        Point2f start = geom::convertTo(span.line.p1);
        Point2f end = geom::convertTo(span.line.p2);
        line(display, start, end, [self scalarColorFrom:color], 1, LINE_AA);

        for (NSValue *keyPoint in span.keyPoints) {
            BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
            circle(display, geom::convertTo(keyPoint.CGPointValue), 3, [self scalarColorFrom:span.color], filled ? -1 : 1, LINE_AA);
        }
    }

    return [[UIImage alloc] initWithCVMat:display];
}

// MARK: - Render helpers
- (Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

// MARK: -
- (EigenVector)generateEigenVectorFromSpans:(NSArray <ContourSpan *> *)spans {
    std::vector<std::vector<cv::Point2d>> samples = [self allSamplePoints:spans];
    double eigenInit[] = {0, 0};
    double allWeights = 0.0;
    Mat allEigenVectors = Mat(1, 2, cv::DataType<double>::type, eigenInit);

    for (int i = 0; i < samples.size(); i++) {
        std::vector<cv::Point2d> vectorPoints = samples[i];
        cv::Mat mean = cv::Mat();
        cv::Mat eigen = cv::Mat();
        cv::Mat computePoints = cv::Mat(vectorPoints).reshape(1);
        cv::PCACompute(computePoints, mean, eigen, 1);

        cv::Point2d firstP = vectorPoints[0];
        cv::Point2d lastP = vectorPoints[vectorPoints.size() -1];
        cv::Point2d point = lastP - firstP;
        double weight = cv::norm(point);

        Mat eigenMul = eigen.mul(weight);
        allEigenVectors += eigenMul;
        allWeights += weight;
    }

    Mat outEigenVec = allEigenVectors / allWeights;
    double eigenX = outEigenVec.at<double>(0, 0);
    double eigenY = outEigenVec.at<double>(0, 1);
    if (eigenX < 0) {
        eigenX *= -1;
        eigenY *= -1;
    }

    Point2d xDir = Point2d(eigenX, eigenY);
    Point2d yDir = Point2d(-eigenY, eigenX);

    return EigenVectorMake(xDir, yDir);
}

- (ContourSpanInfo *)generateSpanInfoWithSpanPoints:(std::vector<std::vector<cv::Point2d>>)allSpanPoints andEigenVector:(EigenVector)eigenVector {
    CGSize sz = self.inputImage.size;
    Point2d eigenVectorx = geom::convertTo(eigenVector.x);
    Point2d eigenVectory = geom::convertTo(eigenVector.y);
    CGRectOutline rectOutline = geom::outlineWithSize(sz);

    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight],
                                 [NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft]];
    NSArray <NSValue *> *normalizedPts = nsarray::pix2norm(sz, pts);
    NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(normalizedPts, eigenVectorx);
    NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(normalizedPts, eigenVectory);

    double px0 = pxCoords.min.doubleValue;
    double px1 = pxCoords.max.doubleValue;
    double py0 = pyCoords.min.doubleValue;
    double py1 = pyCoords.max.doubleValue;

    // tl
    Point2d p00 = px0 * eigenVectorx + py0 * eigenVectory;
    // tr
    Point2d p01 = px1 * eigenVectorx + py0 * eigenVectory;
    // br
    Point2d p11 = px1 * eigenVectorx + py1 * eigenVectory;
    // bl
    Point2d p10 = px0 * eigenVectorx + py1 * eigenVectory;

    CGRectOutline corners = CGRectOutlineMake(geom::convertTo(p00),
                                              geom::convertTo(p10),
                                              geom::convertTo(p11),
                                              geom::convertTo(p01));

    vector<double> ycoords;
    vector<vector<double>> xcoords;
    for (int i = 0; i < allSpanPoints.size(); i++) {
        std::vector<cv::Point2d> spanPoints = allSpanPoints[i];
        std::vector<double> pxCoords = vectors::dotProduct(spanPoints, eigenVectorx);
        std::vector<double> pyCoords = vectors::dotProduct(spanPoints, eigenVectory);
        double meany = 1.0 * std::accumulate(pyCoords.begin(), pyCoords.end(), 0LL) / pyCoords.size();

        ycoords.push_back(meany - py0);
        xcoords.push_back(vectors::subtract(pxCoords, px0));
    }
    return [[ContourSpanInfo alloc] initWithCorners:corners xCoordinates:xcoords yCoordinates:ycoords];
}

- (vector<vector<Point2d>>)allSamplePoints:(NSArray <ContourSpan *> *)spans {
    vector<vector<Point2d>> allPoints;
    for (ContourSpan *span in spans) {
        vector<Point2d> samplePoints;
        for (NSArray <NSValue *> *points in span.spanPoints) {
            for (NSValue *p in points) {
                samplePoints.push_back(cv::Point2f(p.CGPointValue.x, p.CGPointValue.y));
            }
        }
        allPoints.push_back(samplePoints);
    }

    return allPoints;
}
@end
