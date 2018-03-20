#import <opencv2/opencv.hpp>
#include <numeric>
#import "PageDewarp.h"
// models
#import "ImageRemapper.h"
// private
#import "Contour+internal.h"
#import "ContourSpan+internal.h"
#import "ImageRemapper+internal.h"
// extras
#import "functions.h"
//#import "NSArray+extras.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Contour.h"
#import "UIColor+extras.h"
// structs
//#import "EigenVector.h"
#import "LineInfo.h"
#import "CGRectOutline.h"

using namespace std;
using namespace cv;

@interface PageDewarp ()
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@end

// MARK: -
@implementation PageDewarp
- (instancetype)initWithImage:(UIImage *)image filteredBy:(BOOL (^)(Contour *c))filter {
    self = [super init];
    self.inputImage = image;
    self.workingImage = [image resizeTo:CGSizeMake(1280, 700)];

    UIImage *mask = [[[self.workingImage threshold:55 constant:25] dilate:CGSizeMake(9, 1)] erode:CGSizeMake(1, 3)];
    self.contours = [mask contoursFilteredBy:filter];;
    self.spans = [mask spansFromContours:self.contours];;

    return self;
}

// MARK: - render dewarped image
- (UIImage *)render {
    std::vector<std::vector<cv::Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    ImageRemapper *remapper = [[ImageRemapper alloc] initWithOriginalImage:self.inputImage
                                                              workingImage:self.workingImage
                                                        remappingKeypoints:allSpanPoints];
    return [remapper remap];
}

// MARK: - Debug
- (UIImage *)renderMasks {
   return [self render:[UIColor blackColor] mode:ContourRenderingModeFill];
}

- (UIImage *)renderContours {
    cv::Mat display = [self.workingImage mat];
    vector<vector<cv::Point>> contours;
    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        contours.push_back(contour.opencvContour);
    }
    for (int i = 0; i < contours.size(); i++) {
        Contour *contour = self.contours[i];
        cv::Scalar color = [self scalarColorFrom:contour.color];
        cv::drawContours(display, contours, i, color, -1);
    }

    cv::Mat output = [self.workingImage mat];
    cv::addWeighted(display, 0.7, output, 0.3, 0, output);
    for (Contour *contour in self.contours) {
        cv::Scalar color = [self scalarColorFrom:[UIColor whiteColor]];
        cv::circle(output, geom::convertTo(contour.center), 3, color, 1, cv::LINE_AA);
        cv::line(output, geom::convertTo(contour.clxMin), geom::convertTo(contour.clxMax), color, 1, cv::LINE_AA);
    }

    return [[UIImage alloc] initWithCVMat:output];
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
    cv::Mat display = [self.workingImage mat];

    for (ContourSpan *span in self.spans) {
        cv::Point2f start = geom::convertTo(span.line.p1);
        cv::Point2f end = geom::convertTo(span.line.p2);
        cv::line(display, start, end, [self scalarColorFrom:color], 1, cv::LINE_AA);

        for (NSValue *keyPoint in span.keyPoints) {
            BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
            cv::circle(display, geom::convertTo(keyPoint.CGPointValue), 3, [self scalarColorFrom:span.color], filled ? -1 : 1, cv::LINE_AA);
        }
    }

    return [[UIImage alloc] initWithCVMat:display];
}

- (UIImage *)renderPreCorrespondences {
    std::vector<std::vector<cv::Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    ImageRemapper *remapper = [[ImageRemapper alloc] initWithOriginalImage:self.inputImage
                                                              workingImage:self.workingImage
                                                        remappingKeypoints:allSpanPoints];
    return [remapper preCorrespondenceKeyPoints];
}

- (UIImage *)renderPostCorrespondences {
    std::vector<std::vector<cv::Point2d>> allSpanPoints = [self allSamplePoints:self.spans];
    ImageRemapper *remapper = [[ImageRemapper alloc] initWithOriginalImage:self.inputImage
                                                              workingImage:self.workingImage
                                                        remappingKeypoints:allSpanPoints];
    return [remapper postCorresponenceKeyPoints];
}

// MARK: - Render helpers
- (cv::Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return cv::Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

- (std::vector<vector<cv::Point2d>>)allSamplePoints:(NSArray <ContourSpan *> *)spans {
    std::vector<vector<cv::Point2d>> allPoints;
    for (ContourSpan *span in spans) {
        std::vector<Point2d> samplePoints;
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
