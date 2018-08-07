#ifndef dewarp_math_hpp
#define dewarp_math_hpp

#include "DataTypes.h"

namespace math {
    int gaussjordan(double **a,
                    double *b,
                    int n);
    double angleDistance(double angle_b,
                         double angle_a);
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

#endif /* dewarp_math_hpp */


