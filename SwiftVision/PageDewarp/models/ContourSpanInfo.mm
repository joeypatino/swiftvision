#import <opencv2/opencv.hpp>
#include <numeric>
#import "ContourSpanInfo.h"
// structs
#import "CGRectOutline.h"
// private
#import "ContourSpanInfo+internal.h"
// extras
#import "functions.h"

@implementation ContourSpanInfo
- (instancetype)initWithCorners:(CGRectOutline)corners
                   xCoordinates:(std::vector<std::vector<double>>)xCoordinates
                   yCoordinates:(std::vector<double>)yCoordinates {
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
    cv::Mat K = Mat(3, 3, cv::DataType<double>::type, &camera);
    cv::Mat rvec;
    cv::Mat tvec;

    cv::Mat inliers;
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

- (std::vector<double>)defaultParameters {
    CGSize dimensions = self.roughDimensions;

    // Array of object points in the object coordinate space
    std::vector<cv::Point3d> cornersObject3d = {
        cv::Point3d(0, 0, 0),
        cv::Point3d(dimensions.width, 0, 0),
        cv::Point3d(dimensions.width, dimensions.height, 0),
        cv::Point3d(0, dimensions.height, 0)};

    // Array of corresponding image points
    std::vector<cv::Point2d> imagePoints = nsarray::convertTo2d(nsarray::pointsFrom(self.corners));

    std::vector<cv::Point3d> camera = {
        cv::Point3d(1.8,0.0,0.0),
        cv::Point3d(0.0,1.8,0.0),
        cv::Point3d(0.0,0.0,1.0)
    };

    // output rotation vectors
    std::vector<double> rvec;
    // output translation vectors
    std::vector<double> tvec;

    // estimate rotation and translation from four 2D-to-3D point correspondences
    cv::solvePnP(cornersObject3d,
             imagePoints,
             cv::Mat(3, 3, cv::DataType<double>::type, &camera),
             cv::Mat::zeros(5, 1, cv::DataType<double>::type),
             rvec,
             tvec);

    // our initial guess for the cubic has no slope
    std::vector<double> cubicSlope = std::vector<double>({0.0, 0.0});

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
    std::vector<double> params;
    for (int i = 0; i < int(rvec.size()); i++) {
        params.push_back(rvec[i]);
    }
    for (int i = 0; i < int(tvec.size()); i++) {
        params.push_back(tvec[i]);
    }
    for (int i = 0; i < int(cubicSlope.size()); i++) {
        params.push_back(cubicSlope[i]);
    }
    for (int i = 0; i < self.yCoordinates.size(); i++) {
        params.push_back(self.yCoordinates[i]);
    }
    for (int i = 0; i < self.xCoordinates.size(); i++) {
        std::vector<double> values = self.xCoordinates[i];
        for (int j = 0; j < values.size(); j++) {
            params.push_back(values[j]);
        }
    }

    //logs::describe_vector(cornersObject3d, "cornersObject3d");
    //logs::describe_vector(imagePoints, "corners");
    //logs::describe_vector(camera, "K");
    //logs::describe_vector(rvec, "rvec");
    //logs::describe_vector(tvec, "tvec");

    return params;
}

- (std::vector<int>)spanCounts {
    std::vector<int> counts;
    for (int i = 0; i < self.xCoordinates.size(); i++) {
        std::vector<double> values = self.xCoordinates[i];
        counts.push_back(int(values.size()));
    }
    return counts;
}

- (std::vector<cv::Point2d>)keyPointIndexesForSpanCounts:(std::vector<int>)spanCounts {
    int npts = std::accumulate(spanCounts.begin(), spanCounts.end(), 0);
    std::vector<std::vector<int>> keyPointIdx = std::vector<std::vector<int>>(2, std::vector<int>(npts+1, 0));
    int start = 1;
    for (int i = 0; i < spanCounts.size(); i++) {
        int count = spanCounts[i];
        int end = start + count;
        for (int r = start; r < end; r++) {
            keyPointIdx[1][r] = 8+i;
        }
        start = end;
    }

    for (int i = 0; i < npts; i++) {
        keyPointIdx[0][i+1] = i + 8 + int(spanCounts.size());
    }
    std::vector<cv::Point2d> keypoints;
    keypoints.reserve(npts+1);
    for (int i = 0; i < npts+1; i++) {
        cv::Point2d kp = cv::Point2d(keyPointIdx[0][i], keyPointIdx[1][i]);
        keypoints.push_back(kp);
    }
    return keypoints;
}

- (std::vector<cv::Point2d>)destinationPoints:(std::vector<std::vector<cv::Point2d>>)spanPoints {
    std::vector<cv::Point2d> destinationPoints;
    destinationPoints.push_back(cv::Point2d(self.corners.topLeft.x, self.corners.topLeft.y));

    for (int i = 0; i < spanPoints.size(); i++) {
        std::vector<cv::Point2d> points = spanPoints[i];
        for (int j = 0; j < points.size(); j++) {
            destinationPoints.push_back(points[j]);
        }
    }
    return destinationPoints;
}

@end
