#include "leptonica.hpp"
#include "PtraArray.hpp"

namespace leptonica {
    int join(std::vector<double> *nad,
             std::vector<double> *nas,
             int istart,
             int iend) {
        int n, i;
        double val;

        if (!nad)
            return 1;
        if (!nas)
            return 0;

        if (istart < 0)
            istart = 0;
        n = (int) nas->size();
        if (iend < 0 || iend >= n)
            iend = n - 1;
        if (istart > iend)
            return 1;

        for (i = istart; i <= iend; i++) {
            val = (*nas)[i];
            nad->push_back(val);
        }

        return 0;
    }

    int getMedianVariation(std::vector<double> *na,
                           double *pmedval,
                           double *pmedvar) {
        int n, i;
        double val, medval;
        std::vector<double> *navar;

        if (pmedval) *pmedval = 0.0;
        if (!pmedvar)
            return 1;
        *pmedvar = 0.0;
        if (!na)
            return 1;

        getMedian(na, &medval);
        if (pmedval) *pmedval = medval;
        n = (int) na->size();
        navar = new std::vector<double>();
        for (i = 0; i < n; i++) {
            val = (*na)[i];
            navar->push_back(fabs(val - medval));
        }
        getMedian(navar, pmedvar);

        free(navar);
        return 0;
    }

    int getMedian(std::vector<double> *na, double *pval) {
        if (!pval)
            return 1;
        *pval = 0.0;  /* init */
        if (!na)
            return 1;

        return getRankValue(na, 0.5, NULL, 0, pval);
    }

    int getRankValue(std::vector<double> *na,
                     double fract,
                     std::vector<double> *nasort,
                     int usebins,
                     double* pval) {
        int n, index;
        std::vector<double> *nas;

        if (!pval)
            return 1;
        *pval = 0.0;  /* init */
        if (!na)
            return 1;
        if (fract < 0.0 || fract > 1.0)
            return 1;
        n = (int) na->size();
        if (n == 0)
            return 1;

        if (nasort) {
            nas = nasort;
        } else {
            if (usebins == 0)
                nas = sort(NULL, na, L_SORT_INCREASING);
            else
                nas = binSort(na, L_SORT_INCREASING);
            if (!nas)
                return 1;
        }
        index = (int)(fract * (double)(n - 1) + 0.5);
        *pval = nas->at(index);

        if (!nasort) free(nas);
        return 0;
    }

    std::vector<double> *sortByIndex(std::vector<double> *nas,
                                     std::vector<double> *naindex) {
        int i, n, index;
        double val;
        std::vector<double> *nad;

        if (!nas)
            return (std::vector<double> *)NULL;
        if (!naindex)
            return (std::vector<double> *)NULL;

        n = (int) nas->size();
        nad = new std::vector<double>();
        for (i = 0; i < n; i++) {
            index = (*naindex)[i];
            val = (*nas)[index];
            nad->push_back(val);
        }

        return nad;
    }

    std::vector<double> *sort(std::vector<double> *naout,
                              std::vector<double> *nain,
                              int sortorder) {
        int i, n, gap, j;
        double tmp;

        if (!nain)
            return (std::vector<double> *)NULL;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return (std::vector<double> *)NULL;

        /* Make naout if necessary; otherwise do in-place */
        if (!naout)
            naout = new std::vector<double>(*nain);
        else if (nain != naout)
            return (std::vector<double> *)NULL;

        n = (int)naout->size();

        /* Shell sort */
        for (gap = n/2; gap > 0; gap = gap / 2) {
            for (i = gap; i < n; i++) {
                for (j = i - gap; j >= 0; j -= gap) {
                    double jVal = naout->at(j);
                    double jGapVal = naout->at(j + gap);
                    if ((sortorder == L_SORT_INCREASING && jVal > jGapVal) ||
                        (sortorder == L_SORT_DECREASING && jVal < jGapVal)){
                        tmp = naout->at(j);
                        naout->at(j) = naout->at(j + gap);
                        naout->at(j + gap) = tmp;
                    }
                }
            }
        }

        return naout;
    }

    std::vector<double> *binSort(std::vector<double> *nas,
                                 int sortorder) {
        std::vector<double> *nat, *nad;

        if (!nas)
            return (std::vector<double> *)NULL;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return (std::vector<double> *)NULL;

        nat = getBinSortIndex(nas, sortorder);
        nad = sortByIndex(nas, nat);
        free(nat);
        return nad;
    }

    std::vector<double> *getBinSortIndex(std::vector<double> *nas,
                                         int sortorder) {
        int i, n, isize, ival, imax;
        double size;
        std::vector<double> *na, *nai, *nad;
        PtrArray *paindex;

        if (!nas)
            return (std::vector<double> *)NULL;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return (std::vector<double> *)NULL;

        /* Set up a ptra holding numa at indices for which there
         * are values in nas.  Suppose nas has the value 230 at index
         * 7355.  A numa holding the index 7355 is created and stored
         * at the ptra index 230.  If there is another value of 230
         * in nas, its index is added to the same numa (at index 230
         * in the ptra).  When finished, the ptra can be scanned for numa,
         * and the original indices in the nas can be read out.  In this
         * way, the ptra effectively sorts the input numbers in the nas. */
        getMax(nas, &size, NULL);
        isize = (int)size;

        paindex = dewarp::ptraCreate(isize + 1);
        n = (int)nas->size();
        for (i = 0; i < n; i++) {
            ival = (*nas)[i];
            nai = (std::vector<double> *)dewarp::ptraGetPtrToItem(paindex, ival);
            if (!nai) {  /* make it; no shifting will occur */
                nai = new std::vector<double>();
                dewarp::ptraInsert(paindex, ival, nai, L_MIN_DOWNSHIFT);
            }
            nai->push_back(i);
        }

        /* Sort by scanning the ptra, extracting numas and pulling
         * the (index into nas) numbers out of each numa, taken
         * successively in requested order. */
        dewarp::ptraGetMaxIndex(paindex, &imax);
        nad = new std::vector<double>();
        if (sortorder == L_SORT_INCREASING) {
            for (i = 0; i <= imax; i++) {
                na = (std::vector<double> *)dewarp::ptraRemove(paindex, i, L_NO_COMPACTION);
                if (!na) continue;
                join(nad, na, 0, -1);
                free(na);
            }
        } else {  /* L_SORT_DECREASING */
            for (i = imax; i >= 0; i--) {
                na = (std::vector<double> *)dewarp::ptraRemoveLast(paindex);
                if (!na) break;  /* they've all been removed */
                join(nad, na, 0, -1);
                free(na);
            }
        }

        dewarp::ptraDestroy(&paindex, false, false);
        return nad;
    }

    std::vector<double> *getSortIndex(std::vector<double> *na,
                                      int sortorder) {
        int i, n, gap, j;
        double tmp;
        std::vector<double> *array;   /* copy of input array */
        std::vector<double> *iarray;  /* array of indices */
        std::vector<double> *naisort;


        if (!na)
            return (std::vector<double> *)NULL;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return (std::vector<double> *)NULL;

        n = (int)na->size();
        array = new std::vector<double>(*na);
        if (array == NULL)
            return (std::vector<double> *)NULL;
        iarray = new std::vector<double>(n);
        if (iarray == NULL) {
            free(array);
            return (std::vector<double> *)NULL;
        }
        for (i = 0; i < n; i++)
            iarray->at(i) = i;

        /* Shell sort */
        for (gap = n/2; gap > 0; gap = gap / 2) {
            for (i = gap; i < n; i++) {
                for (j = i - gap; j >= 0; j -= gap) {
                    double jValue = array->at(j);
                    double jGapValue = array->at(j + gap);
                    if ((sortorder == L_SORT_INCREASING && jValue > jGapValue) ||
                        (sortorder == L_SORT_DECREASING && jValue < jGapValue)) {
                        tmp = array->at(j);
                        array->at(j) = array->at(j + gap);
                        array->at(j + gap) = tmp;
                        tmp = iarray->at(j);
                        iarray->at(j) = iarray->at(j + gap);
                        iarray->at(j + gap) = tmp;
                    }
                }
            }
        }

        naisort = new std::vector<double>();
        for (i = 0; i < n; i++)
            naisort->push_back((*iarray)[i]);

        free(array);
        free(iarray);
        return naisort;
    }

    int getMin(std::vector<double> *na,
               double *pminval,
               int *piminloc) {
        int i, n, iminloc;
        double val, minval;

        if (!pminval && !piminloc)
            return 1;
        if (pminval) *pminval = 0.0;
        if (piminloc) *piminloc = 0;
        if (!na)
            return 1;

        minval = +1000000000.;
        iminloc = 0;
        n = (int)na->size();
        for (i = 0; i < n; i++) {
            val = (*na)[i];
            if (val < minval) {
                minval = val;
                iminloc = i;
            }
        }

        if (pminval) *pminval = minval;
        if (piminloc) *piminloc = iminloc;
        return 0;
    }

    int getMax(std::vector<double> *na,
               double *pmaxval,
               int *pimaxloc) {
        int i, n, imaxloc;
        double val, maxval;

        if (!pmaxval && !pimaxloc)
            return 1;
        if (pmaxval) *pmaxval = 0.0;
        if (pimaxloc) *pimaxloc = 0;
        if (!na)
            return 1;

        maxval = -1000000000.;
        imaxloc = 0;
        n = (int)na->size();
        for (i = 0; i < n; i++) {
            val = (*na)[i];
            if (val > maxval) {
                maxval = val;
                imaxloc = i;
            }
        }

        if (pmaxval) *pmaxval = maxval;
        if (pimaxloc) *pimaxloc = imaxloc;
        return 0;
    }

    std::vector<std::vector<DPoint>> * sortByIndex(std::vector<std::vector<DPoint>> *ptaas,
                                                   std::vector<double> *naindex) {
        int i, n, index;
        std::vector<DPoint> *pta;
        std::vector<std::vector<DPoint>> *ptaad;

        if (!ptaas)
            return (std::vector<std::vector<DPoint>> *)NULL;
        if (!naindex)
            return (std::vector<std::vector<DPoint>> *)NULL;

        n = (int)ptaas->size();
        if (naindex->size() != n)
            return (std::vector<std::vector<DPoint>> *)NULL;
        ptaad = new std::vector<std::vector<DPoint>>();
        for (i = 0; i < n; i++) {
            index = (*naindex)[i];
            pta = &(*ptaas)[index];
            ptaad->push_back(*pta);
        }

        return ptaad;
    }

    std::vector<DPoint> *sort(std::vector<DPoint> *ptas,
                              int sorttype,
                              int sortorder,
                              std::vector<double> **pnaindex) {
        std::vector<DPoint> *ptad;
        std::vector<double> *naindex;

        if (pnaindex) *pnaindex = NULL;
        if (!ptas)
            return (std::vector<DPoint> *)NULL;
        if (sorttype != L_SORT_BY_X && sorttype != L_SORT_BY_Y)
            return (std::vector<DPoint> *)NULL;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return (std::vector<DPoint> *)NULL;

        if (getSortIndex(ptas, sorttype, sortorder, &naindex) != 0)
            return (std::vector<DPoint> *)NULL;

        ptad = sortByIndex(ptas, naindex);
        if (pnaindex)
            *pnaindex = naindex;
        else
            free(naindex);
        if (!ptad)
            return (std::vector<DPoint> *)NULL;
        return ptad;
    }

    int getSortIndex(std::vector<DPoint> *ptas,
                     int sorttype,
                     int sortorder,
                     std::vector<double> **pnaindex) {
        int i, n;
        double x, y;
        std::vector<double> *na;

        if (!pnaindex)
            return 1;
        *pnaindex = NULL;
        if (!ptas)
            return 1;
        if (sorttype != L_SORT_BY_X && sorttype != L_SORT_BY_Y)
            return 1;
        if (sortorder != L_SORT_INCREASING && sortorder != L_SORT_DECREASING)
            return 1;

        /* Build up numa of specific data */
        n = (int)ptas->size();
        na = new std::vector<double>();
        if (na == NULL)
            return 1;
        for (i = 0; i < n; i++) {
            DPoint p = ptas->at(i);
            x = p.x;
            y = p.y;
            if (sorttype == L_SORT_BY_X)
                na->push_back(x);
            else
                na->push_back(y);
        }

        /* Get the sort index for data array */
        *pnaindex = getSortIndex(na, sortorder);
        free(na);
        if (!*pnaindex)
            return 1;
        return 0;
    }

    std::vector<DPoint> * sortByIndex(std::vector<DPoint> *ptas,
                                      std::vector<double> *naindex) {
        int i, index, n;
        std::vector<DPoint> *ptad;

        if (!ptas)
            return (std::vector<DPoint> *)NULL;
        if (!naindex)
            return (std::vector<DPoint> *)NULL;

        /* Build up sorted pta using sort index */
        n = (int)naindex->size();
        ptad = new std::vector<DPoint>();
        if (ptad == NULL)
            return (std::vector<DPoint> *)NULL;
        for (i = 0; i < n; i++) {
            index = naindex->at(i);
            DPoint p = ptas->at(index);
            ptad->push_back(p);
        }

        return ptad;
    }

    int addMultConstant(std::vector<std::vector<double>> *fpix,
                        double addc,
                        double multc) {
        int i, j, w, h;
        if (!fpix)
            return 1;

        if (addc == 0.0 && multc == 1.0)
            return 0;

        h = (int)fpix->size();
        w = (int)fpix->at(0).size();

        for (i = 0; i < h; i++) {
            if (addc == 0.0) {
                for (j = 0; j < w; j++)
                    fpix->at(i).at(j) *= multc;
            } else if (multc == 1.0) {
                for (j = 0; j < w; j++)
                    fpix->at(i).at(j) += addc;
            } else {
                for (j = 0; j < w; j++) {
                    double val = fpix->at(i).at(j);
                    fpix->at(i).at(j) = multc * val + addc;
                }
            }
        }

        return 0;
    }

    std::vector<std::vector<double>> *scaleByInteger(std::vector<std::vector<double>> *fpixs,
                                                     int factor) {
        int     i, j, k, m, ws, hs, wd, hd, wpls, wpld;
        double   val0, val1, val2, val3;
        double  *datas, *datad, *lines, *lined, *fract;
        std::vector<std::vector<double>> *fpixd;

        if (!fpixs)
            return (std::vector<std::vector<double>> *)NULL;
        hs = (int)fpixs->size();
        ws = (int)fpixs->at(0).size();

        hd = factor * (hs - 1) + 1;
        wd = factor * (ws - 1) + 1;

        datas = (double *)calloc(hs * ws, sizeof(double));
        datad = (double *)calloc(hd * wd, sizeof(double));
        for (int i = 0; i < hs; i++) {
            for (int j = 0; j < ws; j++) {
                datas[i * ws + j] = (*fpixs)[i][j];
            }
        }

        wpls = ws; /* 4-byte words */
        wpld = wd; /* 4-byte words */
        fract = (double *)calloc(factor, sizeof(double));
        for (i = 0; i < factor; i++)
            fract[i] = i / (double)factor;
        for (i = 0; i < hs - 1; i++) {
            lines = datas + i * wpls;
            for (j = 0; j < ws - 1; j++) {
                val0 = lines[j];
                val1 = lines[j + 1];
                val2 = lines[wpls + j];
                val3 = lines[wpls + j + 1];
                for (k = 0; k < factor; k++) {  /* rows of sub-block */
                    lined = datad + (i * factor + k) * wpld;
                    for (m = 0; m < factor; m++) {  /* cols of sub-block */
                        lined[j * factor + m] =
                        val0 * (1.0 - fract[m]) * (1.0 - fract[k]) +
                        val1 * fract[m] * (1.0 - fract[k]) +
                        val2 * (1.0 - fract[m]) * fract[k] +
                        val3 * fract[m] * fract[k];
                    }
                }
            }
        }

        /* Do the right-most column of fpixd, skipping LR corner */
        for (i = 0; i < hs - 1; i++) {
            lines = datas + i * wpls;
            val0 = lines[ws - 1];
            val1 = lines[wpls + ws - 1];
            for (k = 0; k < factor; k++) {
                lined = datad + (i * factor + k) * wpld;
                lined[wd - 1] = val0 * (1.0 - fract[k]) + val1 * fract[k];
            }
        }

        /* Do the bottom-most row of fpixd */
        lines = datas + (hs - 1) * wpls;
        lined = datad + (hd - 1) * wpld;
        for (j = 0; j < ws - 1; j++) {
            val0 = lines[j];
            val1 = lines[j + 1];
            for (m = 0; m < factor; m++)
                lined[j * factor + m] = val0 * (1.0 - fract[m]) + val1 * fract[m];
            lined[wd - 1] = lines[ws - 1];  /* LR corner */
        }

        free(fract);
        free(datas);

        fpixd = new std::vector<std::vector<double>>(hd, std::vector<double>(wd));
        for (int i = 0; i < hd; i++) {
            for (int j = 0; j < wd; j++) {
                (*fpixd)[i][j] = datad[i * wd + j];
            }
        }
        free(datad);

        return fpixd;
    }
}
