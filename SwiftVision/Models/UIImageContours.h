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
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image filteredBy:(nullable BOOL (^)(Contour * _Nonnull c))filter;
- (UIImage * _Nullable)render NS_SWIFT_NAME(render());
- (UIImage * _Nullable)render:(UIColor * _Nonnull)color mode:(ContourRenderingMode)mode NS_SWIFT_NAME(render(inColor:mode:));
- (UIImage * _Nullable)renderMasks NS_SWIFT_NAME(renderMasks());
- (Contour * _Nullable)objectAtIndexedSubscript:(NSInteger)idx;
- (NSInteger)count;
@end

