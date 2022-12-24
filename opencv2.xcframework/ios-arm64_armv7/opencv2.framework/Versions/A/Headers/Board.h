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


@class Dictionary;
@class IntVector;
@class Mat;
@class Point3f;
@class Size2i;



NS_ASSUME_NONNULL_BEGIN

// C++: class Board
/**
 * Board of ArUco markers
 *
 * A board is a set of markers in the 3D space with a common coordinate system.
 * The common form of a board of marker is a planar (2D) board, however any 3D layout can be used.
 * A Board object is composed by:
 * - The object points of the marker corners, i.e. their coordinates respect to the board system.
 * - The dictionary which indicates the type of markers of the board
 * - The identifier of all the markers in the board.
 *
 * Member of `Objdetect`
 */
CV_EXPORTS @interface Board : NSObject


#ifdef __cplusplus
@property(readonly)cv::Ptr<cv::aruco::Board> nativePtr;
#endif

#ifdef __cplusplus
- (instancetype)initWithNativePtr:(cv::Ptr<cv::aruco::Board>)nativePtr;
+ (instancetype)fromNative:(cv::Ptr<cv::aruco::Board>)nativePtr;
#endif


#pragma mark - Methods


//
//  void cv::aruco::Board::generateImage(Size outSize, Mat& img, int marginSize = 0, int borderBits = 1)
//
/**
 * Draw a planar board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 * @param marginSize minimum margins (in pixels) of the board in the output image
 * @param borderBits width of the marker borders.
 *
 * This function return the image of the GridBoard, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img marginSize:(int)marginSize borderBits:(int)borderBits NS_SWIFT_NAME(generateImage(outSize:img:marginSize:borderBits:));

/**
 * Draw a planar board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 * @param marginSize minimum margins (in pixels) of the board in the output image
 *
 * This function return the image of the GridBoard, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img marginSize:(int)marginSize NS_SWIFT_NAME(generateImage(outSize:img:marginSize:));

/**
 * Draw a planar board
 *
 * @param outSize size of the output image in pixels.
 * @param img output image with the board. The size of this image will be outSize
 * and the board will be on the center, keeping the board proportions.
 *
 * This function return the image of the GridBoard, ready to be printed.
 */
- (void)generateImage:(Size2i*)outSize img:(Mat*)img NS_SWIFT_NAME(generateImage(outSize:img:));


//
// static Ptr_Board cv::aruco::Board::create(vector_Mat objPoints, Dictionary dictionary, Mat ids)
//
/**
 * Provide way to create Board by passing necessary data. Specially needed in Python.
 *
 * @param objPoints array of object points of all the marker corners in the board
 * @param dictionary the dictionary of markers employed for this board
 * @param ids vector of the identifiers of the markers in the board
 */
+ (Board*)create:(NSArray<Mat*>*)objPoints dictionary:(Dictionary*)dictionary ids:(Mat*)ids NS_SWIFT_NAME(create(objPoints:dictionary:ids:));


//
//  Dictionary cv::aruco::Board::getDictionary()
//
/**
 * return the Dictionary of markers employed for this board
 */
- (Dictionary*)getDictionary NS_SWIFT_NAME(getDictionary());


//
//  vector_vector_Point3f cv::aruco::Board::getObjPoints()
//
/**
 * return array of object points of all the marker corners in the board.
 *
 * Each marker include its 4 corners in this order:
 * -   objPoints[i][0] - left-top point of i-th marker
 * -   objPoints[i][1] - right-top point of i-th marker
 * -   objPoints[i][2] - right-bottom point of i-th marker
 * -   objPoints[i][3] - left-bottom point of i-th marker
 *
 * Markers are placed in a certain order - row by row, left to right in every row. For M markers, the size is Mx4.
 */
- (NSArray<NSArray<Point3f*>*>*)getObjPoints NS_SWIFT_NAME(getObjPoints());


//
//  vector_int cv::aruco::Board::getIds()
//
/**
 * vector of the identifiers of the markers in the board (should be the same size as objPoints)
 * @return vector of the identifiers of the markers
 */
- (IntVector*)getIds NS_SWIFT_NAME(getIds());


//
//  Point3f cv::aruco::Board::getRightBottomCorner()
//
/**
 * get coordinate of the bottom right corner of the board, is set when calling the function create()
 */
- (Point3f*)getRightBottomCorner NS_SWIFT_NAME(getRightBottomCorner());


//
//  void cv::aruco::Board::matchImagePoints(vector_Mat detectedCorners, Mat detectedIds, Mat& objPoints, Mat& imgPoints)
//
/**
 * Given a board configuration and a set of detected markers, returns the corresponding
 * image points and object points to call solvePnP
 *
 * @param detectedCorners List of detected marker corners of the board.
 * @param detectedIds List of identifiers for each marker.
 * @param objPoints Vector of vectors of board marker points in the board coordinate space.
 * @param imgPoints Vector of vectors of the projections of board marker corner points.
 */
- (void)matchImagePoints:(NSArray<Mat*>*)detectedCorners detectedIds:(Mat*)detectedIds objPoints:(Mat*)objPoints imgPoints:(Mat*)imgPoints NS_SWIFT_NAME(matchImagePoints(detectedCorners:detectedIds:objPoints:imgPoints:));



@end

NS_ASSUME_NONNULL_END


