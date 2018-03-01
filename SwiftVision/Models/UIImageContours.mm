#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "functions.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"
#import "Contour+internal.h"
#import "NSArray+extras.h"

using namespace std;
using namespace cv;

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *inputImage;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, strong) NSArray<ContourSpan *> *spans;
@property (nonatomic, strong) NSArray <NSArray<NSValue *> *> *spanSamplePoints;
@end


NSArray<NSValue *> * pix2norm(CGSize size, NSArray<NSValue *> *pts) {
    float height = size.height;
    float width = size.width;
    float scale = 2.0 / MAX(height, width);
    CGSize offset = CGSizeMake(width * 0.5, height * 0.5);

    NSMutableArray<NSValue *> *mutatedPts = @[].mutableCopy;
    for (NSValue *pt in pts) {
        CGPoint point = [pt CGPointValue];
        CGPoint mutatedPoint = CGPointMake((point.x - offset.width) * scale, (point.y - offset.height) * scale);
        [mutatedPts addObject:[NSValue valueWithCGPoint:mutatedPoint]];
    }
    return mutatedPts;
}

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

    self.spanSamplePoints = [self sampleSpanPoints:self.spans];
    [self keypointsFromSpanSamples:self.spanSamplePoints];

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

- (NSArray <NSArray <NSValue *> *> *)sampleSpanPoints:(NSArray <ContourSpan *> *)spans {
    NSMutableArray <NSArray <NSValue *> *> *spanPoints = @[].mutableCopy;

    for (ContourSpan *span in spans) {
        NSMutableArray <NSValue *> *contourPoints = @[].mutableCopy;
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

            NSArray <NSValue *> *normalizedPoints = pix2norm(self.inputImage.size, contourPoints);
            [spanPoints addObject:normalizedPoints];
        }
    }

    return spanPoints;
}

- (void)keypointsFromSpanSamples:(NSArray <NSArray <NSValue *> *> *)samples {
    float eigenInit[] = {0, 0};
    Mat allEigenVectors = Mat(1, 2, CV_32F, eigenInit);
    float allWeights = 0.0;

    for (NSArray <NSValue *> *pointValues in samples) {
        Mat mean = Mat();
        Mat eigen = Mat();
        vector<Point2f> vectorPoints = vector<Point2f>();
        for (NSValue *p in pointValues) {
            vectorPoints.push_back(geom::pointFrom(p.CGPointValue));
        }
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

    CGSize sz = self.inputImage.size;
    CGRectOutline rectOutline = geom::outlineWithSize(self.inputImage.size);
    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight]];
    NSArray <NSValue *> *normalizedPts = pix2norm(sz, pts);
    NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(normalizedPts, xDir);
    NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(normalizedPts, yDir);

    float px0 = [pxCoords min].floatValue;
    float px1 = [pxCoords max].floatValue;
    float py0 = [pyCoords min].floatValue;
    float py1 = [pyCoords max].floatValue;

    Point2f p00 = px0 * xDir + py0 * yDir;
    Point2f p10 = px1 * xDir + py0 * yDir;
    Point2f p11 = px1 * xDir + py1 * yDir;
    Point2f p01 = px0 * xDir + py1 * yDir;

    // tl, tr, br, bl
    CGRectOutline corners = CGRectOutlineMake(geom::pointFrom(p00),
                                              geom::pointFrom(p10),
                                              geom::pointFrom(p11),
                                              geom::pointFrom(p01));

    NSMutableArray <NSNumber *> *ycoords = @[].mutableCopy;
    NSMutableArray <NSArray <NSNumber *> *> *xcoords = @[].mutableCopy;
    for (NSArray <NSValue *> *points in samples) {
        NSArray <NSNumber *> *pxCoords = nsarray::dotProduct(points, xDir);
        NSArray <NSNumber *> *pyCoords = nsarray::dotProduct(points, yDir);
        float meany = [pyCoords median].floatValue;
        [ycoords addObject:[NSNumber numberWithFloat:meany - py0]];
        [xcoords addObject:nsarray::subtract(pxCoords, px0)];
    }
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
