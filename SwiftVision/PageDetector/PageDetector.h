#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

/**
 * Detects an sheet of paper within an image.
 * You may either retrieve the boundary of the page (as a CGRectOutline) and then
 * subsequently extract it using extract:fromImage: or call the extractPage: method
 * to directly extract the page.
 *
 * All extracted images are deskewed based on the page outline provided.
 */
@interface PageDetector : NSObject
@property (nonatomic, assign) CGFloat minArea;
@property (nonatomic, assign) CGFloat maxArea;

/**
 * if true, the extracted page will be processed (thresholded) before returned.
 * useful for black and white pages of text
 * default is false
 */
@property (nonatomic, assign) BOOL shouldPostProcess;
/**
 * if true, the input image should be pre processed before attempting to
 * find the page outline. set to false if you prefer to perform your
 * own pre processing.
 * default is true
 */
@property (nonatomic, assign) BOOL shouldPreprocess;
/**
 * Returns a "page" outline as a CGRectOutline struct.
 * This method analyzes 'image' and returns the largest rectangular outline
 * contained within.
 */
- (CGRectOutline)pageOutline:(UIImage *_Nonnull)image;
/**
 * Returns the "page" extracted and deskewed.
 * if no valid page "outline" is found then the entire image is returned
 */
- (UIImage *_Nullable)extractPage:(UIImage *_Nonnull)image;
/**
 * Returns the "page" extracted using 'outline' and then deskewed
 */
- (UIImage *_Nullable)extract:(CGRectOutline)outline fromImage:(UIImage *_Nonnull)image;
/**
 * Returns 'image' with a boundary indicator rendered around the outline of any 'page' in 'image'.
 * if no 'page' is found then 'image' is returned
 */
- (UIImage *_Nullable)renderPageOutline:(UIImage *_Nonnull)image;
/**
 * Returns 'image' with a boundary indicator rendered around 'outline'
 */
- (UIImage *_Nullable)render:(CGRectOutline)outline inImage:(UIImage *_Nonnull)image;
/**
 * Returns the contents of 'image' extracted from 'outline' and then deskewed.
 */
- (UIImage *_Nullable)deskew:(UIImage *_Nonnull)image withOutline:(CGRectOutline)outline;

/**
 * denormalize a CGRectOutline
 */
- (CGRectOutline)denormalize:(CGRectOutline)outline withSize:(CGSize)size;

/**
 * returns the processed version of 'image' used during "page" outline detection
 */
- (UIImage *_Nullable)process:(UIImage *_Nonnull)image;
@end
