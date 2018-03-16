#ifndef KeyPointProjector_hpp
#define KeyPointProjector_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

class KeyPointProjector {
public:
    vector<Point2d> projectKeypoints(vector<Point2d> keyPoints, double *vectors) const;
    vector<Point2d> projectXY(vector<Point2d> xyCoordsArr, double *vectors) const;
private:
    Mat cameraIntrinsics() const;
    vector<Point3d> objectPointsFrom(vector<Point2d> xyCoordsArr, double *vectors) const;
};

#endif /* KeyPointProjector_hpp */
