#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
// models
#import "Contour+internal.h"
#import "ContourSpan+internal.h"
#import "ContourSpanInfo.h"
// extras
#import "functions.h"
#import "NSArray+extras.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
// structs
#import "EigenVector.h"
#import "LineInfo.h"
#import "CGRectOutline.h"

static inline struct EigenVector
EigenVectorMake(cv::Point2f x, cv::Point2f y) {
    struct EigenVector eigen;
    eigen.x = geom::convertTo(x);
    eigen.y = geom::convertTo(y);
    return eigen;
}

using namespace std;
using namespace cv;

@interface ContourSpanInfo()
- (instancetype _Nonnull)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(NSArray <NSArray <NSNumber *> *> *_Nonnull)xCoordinates
                            yCoordinates:(NSArray <NSNumber *> *_Nonnull)yCoordinates;
@end

@interface UIImageContours ()
@property (nonatomic, strong) UIImage *inputImage;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@property (nonatomic, assign) EigenVector eigenVector;
@end

// MARK: -
@implementation UIImageContours
- (instancetype)initWithImage:(UIImage *)image filteredBy:(BOOL (^)(Contour *c))filter {
    self = [super init];
    NSArray <Contour *> *contours = [image contoursFilteredBy:filter];
    NSArray <ContourSpan *> *spans = [image spansFromContours:contours];
    self.inputImage = image;
    self.contours = contours;
    self.spans = spans;
    self.eigenVector = [self generateEigenVectorFromSpans:self.spans];

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
   return [self render:[UIColor whiteColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderKeyPoints {
    return [self renderKeyPoints:[UIColor redColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderKeyPoints:(UIColor *)color mode:(ContourRenderingMode)mode {
    UIImage *renderedContours = [self render];
    cv::Mat display = [renderedContours mat];

    for (ContourSpan *span in self.spans) {
        Point2f start = geom::convertTo(span.line.p1);
        Point2f end = geom::convertTo(span.line.p2);
        line(display, start, end, [self scalarColorFrom:span.color], 1, LINE_AA);

        for (NSValue *keyPoint in span.keyPoints) {
            BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
            circle(display, geom::convertTo(keyPoint.CGPointValue), 3, [self scalarColorFrom:color], filled ? -1 : 1, LINE_AA);
        }
    }

    NSArray <NSArray <NSValue *> *> *allSpanPoints = [self allSamplePointsFromSpans:self.spans];
    ContourSpanInfo *spanInfo = [self generateSpanInfoWithSpanPoints:allSpanPoints andEigenVector:self.eigenVector];
    [self renderCorners:spanInfo.corners using:[UIColor greenColor] in:display];
    [spanInfo defaultParmeters];

    NSMutableArray <NSValue *> *destinationPoints = @[].mutableCopy;
    [destinationPoints addObject:[NSValue valueWithCGPoint:spanInfo.corners.topLeft]];
    [destinationPoints addObjectsFromArray:[allSpanPoints valueForKeyPath: @"@unionOfArrays.self"]];

    return [[UIImage alloc] initWithCVMat:display];
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
            fillConvexPoly(outImage, vertices, 4, [self scalarColorFrom:color]);
        }
        // end - debugging

        contours.push_back(contour.opencvContour);
    }

    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)renderDewarped {
//    NSMutableArray *allXCoords = @[].mutableCopy;
//    NSMutableArray *allYCoords = @[].mutableCopy;
//    for (ContourSpan *span in self.spans) {
//        ContourSpanInfo *spanPoints = [span keyPointsUsingEigenVector:self.eigenVector];
//        printf("[%s, %s, %s, %s]\n",
//               [NSStringFromCGPoint(spanPoints.corners.topLeft) UTF8String],
//               [NSStringFromCGPoint(spanPoints.corners.topRight) UTF8String],
//               [NSStringFromCGPoint(spanPoints.corners.botRight) UTF8String],
//               [NSStringFromCGPoint(spanPoints.corners.botLeft) UTF8String]);
//
//        [allXCoords addObjectsFromArray:spanPoints.xCoordinates];
//        [allYCoords addObjectsFromArray:spanPoints.yCoordinates];
//    }

    return [[UIImage alloc] init];
}

// MARK: - Render helpers
- (void)renderCorners:(CGRectOutline)cornerOutline using:(UIColor *)color in:(cv::Mat)display {
    NSArray <NSValue *> *corners = nsarray::pointsFrom(cornerOutline);
    NSArray <NSValue *> *normalizedCornerPoints = nsarray::norm2pix(self.inputImage.size, corners);
    std::vector<cv::Point> vectorPoints = std::vector<cv::Point>();
    for (NSValue *point in normalizedCornerPoints) {
        vectorPoints.push_back(geom::convertTo(point.CGPointValue));
    }
    polylines(display, vectorPoints, YES, [self scalarColorFrom:color]);
}

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
        std::vector<Point2f> vectorPoints = nsarray::convertTo(pointValues);
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
    cv::Point2f eigenVectorx = geom::convertTo(eigenVector.x);
    cv::Point2f eigenVectory = geom::convertTo(eigenVector.y);
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
                                              geom::convertTo(p01),
                                              geom::convertTo(p11),
                                              geom::convertTo(p10));

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
        [samplePoints addObjectsFromArray:span.spanPoints];
    }
    return [NSArray arrayWithArray:samplePoints];
}
@end
