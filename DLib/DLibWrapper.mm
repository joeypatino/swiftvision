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

double polyval(matrix<double> p, double x) {
    double output = 0;
    double polyCnt = p.nr();
    for (int i = 0; i < polyCnt; i++) {
        output += p(i, 0) * pow(x, (polyCnt-1)-i);
    }
    return output;
}

matrix<double> polyval(matrix<double> p, matrix<double> x) {
    long polyCnt = x.nr();
    matrix<double> output = matrix<double>(polyCnt, 1);
    for (int i = 0; i < polyCnt; i++) {
        output(i, 0) = polyval(p, x(i, 0));
    }
    return output;
}

matrix<double> hstack(matrix<double> mat1, matrix<double> mat2) {
    assert(mat1.nr() == mat2.nr());
    int mat1R = int(mat1.nr());
    int mat1C = int(mat1.nc());
    int mat2C = int(mat2.nc());
    matrix<double> output = matrix<double>(mat1R, mat1C + mat2C);
    for (int r = 0; r < mat1R; r++) {
        for (int m1 = 0; m1 < mat1C; m1++) {
            output(r, m1) = mat1(r, m1);
        }
        for (int m2 = 0; m2 < mat2C; m2++) {
            output(r, m2 + mat1C) = mat2(r, m2);
        }
    }
    return output;
}

NSArray <NSNumber *> * numbersAlongAxis(int axis, NSArray <NSValue *> *values){
    NSMutableArray <NSNumber *> *numbers = @[].mutableCopy;
    for (NSValue *value in values) {
        if (axis == 0) {
            [numbers addObject:[NSNumber numberWithFloat:value.CGPointValue.x]];
        } else {
            [numbers addObject:[NSNumber numberWithFloat:value.CGPointValue.y]];
        }
    }
    return [NSArray arrayWithArray:numbers];
}

column_vector convertTo(NSArray <NSValue *> *values) {
    column_vector output = column_vector(values.count * 2, 1);
    for (int i = 0; i < values.count; i++) {
        CGPoint point = values[i].CGPointValue;
        output(i*2, 0) = point.x;
        output((i*2)+1, 0) = point.y;
    }

    return output;
}

column_vector convertTo(NSArray <NSNumber *> *numbers) {
    column_vector output = column_vector(numbers.count, 1);
    for (int i = 0; i < numbers.count; i++) {
        NSNumber *number = numbers[i];
        output(i, 0) = number.floatValue;
    }

    return output;
}

@implementation DLibWrapper
- (void)testPolyval {
    matrix<double> p = {3,0,1};
    cout << "p: \n" << p << endl;
    matrix<double> x = {5,9,8};
    cout << "x: \n" << x << endl;
    matrix<double> res = polyval(p,x);
    cout << "res:: " << endl;
    cout << "\n------\n" << endl;
    cout << res << endl;
    cout << "------" << endl;
}

- (void)testHStack {
    matrix<double> p = {3,0,1};
    cout << "p: \n" << p << endl;

    matrix<double, 3, 2> x = matrix<double, 3, 2>({0,5, 3,3, 1,9});
    cout << "x: \n" << x << endl;

    matrix<double> stack = hstack(x, p);
    cout << "stack:: " << endl;
    cout << "\n------\n" << endl;
    cout << stack << endl;
    cout << "------" << endl;
}

- (void)testResize {
    NSArray <NSValue *> *values = @[[NSValue valueWithCGPoint:CGPointMake(4, 7)],
                                    [NSValue valueWithCGPoint:CGPointMake(3, 6)],
                                    [NSValue valueWithCGPoint:CGPointMake(8, 4)],
                                    [NSValue valueWithCGPoint:CGPointMake(25, 53)],
                                    [NSValue valueWithCGPoint:CGPointMake(34, 64)],
                                    [NSValue valueWithCGPoint:CGPointMake(12, 54)],
                                    [NSValue valueWithCGPoint:CGPointMake(90, 43)],
                                    [NSValue valueWithCGPoint:CGPointMake(12, 21)],
                                    [NSValue valueWithCGPoint:CGPointMake(34, 12)],
                                    [NSValue valueWithCGPoint:CGPointMake(3, 5)],
                                    [NSValue valueWithCGPoint:CGPointMake(1, 4)],
                                    [NSValue valueWithCGPoint:CGPointMake(0, 3)]];

    matrix<double> output = reshape(convertTo(values), values.count, 2);
    cout << "output:: " << endl;
    cout << "\n------\n" << endl;
    cout << output << endl;
    cout << "------" << endl;
}

- (void)optimize:(NSArray <NSNumber *> *)params to:(NSArray <NSValue *> *)dstPoints keyPointIdx:(NSArray <NSValue *> *)keyPointIndexes {

}

- (void)minimize:(NSArray <NSNumber *> *)params to:(NSArray <NSValue *> *)dstpoints {
    //[self testPolyval];
    //[self testHStack];
    //[self testResize];

//    column_vector target_vector;
//    column_vector starting_point = convertTo(params);
//    auto be_like_target = [&](const column_vector& x) {
//        return mean(squared(x-target_vector));
//    };
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

- (NSArray <NSValue *> *)projectKeypoints:(NSArray <NSValue *> *)keyPoints of:(NSArray <NSNumber *> *)vectors {
    NSMutableArray <NSValue *> *projectedValues = @[].mutableCopy;
    for (NSValue *value in keyPoints) {
        int x = value.CGPointValue.x;
        int y = value.CGPointValue.y;
        float xvec = vectors[x].floatValue;
        float yvec = vectors[y].floatValue;
        CGPoint projectedPoint = CGPointMake(xvec, yvec);
        [projectedValues addObject:[NSValue valueWithCGPoint:projectedPoint]];
    }
    [projectedValues replaceObjectAtIndex:0 withObject:[NSValue valueWithCGPoint:CGPointZero]];
    return [self projectXY:projectedValues of:vectors];
}

- (NSArray <NSValue *> *)projectXY:(NSArray <NSValue *> *)xyCoordsArr of:(NSArray <NSNumber *> *)vectors {
    // get cubic polynomial coefficients given
    //
    //  f(0) = 0, f'(0) = alpha
    //  f(1) = 0, f'(1) = beta

    /**
     RVEC_IDX = slice(0, 3)   # index of rvec in params vector
     TVEC_IDX = slice(3, 6)   # index of tvec in params vector
     CUBIC_IDX = slice(6, 8)  # index of cubic slopes in params vector
     */

    // slice [6] and [7]
    float alpha = vectors[6].floatValue;
    float beta = vectors[7].floatValue;

    column_vector poly = {alpha + beta, -2*alpha - beta, alpha, 0};
    NSArray <NSNumber *> *xCoordsArr = numbersAlongAxis(0, xyCoordsArr);
    matrix<double> xCoords = convertTo(xCoordsArr);
    matrix<double> zCoords = polyval(poly, xCoords);

    matrix<double> xyCoords = reshape(convertTo(xyCoordsArr), xyCoordsArr.count, 2);
    matrix<double> objPoints = hstack(xyCoords, zCoords);
//    [xyCoords + zCoords]

    return @[];
}

@end
