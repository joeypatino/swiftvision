#include "math+extras.hpp"

namespace math {
    double polyval(vector<double> p, double x) {
        double output = 0;
        double polyCnt = p.size();
        for (int i = 0; i < polyCnt; i++) {
            output += p[i] * pow(x, (polyCnt-1)-i);
        }
        return output;
    }

    vector<double> polyval(vector<double> p, vector<double> x) {
        long polyCnt = x.size();
        vector<double> output = vector<double>(polyCnt, 1);
        for (int i = 0; i < polyCnt; i++) {
            output[i] = polyval(p, x[i]);
        }
        return output;
    }

    double filterNanInf(double x) {
        if (cvIsNaN(x) || cvIsInf(x))
            return 0;
        return x;
    }
}
