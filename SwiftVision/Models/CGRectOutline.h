#import <UIKit/UIKit.h>

struct
CGRectOutline {
    CGPoint topLeft;
    CGPoint botLeft;
    CGPoint botRight;
    CGPoint topRight;
};
typedef struct CG_BOXABLE CGRectOutline CGRectOutline;

static inline struct CGRectOutline
CGRectOutlineMake(CGPoint topLeft, CGPoint botLeft, CGPoint botRight, CGPoint topRight) {
    struct CGRectOutline outline;

    outline.topLeft = topLeft;
    outline.botLeft = botLeft;
    outline.botRight = botRight;
    outline.topRight = topRight;

    return outline;
}
