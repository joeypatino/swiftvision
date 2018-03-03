#import <opencv2/opencv.hpp>
#import "ContourSpanInfo.h"
#import "CGRectOutline.h"

@implementation ContourSpanInfo
- (instancetype)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(NSArray <NSArray <NSNumber *> *> *)xCoordinates
                            yCoordinates:(NSArray <NSNumber *> *)yCoordinates {
    self = [super init];
    _corners = corners;
    _xCoordinates = xCoordinates;
    _yCoordinates = yCoordinates;
    return self;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@",\n [%@, \n%@, \n%@, \n%@]",
     NSStringFromCGPoint(self.corners.topLeft),
     NSStringFromCGPoint(self.corners.topRight),
     NSStringFromCGPoint(self.corners.botRight),
     NSStringFromCGPoint(self.corners.botLeft)];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}
@end
