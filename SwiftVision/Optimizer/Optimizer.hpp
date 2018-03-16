#ifndef Optimizer_hpp
#define Optimizer_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>
#include "CostFunction.hpp"

using namespace std;
using namespace cv;

struct OptimizerResult {
    double fun;
    double dur;
    vector<double> x;
};

class Optimizer {
public:
    Optimizer(Ptr<CostFunction> fn, vector<double> x);
    OptimizerResult optimize();
    OptimizerResult initialOptimization();
private:
    Ptr<DownhillSolver> solver;
    vector<double> parameters;
};

#endif /* Optimizer_hpp */

