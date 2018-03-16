#ifndef CostFunction_hpp
#define CostFunction_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>
#import "KeyPointProjector.hpp"

using namespace std;
using namespace cv;

class CostFunction:public MinProblemSolver::Function {
public:
    virtual double calc(const double* x) const;
    int getDims() const;
    void setParameters(vector<double> input);
    vector<double> getParameters() const;

private:
    vector<double> inputParams;
};

#endif /* CostFunction_hpp */
