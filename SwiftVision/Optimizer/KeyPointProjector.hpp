#ifndef KeyPointProjector_hpp
#define KeyPointProjector_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

class KeyPointProjector {
public:
    KeyPointProjector();
    virtual ~KeyPointProjector();
    vector<Point2f> projectKeypoints(vector<Point2f> keyPoints, double *vectors) const;
private:
    Mat cameraIntrinsics() const;
    vector<Point2f> projectXY(vector<Point2f> xyCoordsArr, double *vectors) const;
    vector<Point3f> objectPointsFrom(vector<Point2f> xyCoordsArr, double *vectors) const;
};

#endif /* KeyPointProjector_hpp */
