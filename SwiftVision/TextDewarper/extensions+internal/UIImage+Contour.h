#import <UIKit/UIKit.h>

@class Contour;
@class ContourSpan;
@class TextDewarperConfiguration;
@interface UIImage (Contour)
- (NSArray<Contour *> *_Nonnull)contoursFilteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter usingConfiguration:(TextDewarperConfiguration *_Nonnull)configuration NS_SWIFT_NAME(contours(filteredBy:using:));
- (NSArray<ContourSpan *> *_Nonnull)spansFromContours:(NSArray<Contour *> *_Nonnull)contours  usingConfiguration:(TextDewarperConfiguration *_Nonnull)configuration NS_SWIFT_NAME(spans(from:using:));
@end
