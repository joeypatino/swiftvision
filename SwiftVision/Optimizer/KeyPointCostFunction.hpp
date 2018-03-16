#ifndef KeyPointCostFunction_hpp
#define KeyPointCostFunction_hpp

#include <stdio.h>
#include "CostFunction.hpp"

using namespace std;
using namespace cv;

class KeyPointCostFunction: public CostFunction {
public:
    explicit KeyPointCostFunction(vector<Point2d> _destinationPoints, vector<Point2d> _keyPointIndexes);
    virtual ~KeyPointCostFunction();
    virtual double calc(const double* x) const;
private:
    vector<Point2d> destinationPoints;
    vector<Point2d> keyPointIndexes;
    KeyPointProjector *projector;
};

#endif /* KeyPointCostFunction_hpp */
