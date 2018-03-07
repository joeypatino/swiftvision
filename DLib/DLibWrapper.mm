#import "DLibWrapper.h"
#import <dlib/optimization.h>
#include <iostream>

using namespace std;
using namespace dlib;

// ----------------------------------------------------------------------------------------

// In dlib, most of the general purpose solvers optimize functions that take a
// column vector as input and return a double.  So here we make a typedef for a
// variable length column vector of doubles.  This is the type we will use to
// represent the input to our objective functions which we will be minimizing.
typedef matrix<double, 0, 1> column_vector;

@implementation DLibWrapper
- (void)rundlib {

    column_vector starting_point = {-4, 5, 99, 3};
    column_vector target = {3, 5, 1, 7};
    auto be_like_target = [&](const column_vector& x) {
        return mean(squared(x-target));
    };
    find_min_bobyqa(be_like_target,
                    starting_point,
                    9,    // number of interpolation points
                    uniform_matrix<double>(4,1, -1e100),  // lower bound constraint
                    uniform_matrix<double>(4,1, 1e100),   // upper bound constraint
                    10,    // initial trust region radius
                    1e-6,  // stopping trust region radius
                    100    // max number of objective function evaluations
                    );
    cout << "be_like_target solution:\n" << starting_point << endl;
}

@end
