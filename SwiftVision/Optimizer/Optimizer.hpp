#ifndef Optimizer_hpp
#define Optimizer_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>
#import "KeyPointProjector.hpp"

using namespace std;
using namespace cv;

struct OptimizerResult {
    double fun;
    double dur;
    std::vector<double> x;
};

class CostFunction:public MinProblemSolver::Function {
public:
    CostFunction(vector<Point2f> _destinationPoints, vector<Point2f> _keyPointIndexes);
    virtual ~CostFunction();
    void setInput(vector<double> input);
private:
    int getDims() const;
    double calc(const double* x) const;
    vector<double> inputParams;
    vector<Point2f> destinationPoints;
    vector<Point2f> keyPointIndexes;
    KeyPointProjector *projector;
};

class Optimizer {
public:
    Optimizer(Ptr<CostFunction> fn, vector<double> x);
    OptimizerResult optimize();
    double optimizeOnce(vector<double> params);
private:
    Ptr<DownhillSolver> solver;
    vector<double> params;
};

#endif /* Optimizer_hpp */

