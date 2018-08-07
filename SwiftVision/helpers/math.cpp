#include <math.h>
#include "math.hpp"
#include "dewarp.hpp"

#define  SWAP(a,b)   {temp = (a); (a) = (b); (b) = temp;}

namespace math {
    int gaussjordan(double **a,
                    double *b,
                    int n) {
        int i, icol, irow, j, k, col, row, success;
        int *indexc, *indexr, *ipiv;
        double maxval, val, pivinv, temp;

        if (!a)
            return 1;
        if (!b)
            return 1;

        success = true;
        indexc = (int *)calloc(n, sizeof(int));
        indexr = (int *)calloc(n, sizeof(int));
        ipiv = (int *)calloc(n, sizeof(int));
        if (!indexc || !indexr || !ipiv) {
            success = false;
            goto cleanup_arrays;
        }

        icol = irow = 0;  /* silence static checker */
        for (i = 0; i < n; i++) {
            maxval = 0.0;
            for (j = 0; j < n; j++) {
                if (ipiv[j] != 1) {
                    for (k = 0; k < n; k++) {
                        if (ipiv[k] == 0) {
                            if (fabs(a[j][k]) >= maxval) {
                                maxval = fabs(a[j][k]);
                                irow = j;
                                icol = k;
                            }
                        } else if (ipiv[k] > 1) {
                            success = false;
                            goto cleanup_arrays;
                        }
                    }
                }
            }
            ++(ipiv[icol]);

            if (irow != icol) {
                for (col = 0; col < n; col++)
                    SWAP(a[irow][col], a[icol][col]);
                SWAP(b[irow], b[icol]);
            }

            indexr[i] = irow;
            indexc[i] = icol;
            if (a[icol][icol] == 0.0) {
                success = false;
                goto cleanup_arrays;
            }
            pivinv = 1.0 / a[icol][icol];
            a[icol][icol] = 1.0;
            for (col = 0; col < n; col++)
                a[icol][col] *= pivinv;
            b[icol] *= pivinv;

            for (row = 0; row < n; row++) {
                if (row != icol) {
                    val = a[row][icol];
                    a[row][icol] = 0.0;
                    for (col = 0; col < n; col++)
                        a[row][col] -= a[icol][col] * val;
                    b[row] -= b[icol] * val;
                }
            }
        }

        for (col = n - 1; col >= 0; col--) {
            if (indexr[col] != indexc[col]) {
                for (k = 0; k < n; k++)
                    SWAP(a[k][indexr[col]], a[k][indexc[col]]);
            }
        }

    cleanup_arrays:
        free(indexr);
        free(indexc);
        free(ipiv);
        return (success) ? 0 : 1;
    }

    double angleDistance(double angle_b, double angle_a) {
        double diff = angle_b - angle_a;

        while (diff > M_PI) {
            diff -= 2 * M_PI;
        }
        while (diff < -M_PI) {
            diff += 2 * M_PI;
        }
        return abs(diff);
    }

    int getQuadraticLSF(vectorPointD *pta,
                        double *pa,
                        double *pb,
                        double *pc,
                        std::vector<double> **pnafit) {
        int n = 0, i, ret;
        double x, y, sx, sy, sx2, sx3, sx4, sxy, sx2y;
        double *f[3];
        double g[3];

        if (pa) *pa = 0.0;
        if (pb) *pb = 0.0;
        if (pc) *pc = 0.0;
        if (pnafit) *pnafit = NULL;
        if (!pa && !pb && !pc && !pnafit)
            return 1;
        if (!pta)
            return 1;
        if (pta->size() < 3)
            return 1;

        n = (int)pta->size();
        sx = sy = sx2 = sx3 = sx4 = sxy = sx2y = 0.;
        for (i = 0; i < n; i++) {
            DPoint p = pta->at(i); /* not a copy */
            x = p.x;
            y = p.y;
            sx += x;
            sy += y;
            sx2 += x * x;
            sx3 += x * x * x;
            sx4 += x * x * x * x;
            sxy += x * y;
            sx2y += x * x * y;
        }

        for (i = 0; i < 3; i++)
            f[i] = (double *)calloc(3, sizeof(double));
        f[0][0] = sx4;
        f[0][1] = sx3;
        f[0][2] = sx2;
        f[1][0] = sx3;
        f[1][1] = sx2;
        f[1][2] = sx;
        f[2][0] = sx2;
        f[2][1] = sx;
        f[2][2] = n;
        g[0] = sx2y;
        g[1] = sxy;
        g[2] = sy;

        /* Solve for the unknowns, also putting f-inverse into f */
        ret = gaussjordan(f, g, 3);
        for (i = 0; i < 3; i++)
            free(f[i]);
        if (ret)
            return 1;

        if (pa) *pa = g[0];
        if (pb) *pb = g[1];
        if (pc) *pc = g[2];
        if (pnafit) {

            *pnafit = new std::vector<double>(n);
            for (i = 0; i < n; i++) {
                DPoint p = pta->at(i); /* not a copy */
                x = p.x;
                y = g[0] * x * x + g[1] * x + g[2];
                (*pnafit)->push_back(y);
            }
        }
        return 0;
    }

    int dewarpQuadraticLSF(std::vector<DPoint> *ptad,
                           double *pa,
                           double *pb,
                           double *pc,
                           double *pmederr) {
        int    i, n;
        double  x, c0, c1, c2;
        std::vector<double> *naerr;

        if (pmederr) *pmederr = 0.0;
        if (!pa || !pb || !pc)
            return 1;
        *pa = *pb = *pc = 0.0;
        if (!ptad)
            return 1;

        /* Fit to the longest lines */
        getQuadraticLSF(ptad, &c2, &c1, &c0, NULL);
        *pa = c2;
        *pb = c1;
        *pc = c0;

        /* Optionally, find the median error */
        if (pmederr) {
            n = (int)ptad->size();
            naerr = new std::vector<double>();
            for (i = 0; i < n; i++) {
                DPoint p = ptad->at(i);
                applyQuadraticFit(c2, c1, c0, p.x, &x);
                naerr->push_back(abs(x-p.y));
            }
            dewarp::getMedian(naerr, pmederr);
            free(naerr);
        }
        return 0;
    }

    int applyQuadraticFit(double a,
                          double b,
                          double c,
                          double x,
                          double *py) {
        if (!py)
            return 1;

        *py = a * x * x + b * x + c;
        return 0;
    }

    int getLinearLSF(vectorPointD *pta,
                     double *pa,
                     double *pb,
                     vectorD **pnafit) {
        int     n, i;
        double   a, b, factor, sx, sy, sxx, sxy, val;

        if (pa) *pa = 0.0;
        if (pb) *pb = 0.0;
        if (pnafit) *pnafit = NULL;
        if (!pa && !pb && !pnafit)
            return 1;
        if (!pta)
            return 1;
        n = (int) pta->size();
        if (n < 2)
            return 1;

        sx = sy = sxx = sxy = 0.;
        if (pa && pb) {  /* general line */
            for (i = 0; i < n; i++) {
                DPoint p = pta->at(i);
                sx += p.x;
                sy += p.y;
                sxx += p.x * p.x;
                sxy += p.x * p.y;
            }
            factor = n * sxx - sx * sx;
            if (factor == 0.0)
                return 1;
            factor = 1. / factor;

            a = factor * ((double)n * sxy - sx * sy);
            b = factor * (sxx * sy - sx * sxy);
        } else if (pa) {  /* b = 0; line through origin */
            for (i = 0; i < n; i++) {
                DPoint p = pta->at(i);
                sxx += p.x * p.x;
                sxy += p.x * p.y;
            }
            if (sxx == 0.0)
                return 1;
            a = sxy / sxx;
            b = 0.0;
        } else {  /* a = 0; horizontal line */
            for (i = 0; i < n; i++) {
                DPoint p = pta->at(i);
                sy += p.y;
            }
            a = 0.0;
            b = sy / (double)n;
        }

        if (pnafit) {
            *pnafit = new vectorD();
            for (i = 0; i < n; i++) {
                DPoint p = pta->at(i);
                val = a * p.x + b;
                (*pnafit)->push_back(val);
            }
        }

        if (pa) *pa = a;
        if (pb) *pb = b;
        return 0;
    }

    int applyLinearFit(double a,
                       double b,
                       double x,
                       double *py) {

        if (!py)
            return 1;

        *py = a * x + b;
        return 0;
    }
}
