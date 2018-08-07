#ifndef datatypes_h
#define datatypes_h

#include <stdio.h>
#include <vector>
#include "PtraArray.hpp"

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

#endif /* datatypes_h */
