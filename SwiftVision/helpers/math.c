#include "math.h"

namespace math {
    double polyval(std::vector<double> p, double x) {
        double output = 0;
        double polyCnt = p.size();
        for (int i = 0; i < polyCnt; i++) {
            output += p[i] * pow(x, (polyCnt-1)-i);
        }
        return output;
    }
    
    std::vector<double> polyval(std::vector<double> p, std::vector<double> x) {
        long polyCnt = x.size();
        std::vector<double> output = std::vector<double>(polyCnt, 1);
        for (int i = 0; i < polyCnt; i++) {
            output[i] = polyval(p, x[i]);
        }
        return output;
    }
}
