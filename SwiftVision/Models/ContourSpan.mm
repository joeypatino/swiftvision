#import <opencv2/opencv.hpp>
#import "ContourSpan.h"
// models
#import "Contour.h"
// private
#import "ContourSpan+internal.h"
#import "Contour+internal.h"
// extras
#import "functions.h"
#import "NSArray+extras.h"
#import "UIColor+extras.h"
// structs
#import "EigenVector.h"
#import "LineInfo.h"

static inline struct LineInfo
ContourSpanLineInfoMake(cv::Point2f p1, cv::Point2f p2) {
    struct LineInfo line;
    line.p1 = geom::convertTo(p1);
    line.p2 = geom::convertTo(p2);
    return line;
}

using namespace cv;
using namespace std;

@implementation ContourSpan
- (instancetype)initWithImage:(UIImage *)image contours:(NSArray <Contour *> *)contours {
    self = [super init];
    _samplingStep = 20;
    _color = [UIColor randomColor];
    _image = image;
    _contours = contours;
    _spanPoints = [self sampleSpanPointsFrom:self.contours];
    _line = [self spanLineInfoFromKeyPoints:self.keyPoints];

    return self;
}

- (NSArray <NSArray <NSValue *> *> *)sampleSpanPointsFrom:(NSArray <Contour *> *)contours {
    NSMutableArray <NSValue *> *contourPoints = @[].mutableCopy;
    NSMutableArray <NSArray <NSValue *> *> *spanPoints = @[].mutableCopy;
    for (Contour *contour in contours) {
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

        int step = self.samplingStep;
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
    return [NSArray arrayWithArray:spanPoints];
}

- (NSArray <NSValue *> *)keyPoints {
    NSMutableArray <NSValue *> *keyPoints = @[].mutableCopy;
    for (NSArray <NSValue *> *spanPoints in self.spanPoints) {
        NSArray <NSValue *> *points = nsarray::norm2pix(self.image.size, spanPoints);
        [keyPoints addObjectsFromArray:points];
    }
    return keyPoints;
}

- (LineInfo)spanLineInfoFromKeyPoints:(NSArray <NSValue *> *)keyPoints {
    Mat mean = Mat();
    Mat eigen = Mat();
    vector<Point2f> vectorPoints = nsarray::convertTo(keyPoints);
    Mat computePoints = Mat(vectorPoints).reshape(1);
    PCACompute(computePoints, mean, eigen, 1);

    float x = eigen.at<float>(0, 0);
    float y = eigen.at<float>(0, 1);
    NSArray <NSNumber *> *dps = nsarray::dotProduct(keyPoints, Point2f(x, y));

    Point2f meanf = mean.at<Point2f>(0, 0);
    Point2f eigenf = eigen.at<Point2f>(0, 0);
    Point2f dpm = geom::multi(meanf, eigenf);

    Point2f p1 = meanf + geom::multi(eigenf, dps.min.floatValue - geom::sum(dpm));
    Point2f p2 = meanf + geom::multi(eigenf, dps.max.floatValue - geom::sum(dpm));

    return ContourSpanLineInfoMake(p1, p2);
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}
@end

