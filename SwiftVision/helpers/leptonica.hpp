#ifndef leptonica_hpp
#define leptonica_hpp

#import <opencv2/opencv.hpp>
#include <stdio.h>
#include <vector>
#include <cassert>

using namespace std;
using namespace cv;

struct PtrArray
{
    int          nalloc;    /*!< size of allocated ptr array         */
    int          imax;      /*!< greatest valid index                */
    int          nactual;   /*!< actual number of stored elements    */
    void         **array;   /*!< ptr array                           */
};
typedef struct PtrArray  PtrArray;

/*------------------------------------------------------------------------*
 *                              Array flags                               *
 *------------------------------------------------------------------------*/

/*! Flags for removal from PtraArray */
enum {
    L_NO_COMPACTION = 1,        /*!< null the pointer only                */
    L_COMPACTION = 2            /*!< compact the array                    */
};

/*! Flags for insertion into PtraArray */
enum {
    L_AUTO_DOWNSHIFT = 0,     /*!< choose based on number of holes        */
    L_MIN_DOWNSHIFT = 1,      /*!< downshifts min # of ptrs below insert  */
    L_FULL_DOWNSHIFT = 2      /*!< downshifts all ptrs below insert       */
};

/*! Accessor flags for PtraArray */
enum {
    L_HANDLE_ONLY = 0,     /*!< ptr to PtraArray; caller can inspect only   */
    L_REMOVE = 1           /*!< caller owns; destroy or save in PtraArray   */
};

/*! Sort order flags */
enum {
    L_SORT_INCREASING = 1,       /*!< sort in increasing order              */
    L_SORT_DECREASING = 2        /*!< sort in decreasing order              */
};

#ifndef ABSX
/*! Absoulute value of %x */
#define ABSX(x)     (((x) < 0) ? (-1 * (x)) : (x))
#endif


namespace leptonica {
    int gaussjordan(double **a,
                    double *b,
                    int n);
    int getQuadraticLSF(std::vector<Point2d> *pta,
                        double *pa,
                        double *pb,
                        double *pc,
                        std::vector<double> **pnafit);
    int applyQuadraticFit(float a,
                          float b,
                          float c,
                          float x,
                          float *py);
    int getMedianVariation(std::vector<double> *na,
                           double *pmedval,
                           double *pmedvar);


    // Helpers
    int getMin(std::vector<double> *na,
               double *pminval,
               int *piminloc);
    int getMax(std::vector<double> *na,
               double *pmaxval,
               int *pimaxloc);
    int getMedian(std::vector<double> *na,
                  double *pval);

    int getRankValue(std::vector<double> *na,
                     double fract,
                     std::vector<double> *nasort,
                     int usebins,
                     double *pval);

    std::vector<double>* sort(std::vector<double> *naout,
                              std::vector<double> *nain,
                              int sortorder);

    std::vector<std::vector<cv::Point2d>> * sortByIndex(std::vector<std::vector<cv::Point2d>> *ptaas,
                                                        std::vector<double> *naindex);
    
    std::vector<double> *sortByIndex(std::vector<double>*nas,
                                     std::vector<double>*naindex);

    std::vector<double> *binSort(std::vector<double> *nas,
                                 int sortorder);

    std::vector<double> *getBinSortIndex(std::vector<double> *nas,
                                         int sortorder);

    std::vector<double> *getSortIndex(std::vector<double> *na,
                                      int sortorder);


    // PtrArray
    PtrArray * ptraCreate(int n);

    void ptraDestroy(PtrArray **ppa,
                     int freeflag,
                     int warnflag);

    int ptraGetActualCount(PtrArray *pa,
                           int *pcount);
    void *ptraRemove(PtrArray *pa,
                     int index,
                     int flag);

    int ptraGetMaxIndex(PtrArray *pa,
                        int *pmaxindex);

    void *ptraGetPtrToItem(PtrArray *pa,
                           int index);

    int ptraInsert(PtrArray  *pa,
                   int index,
                   void *item,
                   int shiftflag);
}
#endif /* leptonica_hpp */



