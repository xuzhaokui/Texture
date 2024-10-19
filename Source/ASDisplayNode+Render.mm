#import <CoreGraphics/CoreGraphics.h>
#import <AsyncDisplayKit/ASDisplayNode+Render.h>

@implementation ASDisplayNode (renderInContext)

- (void)renderInContext:(CGContextRef)ctx
                atScale:(CGFloat)scale
       isCancelledBlock:(BOOL (^)(void))isCancelledBlock
{
}

@end
