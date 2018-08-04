#include "leptonica.hpp"

#define  SWAP(a,b)   {temp = (a); (a) = (b); (b) = temp;}

namespace leptonica {

    void *reallocNew(void **pindata,
                     int oldsize,
                     int newsize) {
        int  minsize;
        void *indata;
        void *newdata;

        if (!pindata)
            return NULL;
        indata = *pindata;

        if (newsize <= 0) {   /* nonstandard usage */
            if (indata) {
                free(indata);
                *pindata = NULL;
            }
            return NULL;
        }

        if (!indata) {  /* nonstandard usage */
            if ((newdata = (void *)calloc(1, newsize)) == NULL)
                return NULL;
            return newdata;
        }

        /* Standard usage */
        if ((newdata = (void *)calloc(1, newsize)) == NULL)
            return NULL;
        minsize = min(oldsize, newsize);
        memcpy((char *)newdata, (char *)indata, minsize);

        free(indata);
        *pindata = NULL;

        return newdata;
    }

    PtrArray *ptraCreate(int n) {
        PtrArray *pa;

        if (n <= 0)
            n = 20;

        pa = (PtrArray *)calloc(1, sizeof(PtrArray));
        if ((pa->array = (void **)calloc(n, sizeof(void *))) == NULL) {
            ptraDestroy(&pa, 0, 0);
            return (PtrArray *)NULL;
        }
        pa->nalloc = n;
        pa->imax = -1;
        pa->nactual = 0;
        return pa;
    }

    void ptraDestroy(PtrArray **ppa,
                     int freeflag,
                     int warnflag) {

        int i, nactual;
        void *item;
        PtrArray *pa;

        if (ppa == NULL) {
            return;
        }
        if ((pa = *ppa) == NULL)
            return;

        ptraGetActualCount(pa, &nactual);
        if (nactual > 0) {
            if (freeflag) {
                for (i = 0; i <= pa->imax; i++) {
                    if ((item = ptraRemove(pa, i, L_NO_COMPACTION)) != NULL)
                        free(item);
                }
            }
        }

        free(pa->array);
        free(pa);
        *ppa = NULL;
        return;
    }

    int ptraGetActualCount(PtrArray *pa,
                           int *pcount) {

        if (!pa)
            return 1;
        if (!pcount)
            return 1;
        *pcount = pa->nactual;

        return 0;
    }

    void *ptraRemove(PtrArray *pa,
                     int index,
                     int flag) {

        int i, imax, fromend, icurrent;
        void *item;

        if (!pa)
            return (void *)NULL;
        ptraGetMaxIndex(pa, &imax);
        if (index < 0 || index > imax)
            return (void *)NULL;

        item = pa->array[index];
        if (item)
            pa->nactual--;
        pa->array[index] = NULL;

        /* If we took the last item, need to reduce pa->n */
        fromend = (index == imax);
        if (fromend) {
            for (i = index - 1; i >= 0; i--) {
                if (pa->array[i])
                    break;
            }
            pa->imax = i;
        }

        /* Compact from index to the end of the array */
        if (!fromend && flag == L_COMPACTION) {
            for (icurrent = index, i = index + 1; i <= imax; i++) {
                if (pa->array[i])
                    pa->array[icurrent++] = pa->array[i];
            }
            pa->imax = icurrent - 1;
        }
        return item;
    }

    void *ptraRemoveLast(PtrArray *pa) {
        int imax;

        if (!pa)
            return (void *)NULL;

        /* Remove the last item in the array.  No compaction is required. */
        ptraGetMaxIndex(pa, &imax);
        if (imax >= 0)
            return ptraRemove(pa, imax, L_NO_COMPACTION);
        else  /* empty */
            return NULL;
    }

    int ptraGetMaxIndex(PtrArray *pa,
                        int *pmaxindex) {
        if (!pa)
            return 1;
        if (!pmaxindex)
            return 1;
        *pmaxindex = pa->imax;
        return 0;
    }

    void *ptraGetPtrToItem(PtrArray *pa,
                           int index) {

        if (!pa)
            return (void *)NULL;
        if (index < 0 || index >= pa->nalloc)
            return (void *)NULL;

        return pa->array[index];
    }

    static int ptraExtendArray(PtrArray *pa) {
        if (!pa)
            return 1;

        if ((pa->array = (void **)reallocNew((void **)&pa->array,
                                             sizeof(void *) * pa->nalloc,
                                             2 * sizeof(void *) * pa->nalloc)) == NULL)
            return 1;

        pa->nalloc *= 2;
        return 0;
    }

    int ptraInsert(PtrArray *pa,
                   int index,
                   void *item,
                   int shiftflag) {
        int i, ihole, imax;
        double nexpected;

        if (!pa)
            return 1;
        if (index < 0 || index > pa->nalloc)
            return 1;
        if (shiftflag != L_AUTO_DOWNSHIFT && shiftflag != L_MIN_DOWNSHIFT &&
            shiftflag != L_FULL_DOWNSHIFT)
            return 1;

        if (item) pa->nactual++;
        if (index == pa->nalloc) {  /* can happen when index == n */
            if (ptraExtendArray(pa))
                return 1;
        }

        /* We are inserting into a hole or adding to the end of the array.
         * No existing items are moved. */
        ptraGetMaxIndex(pa, &imax);
        if (pa->array[index] == NULL) {
            pa->array[index] = item;
            if (item && index > imax)  /* new item put beyond max so far */
                pa->imax = index;
            return 0;
        }

        /* We are inserting at the location of an existing item,
         * forcing the existing item and those below to shift down.
         * First, extend the array automatically if the last element
         * (nalloc - 1) is occupied (imax).  This may not be necessary
         * in every situation, but only an anomalous sequence of insertions
         * into the array would cause extra ptr allocation.  */
        if (imax >= pa->nalloc - 1 && ptraExtendArray(pa))
            return 1;

        /* If there are no holes, do a full downshift.
         * Otherwise, if L_AUTO_DOWNSHIFT, use the expected number
         * of holes between index and n to determine the shift mode */
        if (imax + 1 == pa->nactual) {
            shiftflag = L_FULL_DOWNSHIFT;
        } else if (shiftflag == L_AUTO_DOWNSHIFT) {
            if (imax < 10) {
                shiftflag = L_FULL_DOWNSHIFT;  /* no big deal */
            } else {
                nexpected = (double)(imax - pa->nactual) *
                (double)((imax - index) / imax);
                shiftflag = (nexpected > 2.0) ? L_MIN_DOWNSHIFT : L_FULL_DOWNSHIFT;
            }
        }

        if (shiftflag == L_MIN_DOWNSHIFT) {  /* run down looking for a hole */
            for (ihole = index + 1; ihole <= imax; ihole++) {
                if (pa->array[ihole] == NULL)
                    break;
            }
        } else {  /* L_FULL_DOWNSHIFT */
            ihole = imax + 1;
        }

        for (i = ihole; i > index; i--)
            pa->array[i] = pa->array[i - 1];
        pa->array[index] = (void *)item;
        if (ihole == imax + 1)  /* the last item was shifted down */
            pa->imax++;

        return 0;
    }


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

    int getQuadraticLSF(std::vector<Point2d> *pta,
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
            Point2d p = pta->at(i); /* not a copy */
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
                Point2d p = pta->at(i); /* not a copy */
                x = p.x;
                y = g[0] * x * x + g[1] * x + g[2];
                (*pnafit)->push_back(y);
            }
        }
        return 0;
    }

    int applyQuadraticFit(float a,
                          float b,
                          float c,
                          float x,
                          float *py) {
        if (!py)
            return 1;

        *py = a * x * x + b * x + c;
        return 0;
    }

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

        paindex = ptraCreate(isize + 1);
        n = (int)nas->size();
        for (i = 0; i < n; i++) {
            ival = (*nas)[i];
            nai = (std::vector<double> *)ptraGetPtrToItem(paindex, ival);
            if (!nai) {  /* make it; no shifting will occur */
                nai = new std::vector<double>();
                ptraInsert(paindex, ival, nai, L_MIN_DOWNSHIFT);
            }
            nai->push_back(i);
        }

        /* Sort by scanning the ptra, extracting numas and pulling
         * the (index into nas) numbers out of each numa, taken
         * successively in requested order. */
        ptraGetMaxIndex(paindex, &imax);
        nad = new std::vector<double>();
        if (sortorder == L_SORT_INCREASING) {
            for (i = 0; i <= imax; i++) {
                na = (std::vector<double> *)ptraRemove(paindex, i, L_NO_COMPACTION);
                if (!na) continue;
                join(nad, na, 0, -1);
                free(na);
            }
        } else {  /* L_SORT_DECREASING */
            for (i = imax; i >= 0; i--) {
                na = (std::vector<double> *)ptraRemoveLast(paindex);
                if (!na) break;  /* they've all been removed */
                join(nad, na, 0, -1);
                free(na);
            }
        }

        ptraDestroy(&paindex, false, false);
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

    std::vector<std::vector<cv::Point2d>> * sortByIndex(std::vector<std::vector<cv::Point2d>> *ptaas,
                                                        std::vector<double> *naindex) {
        int i, n, index;
        std::vector<cv::Point2d> *pta;
        std::vector<std::vector<cv::Point2d>> *ptaad;

        if (!ptaas)
            return (std::vector<std::vector<cv::Point2d>> *)NULL;
        if (!naindex)
            return (std::vector<std::vector<cv::Point2d>> *)NULL;

        n = (int)ptaas->size();
        if (naindex->size() != n)
            return (std::vector<std::vector<cv::Point2d>> *)NULL;
        ptaad = new std::vector<std::vector<cv::Point2d>>();
        for (i = 0; i < n; i++) {
            index = (*naindex)[i];
            pta = &(*ptaas)[index];
            ptaad->push_back(*pta);
        }

        return ptaad;
    }
}
