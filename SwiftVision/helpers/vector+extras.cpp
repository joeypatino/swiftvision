#include "vector+extras.hpp"

namespace vectors {
    vector_dd hstack(vector_dd mat1, vector_dd mat2) {
        // rows then cols
        int mat1R = int(mat1.size());
        int mat2R = int(mat2.size());
        int mat1C = int(mat1[0].size());
        int mat2C = int(mat2[0].size());
        assert(mat1R == mat2R);
        vector<vector<double>> output(mat1R, vector<double>(mat1C + mat2C, 0));
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

    vector_dd reshape(vector_d p, int rows, int cols) {
        assert(rows * cols == p.size());
        vector_dd output(rows, vector<double>(cols, 0));
        int i = 0;
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                output[r][c] = p[i];
                i++;
            }
        }
        return output;
    }

    vector_dd reshape(vector_dd p, int rows, int cols) {
        int totalSize = int(p.size() * p[0].size());
        vector_d output;
        for (int r = 0; r < p.size(); r++){
            vector_d row = p[r];
            for (int c = 0; c < row.size(); c++) {
                output.push_back(row[c]);
            }
        }

        return reshape(output, totalSize, cols);
    }

    vector_dd* createdd(double r, double c) {
        return new std::vector<std::vector<double>>(r, std::vector<double>(c, 0));
    }

    void meshgrid(std::vector<double> x, std::vector<double> y, std::vector<std::vector<double>> *xx, std::vector<std::vector<double>> *yy) {
        int xsize = int(x.size());
        int ysize = int(y.size());
        for (int r = 0; r < ysize; r++){
            for (int c = 0; c < xsize; c++){
                yy->at(r).at(c) = y[r];
                xx->at(r).at(c) = x[c];
            }
        }
    }

    vector<double> axis(int x, vector<Point2d> points) {
        vector<double> v;
        for (int i = 0; i < points.size(); i++) {
            Point2d p = points[i];
            if (x == 0) {
                v.push_back(p.x);
            } else if (x == 1) {
                v.push_back(p.y);
            }
        }
        return v;
    }

    vector<vector<double>> convert_to_vector2d(vector<Point2d> points) {
        vector<vector<double>> v(points.size(), vector<double>(2, 0));
        for (int i = 0; i < points.size(); i++) {
            cv::Point2d point = points[i];
            v[i][0] = point.x;
            v[i][1] = point.y;
        }
        return v;
    }

    std::vector<double> dotProduct(std::vector<cv::Point2d> points, cv::Point2d x) {
        std::vector<double> res;
        for (int i = 0; i < points.size(); i++){
            double p = points[i].x * x.x + points[i].y * x.y;
            res.push_back(p);
        }
        return res;
    }

    std::vector<double> subtract(std::vector<double> b, double x) {
        std::vector<double> res;
        for (int i = 0; i < b.size(); i++) {
            res.push_back(b[i] - x);
        }
        return res;
    }

    std::vector<cv::Point2d> add(std::vector<cv::Point2d> points, cv::Point2f pt) {
        std::vector<cv::Point2d> pts;
        for (int i = 0; i < points.size(); i++) {
            cv::Point2d point = points[i];
            cv::Point2d res = cv::Point2d(point.x + pt.x, point.y + pt.y);
            pts.push_back(res);
        }
        return pts;
    }

    std::vector<cv::Point2d> multi(std::vector<cv::Point2d> points, float scale) {
        std::vector<cv::Point2d> pts;
        for (int i = 0; i < points.size(); i++) {
            cv::Point2d point = points[i];
            cv::Point2d res = cv::Point2d(point.x * scale, point.y * scale);
            pts.push_back(res);
        }
        return pts;
    }

    std::vector<cv::Point2d> pix2norm(cv::Size2d size, std::vector<cv::Point2d> points) {
        float height = size.height;
        float width = size.width;
        float scale = 2.0 / MAX(height, width);
        cv::Size2d offset = cv::Size(width * 0.5, height * 0.5);

        std::vector<cv::Point2d> pts;
        for (int i = 0; i < points.size(); i++) {
            cv::Point2d point = points[i];
            cv::Point2d pt = cv::Point2d((point.x - offset.width) * scale, (point.y - offset.height) * scale);
            pts.push_back(pt);
        }
        return pts;
    }

    std::vector<cv::Point2d> norm2pix(cv::Size2d size, std::vector<cv::Point2d> points) {
        float scale = MAX(size.height, size.width) * 0.5;
        cv::Point2f offset = cv::Point2f(0.5 * size.width, 0.5 * size.height);
        return add(multi(points, scale), offset);
    }
}
