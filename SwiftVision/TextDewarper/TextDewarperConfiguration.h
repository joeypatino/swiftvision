#import <UIKit/UIKit.h>

@interface TextDewarperConfiguration : NSObject
@property (nonatomic, assign) UIEdgeInsets inputMaskInsets;    // inset amount for mask on top/right/bottom/left borders

@property (nonatomic, assign) int contourMinWidth;      // min px width of detected text contour
@property (nonatomic, assign) int contourMinHeight;     // min px height of detected text contour
@property (nonatomic, assign) float contourMinAspect;   // filter out text contours below this w/h ratio
@property (nonatomic, assign) int contourMaxThickness;  // max px thickness of detected text contour
@property (nonatomic, assign) int contourSpanMinWidth;

@property (nonatomic, assign) float contourEdgeMaxOverlap;  // max px horiz. overlap of contours in span
@property (nonatomic, assign) float contourEdgeMaxLength;   // max px length of edge connecting contours
@property (nonatomic, assign) float contourEdgeMaxAngle;    // maximum change in angle allowed between contours

@property (nonatomic, assign) int contourSpanSamplingInterval;

@end
