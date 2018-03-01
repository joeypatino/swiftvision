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
    CGRectOutline outline = CGRectOutlineMake(CGPointMake(0, 0), CGPointMake(0, 0),
                                              CGPointMake(0, 0), CGPointMake(0, 0));
    [self keypointsFromSpanSamples:Mat() outline:outline samples:self.spanSamplePoints];

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
        //describe_vector(mask, "mask");
    }

//    bitwise_not(outImage, outImage);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)render {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode {
    BOOL fillConvexPolys = false;
    Scalar contourColor = [self scalarColorFrom:color];

    Mat outImage = Mat::zeros(self.inputImage.size.height, self.inputImage.size.width, CV_8UC1);
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

    int jj = 0;
    for (ContourSpan *s in spans) {
        jj += s.contours.count;
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
            //describe_vector(multi, "multi");

            Mat totals;
            cv::reduce(multi, totals, 0, CV_REDUCE_SUM);
            //describe_vector(totals, "totals");

            Mat masksum;
            cv::reduce(maskContour, masksum, 0, CV_REDUCE_SUM);
            //describe_vector(masksum, "masksum");

            Mat means = totals / masksum;
            //describe_vector(means, "means");

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

- (void)keypointsFromSpanSamples:(Mat)mask outline:(CGRectOutline)outline samples:(NSArray <NSArray <NSValue *> *> *)samples {
    float eigenInit[] = {0, 0};
    Mat allEigenVectors = Mat(1, 2, CV_32F, eigenInit);
    float allWeights = 0.0;

    for (NSArray <NSValue *> *pointValues in samples) {
        Mat mean = Mat();
        Mat eigen = Mat();
        std::vector<cv::Point2f> vectorPoints = std::vector<cv::Point2f>();
        for (NSValue *p in pointValues) {
            CGPoint pp = [p CGPointValue];
            vectorPoints.push_back(cv::Point2f(pp.x, pp.y));
        }
        Mat computePoints = Mat(vectorPoints).reshape(1);
        //describe_vector(computePoints, "points");

        PCACompute(computePoints, mean, eigen, 1);
        //describe_vector(eigen, "eigen");

        CGPoint first = pointValues.firstObject.CGPointValue;
        CGPoint last = pointValues.lastObject.CGPointValue;
        double weight = cv::norm(cv::Point2f(last.x - first.x, last.y - first.y));
        printf("weight:: %f\n", weight);

        Mat eigenMul = eigen.mul(weight);
        //describe_vector(eigenMul, "eigenMul");
        allEigenVectors += eigenMul;

        allWeights += weight;
    }

    //printf("allWeights:: %f\n", allWeights);
    //describe_vector(allEigenVectors, "allEigenVectors");

    Mat outEigenVec = allEigenVectors / allWeights;
    //describe_vector(outEigenVec, "outEigenVec");

    float eigenX = outEigenVec.at<float>(0, 0);
    float eigenY = outEigenVec.at<float>(0, 1);
    if (eigenX < 0) {
        eigenX *= -1;
        eigenY *= -1;
    }


//    cv::Point2f xDir = cv::Point2f(0.999594, 0.010234);
    cv::Point2f xDir = cv::Point2f(eigenX, eigenY);
    //printf("xDir:: {%f, %f}\n", xDir.x, xDir.y);

//    cv::Point2f yDir = cv::Point2f(-0.010234, 0.999594);
    cv::Point2f yDir = cv::Point2f(-eigenY, eigenX);
    //printf("yDir:: {%f, %f}\n", yDir.x, yDir.y);

//    CGSize sz = CGSizeMake(504, 672);
//    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:CGPointMake(504, 672)],
//                                 [NSValue valueWithCGPoint:CGPointMake(0, 672)],
//                                 [NSValue valueWithCGPoint:CGPointMake(0, 0)],
//                                 [NSValue valueWithCGPoint:CGPointMake(504, 0)]];

    CGSize sz = self.inputImage.size;
    CGRectOutline rectOutline = outlineWithSize(self.inputImage.size);
    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight]];
    //describe_points(pts, "pts");
    NSArray <NSValue *> *normalizedPts = pix2norm(sz, pts);
    //describe_points(normalizedPts, "normalizedPts");

    NSArray <NSNumber *> *pxCoords = ArrayOps::dotProduct(normalizedPts, xDir);
    //describe_values(pxCoords, "pxCoords");

    NSArray <NSNumber *> *pyCoords = ArrayOps::dotProduct(normalizedPts, yDir);
    //describe_values(pyCoords, "pyCoords");

    float px0 = [pxCoords min].floatValue;
    //printf("px0: %f \n", px0);
    float px1 = [pxCoords max].floatValue;
    //printf("px1: %f \n", px1);
    float py0 = [pyCoords min].floatValue;
    //printf("py0: %f \n", py0);
    float py1 = [pyCoords max].floatValue;
    //printf("py1: %f \n", py1);

    cv::Point2f p00 = px0 * xDir + py0 * yDir;
    //std::cout << p00 << std::endl;
    cv::Point2f p10 = px1 * xDir + py0 * yDir;
    //std::cout << p10 << std::endl;
    cv::Point2f p11 = px1 * xDir + py1 * yDir;
    //std::cout << p11 << std::endl;
    cv::Point2f p01 = px0 * xDir + py1 * yDir;
    //std::cout << p01 << std::endl;

//    corners = np.vstack((p00, p10, p11, p01)).reshape((-1, 1, 2))
//    NSArray <NSArray <NSValue *> *> *ss = @[ @[ [NSValue valueWithCGPoint:CGPointMake(-0.57738096, -0.9255953)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.53571427, -0.92410713)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.49404764, -0.9255953)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.45238096, -0.92261904)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.4107143,  -0.92410713)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.3690476, -0.9449405)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.32738096, -0.95535713)],
//                                              [NSValue valueWithCGPoint:CGPointMake(-0.2857143, -0.98214287)] ] ];

    NSMutableArray <NSNumber *> *ycoords = @[].mutableCopy;
    NSMutableArray <NSArray <NSNumber *> *> *xcoords = @[].mutableCopy;
    for (NSArray <NSValue *> *points in samples) {
        NSArray <NSNumber *> *pxCoords = ArrayOps::dotProduct(points, xDir);
        NSArray <NSNumber *> *pyCoords = ArrayOps::dotProduct(points, yDir);
        //describe_values(pxCoords, "pxcoords");
        //describe_values(pyCoords, "pycoords");

        float meany = [pyCoords median].floatValue;
        [ycoords addObject:[NSNumber numberWithFloat:meany - py0]];
        [xcoords addObject:ArrayOps::subtract(pxCoords, px0)];
    }

    //NSLog(@"xcoords: %@", xcoords);
    //NSLog(@"ycoords: %@", ycoords);
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
