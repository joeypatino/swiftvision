#ifndef math_extras_hpp
#define math_extras_hpp

#import <opencv2/opencv.hpp>
#include <vector>
#include <math.h>

namespace math {
    double polyval(std::vector<double> p, double x);
    std::vector<double> polyval(std::vector<double> p, std::vector<double> x);
    std::vector<double> linspace(double a, double b, double N);

    double filterNanInf(double x);
    int round(int i, int factor);
}

#endif /* math_extras_hpp */
