#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
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

- (instancetype)initWithContours:(NSArray <Contour *> *)contours inImage:(UIImage *)image {
    self = [super init];
    self.inputImage = image;
    self.contours = contours;
    self.spans = [self spansFrom:self.contours];

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
        cv::Rect rect = cv::Rect(contour.bounds.origin.x, contour.bounds.origin.y, contour.bounds.size.width, contour.bounds.size.height);
        rectangle(outImage, rect, Scalar(255, 255, 255), -1);
    }

    bitwise_not(outImage, outImage);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)render {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    BOOL fillConvexPolys = false;
    Scalar contourColor = [self scalarColorFrom:color];

    Mat outImage = Mat::zeros(self.inputImage.size.height, self.inputImage.size.width, CV_8UC3);
    std::vector<std::vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];

        // start - debugging
        if (fillConvexPolys) {
            cv::Point vertices[4];
            [contour getBoundingVertices:vertices];
            fillConvexPoly(outImage, vertices, 4, [self scalarColorFrom:[UIColor whiteColor]]);
        }
        // end - debugging

        contours.push_back(contour.mat);
    }

    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -
- (NSArray<ContourSpan *> *)spansFrom:(NSArray<Contour *> *)contours {
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
        ContourSpan *curSpan = [[ContourSpan alloc] init];
        CGFloat width = 0;

        // follow successors til end of span
        while (contour) {
            // remove from list (sadly making this loop *also* O(n^2)
            [mutableContours removeObject:contour];
            // add to span
            [curSpan addContour:contour];

            width += contour.localxMax - contour.localxMin;

            // set successor
            contour = contour.next;
        }

        // add if long enough
        if (width > SPAN_MIN_WIDTH)
            [spans addObject:curSpan];
    }

    return spans;
}

- (Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}
@end
