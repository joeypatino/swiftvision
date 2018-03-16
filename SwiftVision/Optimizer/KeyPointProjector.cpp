#include "KeyPointProjector.hpp"
#include "vector+extras.hpp"
#include "math+extras.hpp"
#include "print+extras.hpp"

KeyPointProjector::KeyPointProjector() {
    cout << "KeyPointProjector()" << endl;
}

KeyPointProjector::~KeyPointProjector() {
    cout << "~KeyPointProjector()" << endl;
}

vector<Point2f> KeyPointProjector::projectKeypoints(vector<Point2f> keyPoints, double *vectors) const {
    std::vector<Point2f> projectedPoints;
    for (int i = 0; i < keyPoints.size(); i++) {
        Point2f p = keyPoints[i];
        float x = vectors[int(p.x)];
        float y = vectors[int(p.y)];
        projectedPoints.push_back(Point2f(x, y));
    }
    projectedPoints[0] = Point2f(0, 0);
    return projectXY(projectedPoints, vectors);
}

vector<Point2f> KeyPointProjector::projectXY(vector<Point2f> xyCoordsArr, double *vectors) const {
    std::vector<cv::Point3f> objectPoints = objectPointsFrom(xyCoordsArr, vectors);
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
    cv::Mat intrinsics = cameraIntrinsics();
    //logs::describe_vector(intrinsics, "intrinsics");

    // Input vector of distortion coefficients
    cv::Mat distanceCoeffs = cv::Mat::zeros(1, 5, CV_64FC1);
    //logs::describe_vector(distanceCoeffs, "distanceCoeffs");

    std::vector<cv::Point2f> imagePoints;
    projectPoints(objectPoints, rvec, tvec, intrinsics, distanceCoeffs, imagePoints);
    //logs::describe_vector(imagePoints, "imagePoints");

    return imagePoints;
}

vector<Point3f> KeyPointProjector::objectPointsFrom(vector<Point2f> xyCoordsArr, double *vectors) const {
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

    std::vector<cv::Point3f> objectPoints;
    for (int i = 0; i < objPoints.size(); i++) {
        double x = objPoints[i][0];
        double y = objPoints[i][1];
        double z = objPoints[i][2];
        Point3f point = cv::Point3f(x, y, z);
        objectPoints.push_back(point);
    }

    return objectPoints;
}

Mat KeyPointProjector::cameraIntrinsics() const {
    Mat intrinsics = Mat(3, 3, CV_64FC1);
    intrinsics.at<double>(0, 0) = 1.8;
    intrinsics.at<double>(1, 1) = 1.8;
    intrinsics.at<double>(2, 2) = 1.0;
    return intrinsics;
}
