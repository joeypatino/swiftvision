#ifndef math_extras_hpp
#define math_extras_hpp

#include <vector>
#include <math.h>

using namespace std;

namespace math {
    double polyval(vector<double> p, double x);
    vector<double> polyval(vector<double> p, vector<double> x);
}

#endif /* math_extras_hpp */
