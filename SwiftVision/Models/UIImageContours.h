#import <UIKit/UIKit.h>
#import "Contour.h"
#import "ContourSpan.h"
#import "ContourEdge.h"
#import "CGRectOutline.h"

typedef NS_ENUM(NSUInteger, ContourRenderingMode) {
    ContourRenderingModeOutline,
    ContourRenderingModeFill
};

@interface UIImageContours : NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image NS_DESIGNATED_INITIALIZER;
- (UIImage * _Nullable)render:(nullable BOOL (^)(Contour * _Nonnull contour))filter NS_SWIFT_NAME(render(filteredBy:));
- (UIImage * _Nullable)render:(UIColor * _Nonnull)color mode:(ContourRenderingMode)mode filtered:(nullable BOOL (^)(Contour * _Nonnull c))filter NS_SWIFT_NAME(render(inColor:mode:filteredBy:));
- (UIImage * _Nullable)renderMasks:(nullable BOOL (^)(Contour * _Nonnull c))filter NS_SWIFT_NAME(renderMasks(filteredBy:));
- (Contour * _Nullable)objectAtIndexedSubscript:(NSInteger)idx;
- (NSInteger)count;
@end

