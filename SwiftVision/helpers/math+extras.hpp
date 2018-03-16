#ifndef math_extras_hpp
#define math_extras_hpp

#import <opencv2/opencv.hpp>
#include <vector>
#include <math.h>

using namespace std;

namespace math {
    double polyval(vector<double> p, double x);
    vector<double> polyval(vector<double> p, vector<double> x);

    double filterNanInf(double x);
}

#endif /* math_extras_hpp */
