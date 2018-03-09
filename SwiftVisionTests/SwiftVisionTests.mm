#import "functions.h"
#import <XCTest/XCTest.h>

@interface SwiftVisionTests : XCTestCase

@end

@implementation SwiftVisionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPolyval {
    const std::vector<double> p = {3,0,1};
    printf("p: [%f, %f, %f]\n", p[0], p[1], p[2]);

    const std::vector<double> x = {5,9,8};
    printf("x: [%f, %f, %f]\n", x[0], x[1], x[2]);

    const std::vector<double> v = math::polyval(p,x);
    printf("r: [%f, %f, %f]\n", v[0], v[1], v[2]);
}

- (void)testHStack {
    std::vector<std::vector<double>> p = {{3},{0},{1}};
    logs::describe_vector(p, "p");

    std::vector<std::vector<double>> x = {{0,5}, {3,3}, {1,9}};
    logs::describe_vector(x, "x");

    std::vector<std::vector<double>> result = vectors::hstack(x, p);
    logs::describe_vector(result, "result");
}

- (void)testReshape {
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
    std::vector<std::vector<double>> result = vectors::reshape(nsarray::convertTo(values), int(values.count), 2);
    logs::describe_vector(result, "result");
}
@end
