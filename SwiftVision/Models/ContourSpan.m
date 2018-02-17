#import "ContourSpan.h"
#import "Contour.h"

@interface ContourSpan ()
@property (nonatomic, strong) NSMutableArray <Contour *> *contours;
@end

@implementation ContourSpan

- (instancetype)init {
    self = [super init];
    self.contours = @[].mutableCopy;
    return self;
}

- (void)addContour:(Contour *)contour {
    [self.contours addObject:contour];
}

- (void)removeContour:(Contour *)contour {
    [self.contours removeObject:contour];
}

@end
