#include "vectors.hpp"

namespace vectors {
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

    std::vector<double> dotProduct(std::vector<cv::Point2d> points, cv::Point2d x) {
        std::vector<double> res;
        for (int i = 0; i < points.size(); i++){
            double p = points[i].x * x.x + points[i].y * x.y;
            res.push_back(p);
        }
        return res;
    }

    std::vector<cv::Point2d> norm2pix(cv::Size2d size, std::vector<cv::Point2d> points) {
        float scale = MAX(size.height, size.width) * 0.5;
        cv::Point2d offset = cv::Point2d(0.5 * size.width, 0.5 * size.height);
        return add(multi(points, scale), offset);
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

    std::vector<double> linspace(double a, double b, double N) {
        double h = (b - a) / (N-1);
        std::vector<double> xs(N);
        typename std::vector<double>::iterator x;
        double val;
        for (x = xs.begin(), val = a; x != xs.end(); ++x, val += h) {
            *x = val;
        }
        return xs;
    }
}
