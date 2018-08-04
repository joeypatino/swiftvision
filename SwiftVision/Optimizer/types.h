#ifndef types_h
#define types_h

#include <stdio.h>
#include <vector>

struct DPoint {
    double x;
    double y;
};
typedef struct DPoint DPoint;

struct DSize {
    double width;
    double height;
};
typedef struct DSize DSize;

struct PtrArray
{
    int          nalloc;    /*!< size of allocated ptr array         */
    int          imax;      /*!< greatest valid index                */
    int          nactual;   /*!< actual number of stored elements    */
    void         **array;   /*!< ptr array                           */
};
typedef struct PtrArray  PtrArray;

typedef union suf64 {
    int64_t i;
    uint64_t u;
    double f;
}
suf64;

typedef std::vector<double> vectorD;
typedef std::vector<std::vector<double>> vvectorD;
typedef std::vector<DPoint> vectorPointD;
typedef std::vector<std::vector<DPoint>> vvectorPointD;

#endif /* types_h */
