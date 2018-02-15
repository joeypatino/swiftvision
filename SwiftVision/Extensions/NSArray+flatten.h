#import <Foundation/Foundation.h>

@interface NSArray (flatten)
- (void)flatten:(NSMutableArray * _Nonnull)original inArray:(NSMutableArray * _Nonnull)result;
@end
