#import <UIKit/UIKit.h>

@class Contour;
@class ContourSpan;
@interface UIImage (Contour)
- (NSArray<Contour *> *_Nonnull)contoursFilteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter NS_SWIFT_NAME(contours(filteredBy:));
- (NSArray<ContourSpan *> *_Nonnull)spansFromContours:(NSArray<Contour *> *_Nonnull)contours NS_SWIFT_NAME(spans(from:));
@end
