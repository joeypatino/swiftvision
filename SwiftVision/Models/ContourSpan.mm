#import <opencv2/opencv.hpp>
#import "ContourSpan.h"
#import "functions.h"
#import "Contour.h"
#import "Contour+internal.h"
#import "ContourSpanKeyPoints.h"
#import "NSArray+extras.h"

struct EigenDirection {
    cv::Point2f x;
    cv::Point2f y;
};

static inline struct EigenDirection
EigenDirectionMake(cv::Point2f x, cv::Point2f y) {
    struct EigenDirection eigen;
    eigen.x = x;
    eigen.y = y;
    return eigen;
}

using namespace cv;
using namespace std;

@interface ContourSpan ()
@end

@implementation ContourSpan
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image contours:(NSArray <Contour *> *)contours {
    self = [super init];
    _image = image;
    _contours = contours;
    _keyPoints = [self sampleSpan:self];
    return self;
}

- (ContourSpanKeyPoints *)sampleSpan:(ContourSpan *)span {
    NSMutableArray <NSValue *> *contourPoints = @[].mutableCopy;
    NSMutableArray <NSArray <NSValue *> *> *spanPoints = @[].mutableCopy;
    for (Contour *contour in span.contours) {
        Mat maskContour;
        contour.mask.clone().convertTo(maskContour, CV_32F);

        Mat multi = maskContour.clone();
        for (int c = 0; c < multi.cols; c++) {
            for (int r = 0; r < multi.rows; r++) {
                int value = multi.at<float>(r, c);
                multi.at<float>(r, c) = value * r;
            }
        }

        Mat totals;
        reduce(multi, totals, 0, CV_REDUCE_SUM);

        Mat masksum;
        reduce(maskContour, masksum, 0, CV_REDUCE_SUM);
        Mat means = totals / masksum;

        int step = 14;
        int start = ((means.total() - 1) % step) / 2;

        for (int x = start; x <= means.total(); x += step) {
            float meanValue = means.at<float>(x);
            CGPoint point = CGPointMake(x + contour.bounds.origin.x, meanValue + contour.bounds.origin.y);
            NSValue *pointValue = [NSValue valueWithCGPoint:point];
            [contourPoints addObject:pointValue];
        }

        NSArray <NSValue *> *normalizedPoints = nsarray::pix2norm(self.image.size, contourPoints);
        [spanPoints addObject:normalizedPoints];
    }
    return [self keypointsFromSpanSamples:[NSArray arrayWithArray:spanPoints]];
}

- (EigenDirection)computeEigenVectorsFrom:(NSArray <NSArray <NSValue *> *> *)samples {
    float eigenInit[] = {0, 0};
    Mat allEigenVectors = Mat(1, 2, CV_32F, eigenInit);
    float allWeights = 0.0;

    for (NSArray <NSValue *> *pointValues in samples) {
        Mat mean = Mat();
        Mat eigen = Mat();
        vector<Point2f> vectorPoints = nsarray::convertToVector(pointValues);
        Mat computePoints = Mat(vectorPoints).reshape(1);
        PCACompute(computePoints, mean, eigen, 1);

        Point2f point = geom::pointFrom(geom::subtract(pointValues.lastObject.CGPointValue, pointValues.firstObject.CGPointValue));
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

    return EigenDirectionMake(xDir, yDir);
}

- (ContourSpanKeyPoints *)keypointsFromSpanSamples:(NSArray <NSArray <NSValue *> *> *)samples {
    EigenDirection dir = [self computeEigenVectorsFrom:samples];

    CGSize sz = self.image.size;
    CGRectOutline rectOutline = geom::outlineWithSize(self.image.size);
    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight]];
    NSArray <NSValue *> *normalizedPts = nsarray::pix2norm(sz, pts);
    NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(normalizedPts, dir.x);
    NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(normalizedPts, dir.y);

    float px0 = [pxCoords min].floatValue;
    float px1 = [pxCoords max].floatValue;
    float py0 = [pyCoords min].floatValue;
    float py1 = [pyCoords max].floatValue;

    Point2f p00 = px0 * dir.x + py0 * dir.y;
    Point2f p10 = px1 * dir.x + py0 * dir.y;
    Point2f p11 = px1 * dir.x + py1 * dir.y;
    Point2f p01 = px0 * dir.x + py1 * dir.y;

    // tl, tr, br, bl
    CGRectOutline corners = CGRectOutlineMake(geom::pointFrom(p00),
                                              geom::pointFrom(p10),
                                              geom::pointFrom(p11),
                                              geom::pointFrom(p01));

    NSMutableArray <NSNumber *> *ycoords = @[].mutableCopy;
    NSMutableArray <NSArray <NSNumber *> *> *xcoords = @[].mutableCopy;
    for (NSArray <NSValue *> *points in samples) {
        NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(points, dir.x);
        NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(points, dir.y);

        float meany = [pyCoords median].floatValue;
        [ycoords addObject:[NSNumber numberWithFloat:meany - py0]];
        [xcoords addObject:nsarray::subtract(pxCoords, px0)];
    }

    return [[ContourSpanKeyPoints alloc] initWithCorners:corners xCoordinates:xcoords yCoordinates:ycoords];
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@", %@", self.keyPoints];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}
@end

