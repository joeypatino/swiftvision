#include "PtraArray.hpp"
#include <stdio.h>
#include <vector>

using namespace std;

namespace dewarp {
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
}
