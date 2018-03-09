#include "functions.h"

// MARK: - Geometry
namespace geom {
    double angleDistance(double angle_b, double angle_a) {
        double diff = angle_b - angle_a;

        while (diff > M_PI) {
            diff -= 2 * M_PI;
        }
        while (diff < -M_PI) {
            diff += 2 * M_PI;
        }
        return abs(diff);
    }

    double intervalOverlap(CGPoint int_a, CGPoint int_b) {
        return MIN(int_a.y, int_b.y) - MAX(int_a.x, int_b.x);
    }


    CGPoint subtract(CGPoint p1, CGPoint p2) {
        return CGPointMake(p1.x - p2.x, p1.y - p2.y);
    }

    cv::Point2f subtract(CGPoint p, float d) {
        return cv::Point2f(p.x - d, p.y - d);
    }

    float sum(cv::Point2f p) {
        return p.x + p.y;
    }

    cv::Point2f multi(cv::Point2f p1, cv::Point2f p2) {
        return cv::Point2f(p1.x * p2.x, p1.y * p2.y);
    }

    cv::Point2f multi(cv::Point2f p, float x) {
        return cv::Point2f(p.x * x, p.y * x);
    }


    CGPoint convertTo(cv::Point2f point) {
        return CGPointMake(point.x, point.y);
    }

    cv::Point2f convertTo(CGPoint point) {
        return cv::Point2f(point.x, point.y);
    }


    CGRectOutline outlineWithSize(CGSize size) {

#define PAGE_MARGIN_X 0
#define PAGE_MARGIN_Y 0

        int xmin = PAGE_MARGIN_X;
        int ymin = PAGE_MARGIN_Y;
        int xmax = int(size.width) - PAGE_MARGIN_X;
        int ymax = int(size.height) - PAGE_MARGIN_Y;

        return CGRectOutlineMake(CGPointMake(xmin, ymin),
                                 CGPointMake(xmin, ymax),
                                 CGPointMake(xmax, ymax),
                                 CGPointMake(xmax, ymin));
    }
}

namespace math {
    double polyval(std::vector<double> p, double x) {
        double output = 0;
        double polyCnt = p.size();
        for (int i = 0; i < polyCnt; i++) {
            output += p[i] * pow(x, (polyCnt-1)-i);
        }
        return output;
    }

    std::vector<double> polyval(std::vector<double> p, std::vector<double> x) {
        long polyCnt = x.size();
        std::vector<double> output = std::vector<double>(polyCnt, 1);
        for (int i = 0; i < polyCnt; i++) {
            output[i] = polyval(p, x[i]);
        }
        return output;
    }
}

namespace nsarray {
    NSArray <NSValue *> * add(NSArray <NSValue *> *points, cv::Point2f pt) {
        NSMutableArray *multipliedPts = @[].mutableCopy;
        for (NSValue *point in points) {
            CGPoint multipliedPt = CGPointMake(point.CGPointValue.x + pt.x, point.CGPointValue.y + pt.y);
            [multipliedPts addObject:[NSValue valueWithCGPoint:multipliedPt]];
        }
        return [NSArray arrayWithArray:multipliedPts];
    }

    NSArray <NSNumber *> * subtract(NSArray <NSNumber *> *values, float value) {
        NSMutableArray <NSNumber *> *mutatedValues = @[].mutableCopy;
        for (NSNumber *number in values) {
            [mutatedValues addObject:[NSNumber numberWithFloat:number.floatValue - value]];
        }
        return [NSArray arrayWithArray:mutatedValues];
    }

    NSArray <NSValue *> * multi(NSArray <NSValue *> *points, float scale) {
        NSMutableArray *multipliedPts = @[].mutableCopy;
        for (NSValue *point in points) {
            CGPoint multipliedPt = CGPointMake(point.CGPointValue.x * scale, point.CGPointValue.y * scale);
            [multipliedPts addObject:[NSValue valueWithCGPoint:multipliedPt]];
        }
        return [NSArray arrayWithArray:multipliedPts];
    }
    
    NSArray <NSNumber *> * dotProduct(NSArray <NSValue *> *points, cv::Point2f pt) {
        NSMutableArray *multipliedPts = @[].mutableCopy;
        for (NSValue *point in points) {
            [multipliedPts addObject:[NSNumber numberWithFloat:point.CGPointValue.x * pt.x + point.CGPointValue.y * pt.y]];
        }
        return [NSArray arrayWithArray:multipliedPts];
    }


    NSArray<NSValue *> * pix2norm(CGSize size, NSArray<NSValue *> *points) {
        float height = size.height;
        float width = size.width;
        float scale = 2.0 / MAX(height, width);
        CGSize offset = CGSizeMake(width * 0.5, height * 0.5);

        NSMutableArray<NSValue *> *mutatedPts = @[].mutableCopy;
        for (NSValue *point in points) {
            CGPoint mutatedPoint = CGPointMake((point.CGPointValue.x - offset.width) * scale, (point.CGPointValue.y - offset.height) * scale);
            [mutatedPts addObject:[NSValue valueWithCGPoint:mutatedPoint]];
        }
        return mutatedPts;
    }

    NSArray <NSValue *> * norm2pix(CGSize size, NSArray <NSValue *> *points) {
        float scale = MAX(size.height, size.width) * 0.5;
        cv::Point2f offset = cv::Point2f(0.5 * size.width, 0.5 * size.height);
        NSArray <NSValue *> *rval = nsarray::add(nsarray::multi(points, scale), offset);
        return rval;
    }


    std::vector<cv::Point2f>convertTo2f(NSArray <NSValue *> *points) {
        std::vector<cv::Point2f> vectorPoints = std::vector<cv::Point2f>();
        for (NSValue *point in points) {
            vectorPoints.push_back(geom::convertTo(point.CGPointValue));
        }
        return vectorPoints;
    }

    std::vector<double> convertTo(NSArray <NSValue *> *values) {
        std::vector<double> output = std::vector<double>(values.count * 2, 1);
        for (int i = 0; i < values.count; i++) {
            CGPoint point = values[i].CGPointValue;
            output[i*2] = point.x;
            output[(i*2)+1] = point.y;
        }

        return output;
    }

    std::vector<double> convertTo(NSArray <NSNumber *> *numbers) {
        std::vector<double> output = std::vector<double>(numbers.count, 1);
        for (int i = 0; i < numbers.count; i++) {
            NSNumber *number = numbers[i];
            output[i] = number.floatValue;
        }

        return output;
    }


    NSArray <NSValue *> * pointsFrom(CGRectOutline cornerOutline) {
        return @[[NSValue valueWithCGPoint:cornerOutline.topLeft],
                 [NSValue valueWithCGPoint:cornerOutline.botLeft],
                 [NSValue valueWithCGPoint:cornerOutline.botRight],
                 [NSValue valueWithCGPoint:cornerOutline.topRight]];
    }


    NSArray <NSNumber *> * numbersAlongAxis(int axis, NSArray <NSValue *> *values) {
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
}

namespace vectors {
    std::vector<std::vector<double>> hstack(std::vector<std::vector<double>> mat1, std::vector<std::vector<double>> mat2) {
        // rows then cols
        int mat1R = int(mat1.size());
        int mat2R = int(mat2.size());
        int mat1C = int(mat1[0].size());
        int mat2C = int(mat2[0].size());
        assert(mat1R == mat2R);
        std::vector<std::vector<double>> output(mat1R, std::vector<double>(mat1C + mat2C, 0));
        for (int r = 0; r < mat1R; r++) {
            for (int m1 = 0; m1 < mat1C; m1++) {
                output[r][m1] = mat1[r][m1];
            }
            for (int m2 = 0; m2 < mat2C; m2++) {
                output[r][m2 + mat1C] = mat2[r][m2];
            }
        }
        return output;
    }

    std::vector<std::vector<double>> reshape(std::vector<double> p, int rows, int cols) {
        assert(rows * cols == p.size());
        std::vector<std::vector<double>> output(rows, std::vector<double>(cols, 0));
        int i = 0;
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                output[r][c] = p[i];
                i++;
            }
        }
        return output;
    }

    NSArray <NSValue *> * convertTo(std::vector<std::vector<int>> vector) {
        assert(vector.size() == 2);
        NSMutableArray <NSValue *> *output = @[].mutableCopy;
        int numCols = int(vector.size());
        int numRows = int(vector[0].size());
        for (int y = 0; y < numRows; y++) {
            int v[2];
            for (int x = 0; x < numCols; x++) {
                v[x] = vector[x][y];
            }
            [output addObject:[NSValue valueWithCGPoint:CGPointMake(v[0], v[1])]];
        }

        return output;
    }
}

// MARK: - Loggging
namespace logs {
    void describe_vector(std::vector<std::vector<double>> vector, char const *name) {
        printf("\n# %s #\n", name);
        printf("----------------------------\n");
        int numCols = int(vector.size());
        int numRows = int(vector[0].size());
        printf("[");
        for (int x = 0; x < numCols; x++) {
            printf("[");
            for (int y = 0; y < numRows; y++) {
                double z = vector[x][y];
                printf("%f", z);
                if (y < numRows-1) { printf(", "); }
            }
            if (x < numCols-1) { printf("]\n"); }
            else { printf("]"); }
        }
        printf("]\n");
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<double> vector, char const *name) {
        printf("\n# %s #\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");
        int numRows = int(vector.size());
        printf("[");
        for (int x = 0; x < numRows; x++) {
            double z = vector[x];
            printf("%f", z);
            if (x < numRows-1) { printf(",\n"); }
            else { printf("]\n"); }
        }
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point> vector, char const *name ) {
        printf("\n############ cv::Point %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point2f> vector, char const *name ) {
        printf("\n############ cv::Point2f %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point3f> vector, char const *name) {
        printf("\n############ cv::Point3f %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector( cv::Mat mat, char const *name ) {
        printf("\n############ cv::Mat::%s ############\n", name);
        printf("type: %i\n", mat.type());
        printf("depth: %i\n", mat.depth());
        printf("dims: %i\n", mat.dims);
        printf("channels: %i\n", mat.channels());
        printf("size: {%i, %i}\n", mat.size().height, mat.size().width);
        printf("shape: {");
        for (int i = 0; i < mat.dims; ++i) {
            printf("%i", mat.size[i]);
            if (i < mat.dims - 1){ printf(", "); }
        }
        printf(", %i", mat.cols);
        printf("}\n");
        printf("total: %zul\n", mat.total());
        printf("----------------------------\n");

        std::cout << mat << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_values(NSArray <NSNumber *> *pts, char const *name) {
        printf("\n############ values::%s ############\n", name);
        for (NSNumber *ptNumber in pts) {
            printf("%f\n", ptNumber.floatValue);
        }

        printf("\n############ values::%s ############\n", name);
    }

    void describe_points(NSArray <NSValue *> *pts, char const *name) {
        printf("\n############ Points::%s ############\n", name);

        printf("[");
        for (NSValue *ptValue in pts) {
            printf("[%f, %f]", ptValue.CGPointValue.x, ptValue.CGPointValue.y);
            if (pts.lastObject == ptValue) {
                printf("]\n");
            } else {
                printf("\n");
            }
        }

        printf("\n############ Points::%s ############\n", name);
    }
}
