#import "KeyPointOptimizer.h"
#import <dlib/optimization.h>

using namespace std;
using namespace dlib;

@implementation KeyPointOptimizer
- (instancetype)initWithBaseParameters:(NSArray <NSNumber *> *)params
                     destinationPoints:(NSArray <NSValue *> *)dstPoints
                       keyPointIndexes:(NSArray <NSValue *> *)keyPointIndexes {
    self = [super init];
    _baseParameters = params;
    _destinationPoints = dstPoints;
    _keyPointIndexes = keyPointIndexes;
    return self;
}

- (void)optimizeWithObjective:(double (^)(std::vector<double> vector))objective {
//    matrix<double> target_vector;
//    matrix<double> starting_point;
        auto be_like_target = [&](const matrix<double>& x) {
            return objective(std::vector<double>(x));
        };
//    find_min_bobyqa(be_like_target,
//                    starting_point,
//                    9,    // number of interpolation points
//                    uniform_matrix<double>(4,1, -1e100),  // lower bound constraint
//                    uniform_matrix<double>(4,1, 1e100),   // upper bound constraint
//                    10,    // initial trust region radius
//                    1e-6,  // stopping trust region radius
//                    100    // max number of objective function evaluations
//                    );
//    cout << "be_like_target solution:\n" << starting_point << endl;
}
@end
