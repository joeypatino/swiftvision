#include "KeyPointProjector.hpp"
#include "vector+extras.hpp"
#include "math+extras.hpp"
#include "print+extras.hpp"

std::vector<cv::Point2d> KeyPointProjector::projectKeypoints(std::vector<cv::Point2d> keyPoints, double *vectors) const {
    std::vector<cv::Point2d> projectedPoints;
    for (int i = 0; i < keyPoints.size(); i++) {
        cv::Point2f p = keyPoints[i];
        double x = vectors[int(p.x)];
        double y = vectors[int(p.y)];
        projectedPoints.push_back(cv::Point2d(x, y));
    }
    projectedPoints[0] = cv::Point2d(0, 0);
    return projectXY(projectedPoints, vectors);
}

std::vector<cv::Point2d> KeyPointProjector::projectXY(std::vector<std::vector<double>> xyCoordsArr, double *vectors) const {
    std::vector<cv::Point2d> points;
    for (int r = 0; r < xyCoordsArr.size(); r++) {
        std::vector<double> row = xyCoordsArr[r];
        points.push_back(Point2d(row[0], row[1]));
    }
    return projectXY(points, vectors);
}

std::vector<cv::Point2d> KeyPointProjector::projectXY(std::vector<cv::Point2d> xyCoordsArr, double *vectors) const {
    std::vector<cv::Point3d> objectPoints = objectPointsFrom(xyCoordsArr, vectors);
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
    cv::Matx33d intrinsics = cameraIntrinsics();
    //logs::describe_vector(cv::Mat(intrinsics), "intrinsics");

    // Input vector of distortion coefficients
    cv::Mat distanceCoeffs = cv::Mat::zeros(5, 1, cv::DataType<double>::type);
    //logs::describe_vector(distanceCoeffs, "distanceCoeffs");

    std::vector<cv::Point2d> imagePoints;
    cv::projectPoints(objectPoints, rvec, tvec, intrinsics, distanceCoeffs, imagePoints);
    //logs::describe_vector(imagePoints, "imagePoints");

    return imagePoints;
}

std::vector<cv::Point3d> KeyPointProjector::objectPointsFrom(std::vector<cv::Point2d> xyCoordsArr, double *vectors) const {
    float alpha = vectors[6];
    float beta = vectors[7];

    std::vector<double> poly = {alpha + beta, -2*alpha - beta, alpha, 0};
    std::vector<double> xCoords = vectors::axis(0, xyCoordsArr);
    std::vector<double> zValues = math::polyval(poly, xCoords);

    std::vector<std::vector<double>> xyCoords = vectors::convert_to_vector2d(xyCoordsArr);
    //logs::describe_vector(xyCoords, "xyCoords");

    std::vector<std::vector<double>> zCoords = vectors::reshape(zValues, int(zValues.size()), 1);
    //logs::describe_vector(zCoords, "zCoords");

    std::vector<std::vector<double>> objPoints = vectors::hstack(xyCoords, zCoords);
    //logs::describe_vector(objPoints, "objPoints");

    std::vector<cv::Point3d> objectPoints;
    for (int i = 0; i < objPoints.size(); i++) {
        double x = objPoints[i][0];
        double y = objPoints[i][1];
        double z = objPoints[i][2];
        cv::Point3d point = cv::Point3d(x, y, z);
        objectPoints.push_back(point);
    }

    return objectPoints;
}

cv::Matx33d KeyPointProjector::cameraIntrinsics() const {
    cv::Matx33d intrinsics = Matx<double, 3, 3>();
    intrinsics(0, 0) = 1.2;
    intrinsics(0, 1) = 0.;
    intrinsics(0, 2) = 0.;

    intrinsics(1, 0) = 0.;
    intrinsics(1, 1) = 1.2;
    intrinsics(1, 2) = 0.;

    intrinsics(2, 0) = 0.;
    intrinsics(2, 1) = 0.;
    intrinsics(2, 2) = 1.;
    return intrinsics;
}
