#include "math+extras.hpp"

namespace math {
    double polyval(std::vector<double> p, double x) {
        double output = 0;
        double polyCnt = p.size();
        for (int i = 0; i < polyCnt; i++) {
            output += p[i] * std::pow(x, (polyCnt-1)-i);
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

    double filterNanInf(double x) {
        if (cvIsNaN(x) || cvIsInf(x))
            return 0;
        return x;
    }

    int round(int i, int factor) {
        int j = int(i);
        int rem = j % factor;

        if (rem == 0)
            return j;

        return j + factor - rem;
    }

    std::vector<double> linspace(double a, double b, double N) {
        double h = (b - a) / static_cast<double>(N-1);
        std::vector<double> xs(N);
        std::vector<double>::iterator x;
        double val;
        for (x = xs.begin(), val = a; x != xs.end(); ++x, val += h) {
            *x = val;
        }
        return xs;
    }
}
