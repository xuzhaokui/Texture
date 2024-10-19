#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AsyncDisplayKit/ASDisplayNode.h>

@interface ASDisplayNode (renderInContext)

- (void)renderInContext:(CGContextRef)ctx atScale:(CGFloat)scale isCancelledBlock:(BOOL (^)(void))isCancelledBlock;

@end
