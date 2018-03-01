#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"
#import "functions.h"
#import "UIImage+Mat.h"
#import "UIImageContours.h"
#import "Contour+internal.h"

@interface Contour ()
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype)initWithCVMat:(cv::Mat)cvMat;
@end

@interface UIImageContours ()
- (instancetype _Nonnull)initWithContours:(NSArray <Contour *> *_Nonnull)contours spans:(NSArray <ContourSpan *> *)spans inImage:(UIImage *_Nonnull)image NS_DESIGNATED_INITIALIZER;
@end

@implementation UIImage (OpenCV)
- (UIImage *)resizeTo:(CGSize)size {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;
    cv::Size axis = cv::Size(0, 0);

    float scl_x = float(self.size.width) / size.width;
    float scl_y = float(self.size.height) / size.height;
    float scl = 1.0 / fmaxf(scl_x, scl_y);

    cv::resize(inImage, outImage, axis, scl, scl, cv::INTER_AREA);

    return [[UIImage alloc] initWithCVMat: outImage];
}

/**
 @param blockSize Size of a pixel neighborhood that is used to calculate a threshold value for the
 pixel: 3, 5, 7, and so on.
 @param constant Constant subtracted from the mean or weighted mean (see the details below). Normally, it
 is positive but may be zero or negative as well.
 */
- (UIImage *)threshold:(float)blockSize constant:(float)constant {
    cv::Mat inImage = [self mat];
    cv::Mat grayImage;
    cv::Mat outImage;

    // convert to GRAYSCALE
    cv::cvtColor(inImage, grayImage, cv::COLOR_RGBA2GRAY);
    cv::adaptiveThreshold(grayImage, outImage,
                          255.0,
                          cv::ADAPTIVE_THRESH_MEAN_C,
                          cv::THRESH_BINARY_INV, blockSize, constant);

    // revert to RGBA
    cv::cvtColor(outImage, outImage, cv::COLOR_GRAY2RGBA);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)dilate:(CGSize)kernelSize {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;

    cv::Mat dilateKernel = cv::Mat::ones(kernelSize.height, kernelSize.width, CV_8UC1);
    cv::dilate(inImage, outImage, dilateKernel);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)erode:(CGSize)kernelSize {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;

    cv::Mat erodeKernel = cv::Mat::ones(kernelSize.height, kernelSize.width, CV_8UC1);
    cv::erode(inImage, outImage, erodeKernel);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)elementwiseMinimum:(UIImage *)img {
    cv::Mat inImage = [self mat];
    cv::Mat compImage = [img mat];

    cv::MatExpr expr = cv::min(inImage, compImage);
    cv::Mat outImage = cv::Mat(expr);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -
- (UIImageContours *)contoursFilteredBy:(BOOL (^)(Contour * c))filter {
    NSArray <Contour *> *contours = [self generateContoursFilteredBy:filter];
    NSArray <ContourSpan *> *spans = [self generateSpansFrom:contours];
    return [[UIImageContours alloc] initWithContours:contours spans:spans inImage:self];
}

- (NSArray<Contour *> *)generateContoursFilteredBy:(BOOL (^)(Contour *c))filter {
    cv::Mat cvMat = [self grayScaleMat];
    NSMutableArray <Contour *> *foundContours = @[].mutableCopy;
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(cvMat, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    for (int j = 0; j < contours.size(); j++) {
        std::vector<cv::Point> points = contours.at(j);
        int pointCnt = int(points.size());
        cv::Mat contourMat = cv::Mat(points).reshape(2, pointCnt);

        if (cv::contourArea(contourMat) == 0) continue;

        Contour *contour = [[Contour alloc] initWithCVMat:contourMat];
        if (filter)
            if (!filter(contour))
                continue;

        [foundContours addObject:contour];
    }

    return foundContours;
}

- (NSArray<ContourSpan *> *)generateSpansFrom:(NSArray<Contour *> *)contours {
    CGFloat SPAN_MIN_WIDTH = 16;
    NSArray *sortedContours = [contours sortedArrayUsingComparator:^NSComparisonResult(Contour *obj1, Contour *obj2){
        if (CGRectGetMinY(obj1.bounds) < CGRectGetMinY(obj2.bounds))
            return NSOrderedAscending;
        else if (CGRectGetMinY(obj1.bounds) > CGRectGetMinY(obj2.bounds))
            return NSOrderedDescending;

        return NSOrderedSame;
    }];

    // generate all candidate edges
    NSMutableArray <ContourEdge *> *candidateEdges = @[].mutableCopy;

    NSInteger contourCount = sortedContours.count;
    for (int i = 0; i < contourCount; i++) {
        Contour *currentContour = sortedContours[i];
        for (int j = 0; j < i; j++) {
            Contour *adjacentContour = sortedContours[j];
            ContourEdge *edge = [currentContour contourEdgeWithAdjacentContour:adjacentContour];
            if (edge)
                [candidateEdges addObject:edge];
        }
    }

    [candidateEdges sortUsingComparator:^NSComparisonResult(ContourEdge *edge1, ContourEdge *edge2){
        if (edge1.score < edge2.score) return NSOrderedAscending;
        else if (edge1.score > edge2.score) return NSOrderedDescending;

        return NSOrderedSame;
    }];

    for (ContourEdge *edge in candidateEdges) {
        // if left and right are unassigned, join them
        if (!edge.contourA.next && !edge.contourB.previous) {
            edge.contourA.next = edge.contourB;
            edge.contourB.previous = edge.contourA;
        }
    }

    // generate list of spans as output
    NSMutableArray <ContourSpan *> *spans = @[].mutableCopy;

    NSMutableArray *mutableContours = sortedContours.mutableCopy;
    // until we have removed everything from the list
    while (mutableContours.count > 0) {
        // get the first on the list
        Contour *contour = mutableContours[0];

        // keep following predecessors until none exists
        while (contour.previous)
            contour = contour.previous;

        // start a new span
        NSMutableArray <Contour *> *curSpan = @[].mutableCopy;
        CGFloat width = 0;

        // follow successors til end of span
        while (contour) {
            // remove from list (sadly making this loop *also* O(n^2)
            [mutableContours removeObject:contour];
            // add to span

            [curSpan addObject:contour];

            width += contour.localxMax - contour.localxMin;

            // set successor
            contour = contour.next;
        }

        // add if long enough
        if (width > SPAN_MIN_WIDTH) {
            ContourSpan *span = [[ContourSpan alloc] initWithImage:self contours:curSpan];
            [spans addObject:span];
        }
    }

    return spans;
}

@end

