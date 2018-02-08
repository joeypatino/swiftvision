#import <UIKit/UIKit.h>
#import "Contour.h"

struct CGRectOutline {
    CGPoint topLeft;
    CGPoint botLeft;
    CGPoint botRight;
    CGPoint topRight;
};

static inline struct CGRectOutline
CGRectOutlineMake(CGPoint topLeft, CGPoint botLeft, CGPoint botRight, CGPoint topRight) {
    struct CGRectOutline outline;

    outline.topLeft = topLeft;
    outline.botLeft = botLeft;
    outline.botRight = botRight;
    outline.topRight = topRight;

    return outline;
}

@class Contour;
@interface UIImageContours : NSObject
@property (nonatomic, strong, readonly) UIImage * _Nullable renderedContours;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image NS_DESIGNATED_INITIALIZER;
- (UIImage * _Nullable)renderedContours:(nullable BOOL (^)(Contour * _Nonnull contour))filtered;
- (Contour * _Nullable)objectAtIndexedSubscript:(NSInteger)idx;
- (NSInteger)count;
@end
