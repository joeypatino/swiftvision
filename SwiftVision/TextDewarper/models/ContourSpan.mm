#import <opencv2/opencv.hpp>
#import "ContourSpan.h"
// models
#import "Contour.h"
// private
#import "ContourSpan+internal.h"
#import "Contour+internal.h"
// extras
#import "UIColor+extras.h"
#import "vectors.hpp"

using namespace cv;

@implementation ContourSpan
- (instancetype)initWithImage:(UIImage *)image contours:(NSArray <Contour *> *)contours {
    self = [super init];
    _samplingStep = 20;
    _color = [UIColor randomColor];
    _image = image;
    _contours = contours;
    _spanPoints = [self sampleSpanPointsFrom:self.contours];
    _boundingBox = [self calculateBoundingBoxFrom:self.contours];

    return self;
}

- (void)dealloc {

}

- (CGRect)calculateBoundingBoxFrom:(NSArray <Contour *> *)contours {
    CGRect rect = CGRectZero;
    for (Contour *contour in contours) {
        if (CGRectEqualToRect(rect, CGRectZero))
            rect = contour.bounds;

        rect = CGRectUnion(rect, contour.bounds);
    }
    return rect;
}

- (std::vector<Point2d>)sampleSpanPointsFrom:(NSArray <Contour *> *)contours {
    std::vector<Point2d> contourPoints;
    std::vector<std::vector<Point2d>> spanPoints;
    for (Contour *contour in contours) {
        Mat mask = contour.mask.clone();
        std::vector<double> points = vectors::linspace(0, mask.rows-1, mask.rows);
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
            Point2d point = Point2d(x + contour.bounds.origin.x, meanValue + contour.bounds.origin.y);
            contourPoints.push_back(point);
        }
    }

    Size2d size = Size2d(self.image.size.width, self.image.size.height);
    std::vector<Point2d> normalizedPoints = vectors::pix2norm(size, contourPoints);
    spanPoints.push_back(normalizedPoints);

    std::vector<Point2d> spanKeyPoints = std::vector<Point2d>();
    for (int i = 0; i < spanPoints.size(); i++) {
        std::vector<Point2d> ppts = spanPoints[i];
        for (int j = 0; j < ppts.size(); j++) {
            spanKeyPoints.push_back(ppts[j]);
        }
    }
    return spanKeyPoints;
}

- (std::vector<Point2d>)keyPoints {
    return vectors::norm2pix(Size2d(self.image.size.width, self.image.size.height), self.spanPoints);
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}
@end
