#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "functions.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "Contour+internal.h"

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
    for (ContourSpan *span in self.spans) {
        NSLog(@"%@", span);
    }
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    BOOL fillConvexPolys = false;
    Scalar contourColor = [self scalarColorFrom:color];

    Mat outImage = Mat::zeros(self.inputImage.size.height, self.inputImage.size.width, CV_8UC1);
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
