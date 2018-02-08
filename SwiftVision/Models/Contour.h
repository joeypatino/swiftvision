#import <UIKit/UIKit.h>

@interface Contour: NSObject
@property (nonatomic, assign, readonly) CGPoint *_Nonnull points;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGFloat aspect;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, assign, readonly) CGFloat area;
@end
