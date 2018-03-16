#ifndef vector_extras_hpp
#define vector_extras_hpp

#import <opencv2/opencv.hpp>
#include <vector>
#include <cassert>

using namespace std;
using namespace cv;

namespace vectors {
    vector<vector<double>> hstack(vector<vector<double>> mat1, vector<vector<double>> mat2);
    vector<vector<double>> reshape(vector<double> p, int rows, int cols);

    vector<double> axis(int x, vector<Point2f> points);
    vector<vector<double>> convert_to_vector2d(vector<Point2f> points);
}

#endif /* vector_extras_hpp */
