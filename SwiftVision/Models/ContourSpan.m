#import "ContourSpan.h"
#import "Contour.h"

@interface ContourSpan ()
@property (nonatomic, strong) NSMutableArray <Contour *> *contoursInSpan;
@end

@implementation ContourSpan

- (instancetype)init {
    self = [super init];
    self.contoursInSpan = @[].mutableCopy;
    return self;
}

- (void)addContour:(Contour *)contour {
    [self.contoursInSpan addObject:contour];
}

- (void)removeContour:(Contour *)contour {
    [self.contoursInSpan removeObject:contour];
}

- (NSArray <Contour *> *)contours {
    return self.contoursInSpan;
}

@end
