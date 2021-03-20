#import "TextDewarperConfiguration.h"

@implementation TextDewarperConfiguration
- (instancetype)init {
    self = [super init];
    self.inputMaskInsets = UIEdgeInsetsMake(80, 80, 80, 80);

    self.contourMinWidth = 22;
    self.contourMinHeight = 12;
    self.contourMinAspect = 1.5;
    self.contourMaxThickness = 26;

    self.contourSpanMinWidth = 90;

    self.contourEdgeMaxOverlap = 1.0;
    self.contourEdgeMaxLength = 100;
    self.contourEdgeMaxAngle = 4.5;

    self.contourSpanSamplingInterval = 80;
    return self;
}
@end
