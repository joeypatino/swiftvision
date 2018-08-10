#ifndef cg_rect_outline_h
#define cg_rect_outline_h


struct CGRectOutline {
    CGPoint topLeft;
    CGPoint botLeft;
    CGPoint botRight;
    CGPoint topRight;
};
typedef struct CG_BOXABLE CGRectOutline CGRectOutline;

CG_INLINE CGRectOutline
CGRectOutlineMake(CGPoint topLeft, CGPoint topRight, CGPoint botRight, CGPoint botLeft);

CG_INLINE bool
CGRectOutlineEquals(CGRectOutline outline1, CGRectOutline outline2);

#define CGRectOutlineZero CGRectOutlineMake(CGPointZero, CGPointZero, CGPointZero, CGPointZero)

/*** Definitions of inline functions. ***/

inline CGRectOutline
CGRectOutlineMake(CGPoint topLeft, CGPoint topRight, CGPoint botRight, CGPoint botLeft) {
    return (CGRectOutline){
        .topLeft = topLeft,
        .botLeft = botLeft,
        .botRight = botRight,
        .topRight = topRight
    };
};

inline bool
CGRectOutlineEquals(CGRectOutline outline1, CGRectOutline outline2) {
    return (CGPointEqualToPoint(outline1.topLeft, outline2.topLeft) &&
            CGPointEqualToPoint(outline1.topRight, outline2.topRight) &&
            CGPointEqualToPoint(outline1.botLeft, outline2.botLeft) &&
            CGPointEqualToPoint(outline1.botRight, outline2.botRight));
};

#endif /* cg_rect_outline_h */
