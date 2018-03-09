#import <opencv2/opencv.hpp>
#import "ContourSpanInfo.h"
// structs
#import "CGRectOutline.h"
// private
#import "ContourSpanInfo+internal.h"
// extras
#import "functions.h"

using namespace std;
using namespace cv;

@implementation ContourSpanInfo
- (instancetype)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(NSArray <NSArray <NSNumber *> *> *)xCoordinates
                            yCoordinates:(NSArray <NSNumber *> *)yCoordinates {
    self = [super init];
    _corners = corners;
    _xCoordinates = xCoordinates;
    _yCoordinates = yCoordinates;
    return self;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@",\n [%@, \n%@, \n%@, \n%@]",
     NSStringFromCGPoint(self.corners.topLeft),
     NSStringFromCGPoint(self.corners.topRight),
     NSStringFromCGPoint(self.corners.botRight),
     NSStringFromCGPoint(self.corners.botLeft)];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}

- (CGSize)roughDimensions {
    CGPoint w = geom::subtract(self.corners.topRight, self.corners.topLeft);
    CGPoint h = geom::subtract(self.corners.botLeft, self.corners.topLeft);
    double pageWidth = norm(Mat(geom::convertTo(w)));
    double pageHeight = norm(Mat(geom::convertTo(h)));
    return CGSizeMake(pageHeight, pageWidth);
}

- (NSArray <NSNumber *> *)defaultParameters {
    CGSize dimensions = self.roughDimensions;

    // Array of object points in the object coordinate space
    vector<Point3f> cornersObject3d = {
        Point3f(0, 0, 0),
        Point3f(dimensions.width, 0, 0),
        Point3f(dimensions.width, dimensions.height, 0),
        Point3f(0, dimensions.height, 0)};
    //logs::describe_vector(cornersObject3d, "cornersObject3d");

    // Array of corresponding image points
    vector<Point2f> imagePoints = nsarray::convertTo2f(nsarray::pointsFrom(self.corners));
    //logs::describe_vector(imagePoints, "imagePoints");

    // Input camera matrix
    float FOCAL_LENGTH = 1.8;
    vector<Point3f> camera = { Point3f(FOCAL_LENGTH, 0, 0),
        Point3f(0, FOCAL_LENGTH, 0),
        Point3f(0, 0, 1) };
    //logs::describe_vector(camera, "camera");

    // Input vector of distortion coefficients
    vector<float> distanceCoeffs = {0.0, 0.0, 0.0, 0.0, 0.0};

    // output rotation vectors
    Mat rvec;
    // output translation vectors
    Mat tvec;
    // estimate rotation and translation from four 2D-to-3D point correspondences
    solvePnP(cornersObject3d, imagePoints, Mat(3, 3, CV_32F, &camera), Mat(5, 1, CV_32F, &distanceCoeffs), rvec, tvec);

    //logs::describe_vector(rvec, "rvec");
    //logs::describe_vector(tvec, "tvec");

    // our initial guess for the cubic has no slope
    vector<float> cubicSlope = vector<float>({0.0, 0.0});

    Mat params = Mat();
    params.push_back(rvec);
    params.push_back(tvec);
    params.push_back(cubicSlope);

    for (NSNumber *number in self.yCoordinates) {
        params.push_back(number.floatValue);
    }

    for (NSArray <NSNumber *> *numbers in self.xCoordinates) {
        for (NSNumber *number in numbers) {
            params.push_back(number.floatValue);
        }
    }

    //logs::describe_vector(params, "params");
    NSMutableArray <NSNumber *> *outputParams = @[].mutableCopy;
    for (int i = 0; i < params.total(); i++) {
        NSNumber *value = [NSNumber numberWithFloat:params.at<float>(i, 0)];
        [outputParams addObject:value];
    }

    return outputParams;
}

- (NSArray <NSNumber *> *)spanCounts {
    NSMutableArray *counts = @[].mutableCopy;
    for (NSArray <NSNumber *> *xPoints in self.xCoordinates) {
        [counts addObject:[NSNumber numberWithInteger:xPoints.count]];
    }
    return [NSArray arrayWithArray:counts];
}

- (NSArray <NSValue *> *)keyPointIndexesForSpanCounts:(NSArray <NSNumber *> *)_spanCounts {

    int vals[] = {7, 2, 13, 27, 26, 27, 27, 27, 27, 28, 27, 27, 11, 16, 26, 27, 25, 2, 26, 28, 6, 22, 24, 2, 24, 3, 27, 25, 25, 26, 2, 27};
    int vals_sz = sizeof(vals) / sizeof(int);
    NSMutableArray <NSNumber *> *spanCounts = @[].mutableCopy;
    for (int i = 0; i < vals_sz; i++) {
        [spanCounts addObject:[NSNumber numberWithInt:vals[i]]];
    }

    NSNumber *nptsNum = [spanCounts valueForKeyPath:@"@sum.self"];
    int npts = nptsNum.intValue;

    vector<vector<int>> keyPointIdx = vector<vector<int>>(2, vector<int>(npts+1, 0));
    int start = 1;
    for (int i = 0; i < spanCounts.count; i++) {
        int count = spanCounts[i].intValue;
        int end = start + count;
        for (int r = start; r < end; r++) {
            keyPointIdx[1][r] = 8+i;
        }
        start = end;
    }
    for (int i = 0; i < npts; i++) {
        keyPointIdx[0][i+1] = i + 8 + int(spanCounts.count);
    }
    //logs::describe_vector(keyPointIdx, "keyPointIdx");

    return vectors::convertTo(keyPointIdx);
}

- (NSArray <NSValue *> *)destinationPoints:(NSArray <NSArray <NSValue *> *> *)spanPoints {
    NSMutableArray <NSValue *> *destinationPoints = @[].mutableCopy;
    [destinationPoints addObject:[NSValue valueWithCGPoint:self.corners.topLeft]];
    [destinationPoints addObjectsFromArray:[spanPoints valueForKeyPath: @"@unionOfArrays.self"]];
    return [NSArray arrayWithArray:destinationPoints];
}

@end
