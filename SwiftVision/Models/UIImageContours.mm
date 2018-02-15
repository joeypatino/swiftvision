#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithCVMat:(cv::Mat)cvMat NS_DESIGNATED_INITIALIZER;
- (void)vertices:(cv::Point *)pts;
- (cv::Mat)tightMask;
@end

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, assign) cv::Mat inputImage;
@end

using namespace std;
using namespace cv;

@implementation UIImageContours
// MARK: -
- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    self.image = image;
    self.inputImage = [self grayScaleMat:image];
    self.contours = [self processContours: self.inputImage];

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

- (UIImage *)renderMasks:(BOOL (^)(Contour *c))filter {
    cv::Mat outImage = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC1);
    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        cv::Mat mask = contour.tightMask;
        cv::Rect rect = cv::Rect(contour.bounds.origin.x, contour.bounds.origin.y, contour.bounds.size.width, contour.bounds.size.height);
        cv::rectangle(outImage, rect, cv::Scalar(255, 255, 255), -1);
    }

    cv::bitwise_not(outImage, outImage);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)render:(BOOL (^)(Contour *c))filter {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline filtered:filter];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode filtered:(BOOL (^)(Contour *c))filter {
    BOOL fillConvexPolys = false;
    cv::Scalar contourColor = [self scalarColorFrom:color];

    cv::Mat outImage = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC3);
    cv::Mat hull = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC1);
    std::vector<std::vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        if (filter)
            if (!filter(contour))
                continue;

        if (fillConvexPolys) {
            cv::Point vertices[4];
            [contour vertices:vertices];
            cv::fillConvexPoly(outImage, vertices, 4, [self scalarColorFrom:[UIColor whiteColor]]);
        }
        contours.push_back(contour.mat);
    }

    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    cv::drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -

- (NSArray<Contour *> *)processContours:(cv::Mat)cvMat {
    NSMutableArray <Contour *> *foundContours = @[].mutableCopy;
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(cvMat, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    for (int j = 0; j < contours.size(); j++) {
        std::vector<cv::Point> contour = contours.at(j);
        if (contour.empty()) continue;
        [foundContours addObject:[[Contour alloc] initWithCVMat:cv::Mat(contour)]];
    }

    return foundContours;
}

- (NSArray<ContourSpan *> *)assembleSpans {
    /// def assemble_spans(name, small, pagemask, cinfo_list)

    NSArray *sortedContours = [self.contours sortedArrayUsingComparator:^NSComparisonResult(Contour *obj1, Contour *obj2){

        if (CGRectGetMinY(obj1.bounds) < CGRectGetMinY(obj2.bounds))
            return NSOrderedAscending;
        else if (CGRectGetMinY(obj2.bounds) < CGRectGetMinY(obj1.bounds))
            return NSOrderedDescending;

        return NSOrderedSame;
    }];

    // generate all candidate edges
    NSMutableArray <ContourEdge *> *candidateEdges = @[].mutableCopy;

    NSInteger contourCount = sortedContours.count;
    for (int i = 0; i < contourCount; i++) {
        Contour *currentContour = sortedContours[i];

        for (int j = 0; j < contourCount; j++) {
            Contour *adjacentContour = sortedContours[j];

            // note e is of the form (score, left_cinfo, right_cinfo)
            ContourEdge *edge = [currentContour generateEdge:adjacentContour];
            if (edge)
                [candidateEdges addObject:edge];
        }
    }

    // sort candidate edges by score (lower is better)
    // candidateEdges.sort()

    return @[];
}

- (cv::Mat)grayScaleMat:(UIImage *)image {
    cv::Mat inputImage = [image mat];
    cv::Mat outImage;
    cv::cvtColor(inputImage, outImage, cv::COLOR_RGB2GRAY);

    return outImage;
}

- (cv::Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return cv::Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

@end







