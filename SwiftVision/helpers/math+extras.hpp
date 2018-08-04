#ifndef math_extras_hpp
#define math_extras_hpp

#include <vector>
#include <math.h>
#include "types.h"

namespace math {
    double polyval(std::vector<double> p, double x);
    std::vector<double> polyval(std::vector<double> p, std::vector<double> x);
    std::vector<double> linspace(double a, double b, double N);

    double filterNanInf(double x);
    int round(int i, int factor);

    // new method...
    vectorPointD norm2pix(DSize size, vectorPointD points);
    vectorPointD add(vectorPointD points, DPoint pt);
    vectorPointD multi(vectorPointD points, float scale);
    int gaussjordan(double **a,
                    double *b,
                    int n);
    int getQuadraticLSF(vectorPointD *pta,
                        double *pa,
                        double *pb,
                        double *pc,
                        vectorD **pnafit);
    int dewarpQuadraticLSF(vectorPointD *ptad,
                           double *pa,
                           double *pb,
                           double *pc,
                           double *pmederr);
    int applyQuadraticFit(double a,
                          double b,
                          double c,
                          double x,
                          double *py);

    int getLinearLSF(vectorPointD *pta,
                     double *pa,
                     double *pb,
                     vectorD **pnafit);
    int applyLinearFit(double a,
                       double b,
                       double x,
                       double *py);
}

#endif /* math_extras_hpp */


