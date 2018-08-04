#import <opencv2/opencv.hpp>
#import "ContourSpan.h"
// models
#import "Contour.h"
// private
#import "ContourSpan+internal.h"
#import "Contour+internal.h"
// extras
#import "functions.h"
#import "math+extras.hpp"
#import "NSArray+extras.h"
#import "UIColor+extras.h"
// structs
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

- (NSArray <NSValue *> *)sampleSpanPointsFrom:(NSArray <Contour *> *)contours {
    std::vector<cv::Point2d> contourPoints;
    std::vector<std::vector<cv::Point2d>> spanPoints;
    for (Contour *contour in contours) {
        cv::Mat mask = contour.mask.clone();
        std::vector<double> points = math::linspace(0, mask.rows-1, mask.rows);
        for (int i = 0; i < points.size(); i++) {
            mask.row(i) *= points[i];
        }

        Mat totals;
        reduce(mask, totals, 0, CV_REDUCE_SUM);

        Mat masksum;
        reduce(contour.mask, masksum, 0, CV_REDUCE_SUM);
        Mat means = totals / masksum;

        int step = self.samplingStep;
        int start = ((means.total() - 1) % step) / 2;

        for (int x = start; x < means.total(); x += step) {
            float meanValue = means.at<float>(x);
            cv::Point2d point = cv::Point2d(x + contour.bounds.origin.x, meanValue + contour.bounds.origin.y);
            contourPoints.push_back(point);
        }
    }

    cv::Size2d size = cv::Size2d(self.image.size.width, self.image.size.height);
    std::vector<cv::Point2d> normalizedPoints = vectors::pix2norm(size, contourPoints);
    spanPoints.push_back(normalizedPoints);

    NSMutableArray <NSValue *> *spanKeyPoints = @[].mutableCopy;
    for (int i = 0; i < spanPoints.size(); i++) {
        std::vector<cv::Point2d> ppts = spanPoints[i];
        for (int j = 0; j < ppts.size(); j++) {
            CGPoint point = CGPointMake(ppts[j].x, ppts[j].y);
            [spanKeyPoints addObject:[NSValue valueWithCGPoint:point]];
        }
    }
    return [NSArray arrayWithArray:spanKeyPoints];
}

- (NSArray <NSValue *> *)keyPoints {
    return nsarray::norm2pix(self.image.size, self.spanPoints);
}

- (LineInfo)spanLineInfoFromKeyPoints:(NSArray <NSValue *> *)keyPoints {
    Mat mean = Mat();
    Mat eigen = Mat();
    vector<Point2f> vectorPoints = nsarray::convertTo2f(keyPoints);
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
