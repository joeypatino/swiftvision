#ifndef CornerPointCostFunction_hpp
#define CornerPointCostFunction_hpp

#include <stdio.h>
#include "CostFunction.hpp"

using namespace std;
using namespace cv;

class CornerPointCostFunction: public CostFunction {
public:
    explicit CornerPointCostFunction(vector<Point2d> _destinationPoints, vector<double> _keyPoints);
    virtual ~CornerPointCostFunction();
    virtual double calc(const double* x) const;

private:
    vector<double> keyPoints;
    vector<Point2d> destinationPoints;
    KeyPointProjector *projector;
};

#endif /* CornerPointCostFunction_hpp */
