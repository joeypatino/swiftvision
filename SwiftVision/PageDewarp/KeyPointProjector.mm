#import "KeyPointProjector.h"
#import "functions.h"

std::vector<double> axis(int x, std::vector<cv::Point2f> points) {
    std::vector<double> v;
    for (int i = 0; i < points.size(); i++) {
        cv::Point2f p = points[i];
        if (x == 0) {
            v.push_back(p.x);
        } else if (x == 1) {
            v.push_back(p.y);
        }
    }
    return v;
}

std::vector<std::vector<double>> convert_to_vector2d(std::vector<cv::Point2f> points) {
    std::vector<std::vector<double>> v(points.size(), std::vector<double>(2, 0));
    for (int i = 0; i < points.size(); i++) {
        cv::Point2f point = points[i];
        v[i][0] = point.x;
        v[i][1] = point.y;
    }
    return v;
}

@interface KeyPointProjector ()
- (std::vector<cv::Point2f>)projectXY:(std::vector<cv::Point2f>)xyCoordsArr of:(double*)vectors;
@end

@implementation KeyPointProjector
- (std::vector<cv::Point2f>)projectKeypoints:(std::vector<cv::Point2f>)keyPoints of:(double*)vectors {
    std::vector<cv::Point2f> projectedPoints;
    for (int i = 0; i < keyPoints.size(); i++) {
        cv::Point2f p = keyPoints[i];
        float x = vectors[int(p.x)];
        float y = vectors[int(p.y)];
        projectedPoints.push_back(cv::Point2f(x, y));
    }
    projectedPoints[0] = cv::Point2f(0, 0);
    return [self projectXY:projectedPoints of:vectors];
}

- (std::vector<cv::Point2f>)projectXY:(std::vector<cv::Point2f>)xyCoordsArr of:(double*)vectors {
    std::vector<cv::Point3f> objectPoints = [self objectPointsFrom:xyCoordsArr vectors:vectors];
    //logs::describe_vector(objectPoints, "objectPoints");

    // rotation vector
    double rvec0 = vectors[0];
    double rvec1 = vectors[1];
    double rvec2 = vectors[2];
    std::vector<double>rvec = {rvec0, rvec1, rvec2};
    //logs::describe_vector(cv::Mat(rvec), "rvec");

    // translation vector
    double tvec3 = vectors[3];
    double tvec4 = vectors[4];
    double tvec5 = vectors[5];
    std::vector<double>tvec = {tvec3, tvec4, tvec5};
    //logs::describe_vector(cv::Mat(tvec), "tvec");

    // Input camera matrix
    cv::Mat intrinsics = [self cameraIntrinsics];
    //logs::describe_vector(intrinsics, "intrinsics");

    // Input vector of distortion coefficients
    cv::Mat distanceCoeffs = cv::Mat::zeros(1, 5, CV_64FC1);
    //logs::describe_vector(distanceCoeffs, "distanceCoeffs");

    std::vector<cv::Point2f> imagePoints;
    projectPoints(objectPoints, rvec, tvec, intrinsics, distanceCoeffs, imagePoints);
    //logs::describe_vector(imagePoints, "imagePoints");

    return imagePoints;
}

- (std::vector<cv::Point3f>)objectPointsFrom:(std::vector<cv::Point2f>)xyCoordsArr vectors:(double*)vectors {
    float alpha = vectors[6];
    float beta = vectors[7];

    std::vector<double> poly = {alpha + beta, -2*alpha - beta, alpha, 0};
    std::vector<double> xCoords = axis(0, xyCoordsArr);
    std::vector<double> zValues = math::polyval(poly, xCoords);

    std::vector<std::vector<double>> xyCoords = convert_to_vector2d(xyCoordsArr);
    //logs::describe_vector(xyCoords, "xyCoords");

    std::vector<std::vector<double>> zCoords = vectors::reshape(zValues, int(zValues.size()), 1);
    //logs::describe_vector(zCoords, "zCoords");

    std::vector<std::vector<double>> objPoints = vectors::hstack(xyCoords, zCoords);
    //logs::describe_vector(objPoints, "objPoints");

    std::vector<cv::Point3f> objectPoints;
    for (int i = 0; i < objPoints.size(); i++) {
        double x = objPoints[i][0];
        double y = objPoints[i][1];
        double z = objPoints[i][2];
        cv::Point3f point = cv::Point3f(x, y, z);
        objectPoints.push_back(point);
    }

    return objectPoints;
}

- (cv::Mat)cameraIntrinsics {
    cv::Mat intrinsics = cv::Mat(3, 3, CV_64FC1);
    intrinsics.at<double>(0, 0) = 1.8;
    intrinsics.at<double>(1, 1) = 1.8;
    intrinsics.at<double>(2, 2) = 1.0;
    return intrinsics;
}


//// Test methods...
//- (std::vector<cv::Point2f>)testprojectKeypoints:(std::vector<cv::Point2f>)keyPoints of:(std::vector<double>)vectors {
//    std::vector<cv::Point2f> xy_coords = {
//        cv::Point2f(0.00000000,0.00000000),
//        cv::Point2f(0.20033272,0.07952788),
//        cv::Point2f(0.25980987,0.07952788),
//        cv::Point2f(0.31932692,0.07952788),
//        cv::Point2f(0.37862638,0.07952788),
//        cv::Point2f(0.43772273,0.07952788),
//        cv::Point2f(0.61108224,0.10414961),
//        cv::Point2f(0.39245898,0.22384480)
//    };
//    std::vector<double> pvec = {-0.00000000,0.00000000,0.01341045,-0.74919273,-1.01938189,1.79999995,0.00000000,0.00000000};
//    return [self projectXY:xy_coords of:pvec];
//}
//
//- (std::vector<cv::Point2f>)testprojectXY:(std::vector<cv::Point2f>)xyCoordsArr of:(std::vector<double>)vectors {
//    std::vector<cv::Point3f> objectPoints = {
//        cv::Point3f(0.00000000,0.00000000,0.00000000),
//        cv::Point3f(0.20033272,0.07952788,0.00000000),
//        cv::Point3f(0.25980987,0.07952788,0.00000000),
//        cv::Point3f(0.31932692,0.07952788,0.00000000)
//    };
//    std::vector<double> rvec = {-0.00000000,0.00000000,0.01341045};
//    std::vector<double> tvec = {-0.74919273,-1.01938189,1.79999995};
//    cv::Mat intrinsics = [self cameraIntrinsics];
//    cv::Mat distanceCoeffs = cv::Mat::zeros(1, 5, CV_64FC1);
//
//    std::vector<cv::Point2f> imagePoints;
//    projectPoints(objectPoints, rvec, tvec, intrinsics, distanceCoeffs, imagePoints);
//    logs::describe_vector(imagePoints, "imagePoints");
//
//    // expected output
//    //[[-0.74919273 -1.01938189]]
//    //[[-0.54994450 -0.93717469]]
//    //[[-0.49047270 -0.93637710]]
//    //[[-0.43096100 -0.93557897]]
//
//    // actual output
//    //[-0.74919277, -1.0193819;
//    // -0.54994452, -0.93717474;
//    // -0.4904727, -0.93637711;
//    // -0.43096101, -0.935579]
//
//    return imagePoints;
//}
@end

