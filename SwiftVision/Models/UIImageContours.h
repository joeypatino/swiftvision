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
- (instancetype)initWithImage:(UIImage *)image;

- (NSInteger)count;
- (Contour *)objectAtIndexedSubscript:(NSInteger)idx;
- (void)setObject:(Contour *)obj atIndexedSubscript:(NSInteger)idx;

@end
