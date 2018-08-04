#ifndef leptonica_hpp
#define leptonica_hpp

#import <opencv2/opencv.hpp>
#import "types.h"
#include <stdio.h>
#include <vector>
#include <cassert>

using namespace std;
using namespace cv;

/*----------------------------------------------------------------------------*
 *                              Sort flags                                    *
 *----------------------------------------------------------------------------*/

/*! Sort mode flags */
enum {
    L_SHELL_SORT = 1,            /*!< use shell sort                        */
    L_BIN_SORT = 2               /*!< use bin sort                          */
};

/*! Sort order flags */
enum {
    L_SORT_INCREASING = 1,       /*!< sort in increasing order              */
    L_SORT_DECREASING = 2        /*!< sort in decreasing order              */
};

/*! Sort type flags */
enum {
    L_SORT_BY_X = 1,             /*!< sort box or c.c. by left edge location  */
    L_SORT_BY_Y = 2             /*!< sort box or c.c. by top edge location   */
};

namespace leptonica {
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

    std::vector<double> *sort(std::vector<double> *naout,
                              std::vector<double> *nain,
                              int sortorder);

    std::vector<std::vector<DPoint>> *sortByIndex(std::vector<std::vector<DPoint>> *ptaas,
                                                  std::vector<double> *naindex);
    std::vector<DPoint> *sortByIndex(std::vector<DPoint> *ptas,
                                     std::vector<double> *naindex);
    std::vector<DPoint> *sort(std::vector<DPoint> *ptas,
                              int sorttype,
                              int sortorder,
                              std::vector<double> **pnaindex);
    int getSortIndex(std::vector<DPoint> *ptas,
                     int sorttype,
                     int sortorder,
                     std::vector<double> **pnaindex);

    std::vector<double> *sortByIndex(std::vector<double>*nas,
                                     std::vector<double>*naindex);

    std::vector<double> *binSort(std::vector<double> *nas,
                                 int sortorder);

    std::vector<double> *getBinSortIndex(std::vector<double> *nas,
                                         int sortorder);

    std::vector<double> *getSortIndex(std::vector<double> *na,
                                      int sortorder);
}
#endif /* leptonica_hpp */




