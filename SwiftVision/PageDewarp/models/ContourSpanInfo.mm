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
    return CGSizeMake(pageWidth, pageHeight);
}

- (std::vector<double>)testDefaultParameters {
    cout << "OpenCV version : " << CV_VERSION << endl;
    cout << "Major version : " << CV_MAJOR_VERSION << endl;
    cout << "Minor version : " << CV_MINOR_VERSION << endl;
    cout << "Subminor version : " << CV_SUBMINOR_VERSION << endl;

    std::vector<cv::Point3d> corner_object3d = {
        cv::Point3d(0.00000000,0.00000000,0.00000000),
        cv::Point3d(1.52559066,0.00000000,0.00000000),
        cv::Point3d(1.52559066,2.01848703,0.00000000),
        cv::Point3d(0.00000000,2.01848703,0.00000000)
    };
    std::vector<cv::Point2d> corners = {
        cv::Point2d(-0.74919273,-1.01938189),
        cv::Point2d(0.77626074,-0.99892364),
        cv::Point2d(0.74919273,1.01938189),
        cv::Point2d(-0.77626074,0.99892364)
    };
    std::vector<cv::Point3d> camera = {
        cv::Point3d(1.8,0.0,0.0),
        cv::Point3d(0.0,1.8,0.0),
        cv::Point3d(0.0,0.0,1.0)
    };
    Mat K = Mat(3, 3, cv::DataType<double>::type, &camera);
    Mat rvec;
    Mat tvec;

    Mat inliers;
    cv::solvePnPRansac(corner_object3d,
                       corners,
                       K,
                       cv::Mat::zeros(5, 1, CV_64FC1),
                       rvec, tvec,
                       false,
                       500,
                       2.0,
                       0.95,
                       inliers,
                       cv::SOLVEPNP_ITERATIVE);
//    solvePnP(corner_object3d,
//             corners,
//             K,
//             vector<double>({0, 0, 0, 0, 0}),
//             rvec,
//             tvec, true, SOLVEPNP_DLS);

    logs::describe_vector(corner_object3d, "corner_object3d");
    logs::describe_vector(corners, "corners");
    logs::describe_vector(camera, "K");
    logs::describe_vector(rvec, "rvec");
    logs::describe_vector(tvec, "tvec");

    /**
     expected rvec:
     --------------
     [-0.00000000]
     [0.00000000]
     [0.01341045]

     expected tvec:
     --------------
     [-0.74919273]
     [-1.01938189]
     [1.79999995]
     */
    return {};
}

- (NSArray <NSNumber *> *)defaultParameters {
    CGSize dimensions = self.roughDimensions;

    // Array of object points in the object coordinate space
    vector<Point3d> cornersObject3d = {
        Point3d(0, 0, 0),
        Point3d(dimensions.width, 0, 0),
        Point3d(dimensions.width, dimensions.height, 0),
        Point3d(0, dimensions.height, 0)};

    // Array of corresponding image points
    vector<Point2d> imagePoints = nsarray::convertTo2d(nsarray::pointsFrom(self.corners));

    std::vector<cv::Point3d> camera = {
        cv::Point3d(1.8,0.0,0.0),
        cv::Point3d(0.0,1.8,0.0),
        cv::Point3d(0.0,0.0,1.0)
    };
    Mat K = Mat(3, 3, cv::DataType<double>::type, &camera);

    // output rotation vectors
    vector<double> rvec;
    // output translation vectors
    vector<double> tvec;

    // estimate rotation and translation from four 2D-to-3D point correspondences
    solvePnP(cornersObject3d, imagePoints,
             K,
             Mat::zeros(5, 1, cv::DataType<double>::type),
             rvec,
             tvec);

    // our initial guess for the cubic has no slope
    vector<double> cubicSlope = vector<double>({0.0, 0.0});

    rvec = {
        -0.00000000,
        0.00000000,
        0.01341045
    };
    tvec = {
        -0.74919273,
        -1.01938189,
        1.79999995
    };
    vector<double> params;
    for (int i = 0; i < int(rvec.size()); i++) {
        params.push_back(rvec[i]);
    }
    for (int i = 0; i < int(tvec.size()); i++) {
        params.push_back(tvec[i]);
    }
    for (int i = 0; i < int(cubicSlope.size()); i++) {
        params.push_back(cubicSlope[i]);
    }

    for (NSNumber *number in self.yCoordinates) {
        params.push_back(number.floatValue);
    }

    for (NSArray <NSNumber *> *numbers in self.xCoordinates) {
        for (NSNumber *number in numbers) {
            params.push_back(number.floatValue);
        }
    }

    NSMutableArray <NSNumber *> *outputParams = @[].mutableCopy;
    for (int i = 0; i < int(params.size()); i++) {
        [outputParams addObject:@(params[i])];
    }

    //logs::describe_vector(cornersObject3d, "cornersObject3d");
    //logs::describe_vector(imagePoints, "corners");
    //logs::describe_vector(camera, "K");
    //logs::describe_vector(rvec, "rvec");
    //logs::describe_vector(tvec, "tvec");

    return outputParams;
}

- (NSArray <NSNumber *> *)spanCounts {
    NSMutableArray *counts = @[].mutableCopy;
    for (NSArray <NSNumber *> *xPoints in self.xCoordinates) {
        [counts addObject:[NSNumber numberWithInteger:xPoints.count]];
    }
    return [NSArray arrayWithArray:counts];
}

- (NSArray <NSValue *> *)keyPointIndexesForSpanCounts:(NSArray <NSNumber *> *)spanCounts {
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
    //logs::describe_points(vectors::convertTo(keyPointIdx), "keyPointIdx");

    return vectors::convertTo(keyPointIdx);
}

- (NSArray <NSValue *> *)destinationPoints:(NSArray <NSArray <NSValue *> *> *)spanPoints {
    NSMutableArray <NSValue *> *destinationPoints = @[].mutableCopy;
    [destinationPoints addObject:[NSValue valueWithCGPoint:self.corners.topLeft]];
    [destinationPoints addObjectsFromArray:[spanPoints valueForKeyPath: @"@unionOfArrays.self"]];
    return [NSArray arrayWithArray:destinationPoints];
}

@end
