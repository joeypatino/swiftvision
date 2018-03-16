#ifndef CornerPointCostFunction_hpp
#define CornerPointCostFunction_hpp

#include <stdio.h>
#include "CostFunction.hpp"

using namespace std;
using namespace cv;

class CornerPointCostFunction: public CostFunction {
public:
    explicit CornerPointCostFunction(vector<Point2d> _destinationPoints);
    virtual ~CornerPointCostFunction();
    virtual double calc(const double* x) const;

private:
    vector<Point2d> destinationPoints;
    KeyPointProjector *projector;
};

#endif /* CornerPointCostFunction_hpp */
