#import <opencv2/opencv.hpp>
#import "PageDewarp.h"
// models
#import "ContourSpanInfo.h"
#import "KeyPointProjector.h"
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
#import "Optimizer.hpp"

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

    NSArray <NSArray <NSValue *> *> *allSpanPoints = [self allSamplePointsFromSpans:self.spans];

    ContourSpanInfo *spanInfo = [self generateSpanInfoWithSpanPoints:allSpanPoints andEigenVector:self.eigenVector];
    std::vector<double> params = nsarray::convertTo([spanInfo defaultParameters]);
    std::vector<cv::Point2f> keyPointIndexes = nsarray::convertTo2f([spanInfo keyPointIndexesForSpanCounts:spanInfo.spanCounts]);
    std::vector<cv::Point2f> dstpoints = nsarray::convertTo2f([spanInfo destinationPoints:allSpanPoints]);

    Ptr<CostFunction> fn = Ptr<CostFunction>(new CostFunction(dstpoints, keyPointIndexes));
    Optimizer opt = Optimizer(fn, params);
    printf("initial objective is %f\n",  opt.optimizeOnce(params));

    OptimizerResult res = opt.optimize();
    printf("optimization took: %f\n", res.dur);
    printf("final objective is %f\n", res.fun);

    return [[UIImage alloc] initWithCVMat:display];
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
    NSArray <NSArray <NSValue *> *> *samples = [self allSamplePointsFromSpans:spans];

    float eigenInit[] = {0, 0};
    float allWeights = 0.0;
    Mat allEigenVectors = Mat(1, 2, CV_32F, eigenInit);

    for (NSArray <NSValue *> *pointValues in samples) {
        Mat mean = Mat();
        Mat eigen = Mat();
        std::vector<Point2f> vectorPoints = nsarray::convertTo2f(pointValues);
        Mat computePoints = Mat(vectorPoints).reshape(1);
        PCACompute(computePoints, mean, eigen, 1);

        Point2f point = geom::convertTo(geom::subtract(pointValues.lastObject.CGPointValue, pointValues.firstObject.CGPointValue));
        double weight = norm(point);

        Mat eigenMul = eigen.mul(weight);
        allEigenVectors += eigenMul;
        allWeights += weight;
    }

    Mat outEigenVec = allEigenVectors / allWeights;
    float eigenX = outEigenVec.at<float>(0, 0);
    float eigenY = outEigenVec.at<float>(0, 1);
    if (eigenX < 0) {
        eigenX *= -1;
        eigenY *= -1;
    }

    Point2f xDir = Point2f(eigenX, eigenY);
    Point2f yDir = Point2f(-eigenY, eigenX);

    return EigenVectorMake(xDir, yDir);
}

- (ContourSpanInfo *)generateSpanInfoWithSpanPoints:(NSArray <NSArray <NSValue *> *> *)spanPoints andEigenVector:(EigenVector)eigenVector {
    CGSize sz = self.inputImage.size;
    Point2f eigenVectorx = geom::convertTo(eigenVector.x);
    Point2f eigenVectory = geom::convertTo(eigenVector.y);
    CGRectOutline rectOutline = geom::outlineWithSize(sz);

    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight],
                                 [NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft]];
    NSArray <NSValue *> *normalizedPts = nsarray::pix2norm(sz, pts);
    NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(normalizedPts, eigenVectorx);
    NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(normalizedPts, eigenVectory);

    float px0 = pxCoords.min.floatValue;
    float px1 = pxCoords.max.floatValue;
    float py0 = pyCoords.min.floatValue;
    float py1 = pyCoords.max.floatValue;

    // tl
    Point2f p00 = px0 * eigenVectorx + py0 * eigenVectory;
    // tr
    Point2f p01 = px1 * eigenVectorx + py0 * eigenVectory;
    // br
    Point2f p11 = px1 * eigenVectorx + py1 * eigenVectory;
    // bl
    Point2f p10 = px0 * eigenVectorx + py1 * eigenVectory;

    CGRectOutline corners = CGRectOutlineMake(geom::convertTo(p00),
                                              geom::convertTo(p10),
                                              geom::convertTo(p11),
                                              geom::convertTo(p01));

    NSMutableArray <NSNumber *> *ycoords = @[].mutableCopy;
    NSMutableArray <NSArray <NSNumber *> *> *xcoords = @[].mutableCopy;
    for (NSArray <NSValue *> *points in spanPoints) {
        NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(points, eigenVectorx);
        NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(points, eigenVectory);

        float meany = pyCoords.median.floatValue;
        [ycoords addObject:[NSNumber numberWithFloat:meany - py0]];
        [xcoords addObject:nsarray::subtract(pxCoords, px0)];
    }

    return [[ContourSpanInfo alloc] initWithCorners:corners xCoordinates:xcoords yCoordinates:ycoords];
}

- (NSArray <NSArray <NSValue *> *> *)allSamplePointsFromSpans:(NSArray <ContourSpan *> *)spans {
    NSMutableArray <NSArray <NSValue *> *> *samplePoints = @[].mutableCopy;
    for (ContourSpan *span in spans) {
        NSMutableArray <NSValue *> *spanPoints = @[].mutableCopy;
        for (NSArray <NSValue *> *points in span.spanPoints) {
            [spanPoints addObjectsFromArray:points];
        }
        [samplePoints addObject:spanPoints];
    }
    return [NSArray arrayWithArray:samplePoints];
}
@end
