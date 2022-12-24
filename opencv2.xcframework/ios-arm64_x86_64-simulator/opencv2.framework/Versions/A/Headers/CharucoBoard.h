//
// This file is auto-generated. Please don't modify it!
//
#pragma once

#ifdef __cplusplus
//#import "opencv.hpp"
#import "opencv2/objdetect.hpp"
#import "opencv2/objdetect/aruco_board.hpp"
#else
#define CV_EXPORTS
#endif

#import <Foundation/Foundation.h>
#import "Board.h"

@class Dictionary;
@class Mat;
@class Point3f;
@class Size2i;



NS_ASSUME_NONNULL_BEGIN

// C++: class CharucoBoard
/**
 * ChArUco board is a planar chessboard where the markers are placed inside the white squares of a chessboard.
 *
 * The benefits of ChArUco boards is that they provide both, ArUco markers versatility and chessboard corner precision,
 * which is important for calibration and pose estimation. The board image can be drawn using generateImage() method.
 *
 * Member of `Objdetect`
 */
CV_EXPORTS @interface CharucoBoard : Board


#ifdef __cplusplus
@property(readonly)cv::Ptr<cv::aruco::CharucoBoard> nativePtrCharucoBoard;
#endif

#ifdef __cplusplus
- (instancetype)initWithNativePtr:(cv::Ptr<cv::aruco::CharucoBoard>)nativePtr;
+ (instancetype)fromNative:(cv::Ptr<cv::aruco::CharucoBoard>)nativePtr;
#endif


#pragma mark - Methods


//
//  void cv::aruco::CharucoBoard::generateImage(Size outSize, Mat& img, int marginSize = 0, int borderBits = 1)
//
/**
 * Draw a ChArUco board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 * @param marginSize minimum margins (in pixels) of the board in the output image
 * @param borderBits width of the marker borders.
 *
 * This function return the image of the ChArUco board, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img marginSize:(int)marginSize borderBits:(int)borderBits NS_SWIFT_NAME(generateImage(outSize:img:marginSize:borderBits:));

/**
 * Draw a ChArUco board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 * @param marginSize minimum margins (in pixels) of the board in the output image
 *
 * This function return the image of the ChArUco board, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img marginSize:(int)marginSize NS_SWIFT_NAME(generateImage(outSize:img:marginSize:));

/**
 * Draw a ChArUco board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 *
 * This function return the image of the ChArUco board, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img NS_SWIFT_NAME(generateImage(outSize:img:));


//
// static Ptr_CharucoBoard cv::aruco::CharucoBoard::create(int squaresX, int squaresY, float squareLength, float markerLength, Dictionary dictionary, Mat ids = Mat())
//
/**
 * Create a CharucoBoard object
 *
 * @param squaresX number of chessboard squares in X direction
 * @param squaresY number of chessboard squares in Y direction
 * @param squareLength chessboard square side length (normally in meters)
 * @param markerLength marker side length (same unit than squareLength)
 * @param dictionary dictionary of markers indicating the type of markers.
 * @param ids array of id used markers
 * The first markers in the dictionary are used to fill the white chessboard squares.
 * @return the output CharucoBoard object
 *
 * This functions creates a CharucoBoard object given the number of squares in each direction
 * and the size of the markers and chessboard squares.
 */
+ (CharucoBoard*)create:(int)squaresX squaresY:(int)squaresY squareLength:(float)squareLength markerLength:(float)markerLength dictionary:(Dictionary*)dictionary ids:(Mat*)ids NS_SWIFT_NAME(create(squaresX:squaresY:squareLength:markerLength:dictionary:ids:));

/**
 * Create a CharucoBoard object
 *
 * @param squaresX number of chessboard squares in X direction
 * @param squaresY number of chessboard squares in Y direction
 * @param squareLength chessboard square side length (normally in meters)
 * @param markerLength marker side length (same unit than squareLength)
 * @param dictionary dictionary of markers indicating the type of markers.
 * The first markers in the dictionary are used to fill the white chessboard squares.
 * @return the output CharucoBoard object
 *
 * This functions creates a CharucoBoard object given the number of squares in each direction
 * and the size of the markers and chessboard squares.
 */
+ (CharucoBoard*)create:(int)squaresX squaresY:(int)squaresY squareLength:(float)squareLength markerLength:(float)markerLength dictionary:(Dictionary*)dictionary NS_SWIFT_NAME(create(squaresX:squaresY:squareLength:markerLength:dictionary:));


//
//  Size cv::aruco::CharucoBoard::getChessboardSize()
//
- (Size2i*)getChessboardSize NS_SWIFT_NAME(getChessboardSize());


//
//  float cv::aruco::CharucoBoard::getSquareLength()
//
- (float)getSquareLength NS_SWIFT_NAME(getSquareLength());


//
//  float cv::aruco::CharucoBoard::getMarkerLength()
//
- (float)getMarkerLength NS_SWIFT_NAME(getMarkerLength());


//
//  vector_Point3f cv::aruco::CharucoBoard::getChessboardCorners()
//
/**
 * get CharucoBoard::chessboardCorners
 */
- (NSArray<Point3f*>*)getChessboardCorners NS_SWIFT_NAME(getChessboardCorners());


//
//  bool cv::aruco::CharucoBoard::checkCharucoCornersCollinear(Mat charucoIds)
//
/**
 * check whether the ChArUco markers are collinear
 *
 * @param charucoIds list of identifiers for each corner in charucoCorners per frame.
 * @return bool value, 1 (true) if detected corners form a line, 0 (false) if they do not.
 * solvePnP, calibration functions will fail if the corners are collinear (true).
 *
 * The number of ids in charucoIDs should be <= the number of chessboard corners in the board.
 * This functions checks whether the charuco corners are on a straight line (returns true, if so), or not (false).
 * Axis parallel, as well as diagonal and other straight lines detected.  Degenerate cases:
 * for number of charucoIDs <= 2,the function returns true.
 */
- (BOOL)checkCharucoCornersCollinear:(Mat*)charucoIds NS_SWIFT_NAME(checkCharucoCornersCollinear(charucoIds:));



@end

NS_ASSUME_NONNULL_END


