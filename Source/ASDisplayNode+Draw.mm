//
//  ASDisplayNode+Draw.mm
//  AsyncDisplayKit
//
//  Created by xuzhaokui on 2024/10/20.
//  Copyright © 2024 Pinterest. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <AsyncDisplayKit/ASDisplayNode+Draw.h>
#import <AsyncDisplayKit/_ASDisplayLayer.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

#define CHECK_CANCELLED_AND_RETURN(expr)                      if (isCancelledBlock()) { \
                                                                    expr; \
                                                                    return; \
                                                                  } \

@interface ASDisplayNode () <_ASDisplayLayerDelegate>
@end

@implementation ASDisplayNode (DrawAtScale)

- (void)drawAtScale:(CGFloat)scale
   isCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context) {
      return;
  }
  // Skip subtrees that are hidden or zero alpha.
  if (self.isHidden || self.alpha <= 0.0) {
    return;
  }
  CGContextSaveGState(context);

  CGContextScaleCTM(context, scale, scale);
  CGContextTranslateCTM(context, self.frame.origin.x, self.frame.origin.y);

  [self _drawSelfAtScale:scale isCancelledBlock:isCancelledBlock];

  for (ASDisplayNode *subnode in self.subnodes) {
    [subnode drawAtScale:scale isCancelledBlock:isCancelledBlock];
  }
  CGContextRestoreGState(context);
}

- (void)_drawSelfAtScale:(CGFloat)scale
        isCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock
{
  __instanceLock__.lock();
  BOOL rasterizingFromAscendent = (_hierarchyState & ASHierarchyStateRasterized);
  __instanceLock__.unlock();

  // if super node is rasterizing descendants, subnodes will not have had layout calls because they don't have layers
  if (rasterizingFromAscendent) {
    [self __layout];
  }

  // Capture these outside the draw block so they are retained.
  UIColor *backgroundColor = self.backgroundColor;
  CGRect bounds = self.bounds;
  CGFloat cornerRadius = self.cornerRadius;
  BOOL clipsToBounds = self.clipsToBounds;

  CGRect frame;

  // If this is the root container node, use a frame with a zero origin to draw into. If not, calculate the correct frame using the node's position, transform and anchorPoint.
  if (self.rasterizesSubtree) {
    frame = CGRectMake(0.0f, 0.0f, bounds.size.width, bounds.size.height);
  } else {
    CGPoint position = self.position;
    CGPoint anchorPoint = self.anchorPoint;

    // Pretty hacky since full 3D transforms aren't actually supported, but attempt to compute the transformed frame of this node so that we can composite it into approximately the right spot.
    CGAffineTransform transform = CATransform3DGetAffineTransform(self.transform);
    CGSize scaledBoundsSize = CGSizeApplyAffineTransform(bounds.size, transform);
    CGPoint origin = CGPointMake(position.x - scaledBoundsSize.width * anchorPoint.x,
                                 position.y - scaledBoundsSize.height * anchorPoint.y);
    frame = CGRectMake(origin.x, origin.y, bounds.size.width, bounds.size.height);
  }

  asyncdisplaykit_draw_block_t drawBlock = ^{
    self->__instanceLock__.lock();
    ASDisplayNodeFlags flags = self->_flags;
    BOOL usesImageDisplay = flags.implementsImageDisplay;
    BOOL usesDrawRect = flags.implementsDrawRect;

    if (usesImageDisplay == NO && usesDrawRect == NO) {
      // Early exit before requesting more expensive properties like bounds and opaque from the layer.
      self->__instanceLock__.unlock();
      return;
    }
    CGRect bounds = self.bounds;
    self->__instanceLock__.unlock();

    // Capture drawParameters from delegate.
    id drawParameters = [self drawParameters];

    // Only the -display methods should be called if we can't size the graphics buffer to use.
    if (CGRectIsEmpty(bounds)) {
      return;
    }
    CHECK_CANCELLED_AND_RETURN();
    if (usesImageDisplay) {    // If we are using a display method, we'll get an image back directly.
      UIImage *image = [self.class displayWithParameters:drawParameters isCancelled:isCancelledBlock];
      if (image) {
        BOOL opaque = ASImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(image.CGImage));
        CGBlendMode blendMode = opaque ? kCGBlendModeCopy : kCGBlendModeNormal;
        [image drawInRect:bounds blendMode:blendMode alpha:1];
      }
    } else if (usesDrawRect) { // If we're using a draw method, this will operate on the currentContext.
      [self.class drawRect:bounds withParameters:drawParameters isCancelled:isCancelledBlock isRasterizing:NO];
    }
  };

  // We'll display something if there is clipping, translation and/or a background color.
  BOOL shouldDisplay = backgroundColor || CGPointEqualToPoint(CGPointZero, frame.origin) == NO || clipsToBounds;

  // If we should display, then push a transform, draw the background color, and draw the contents.
  // The transform is popped in a block added after the recursion into subnodes.
  if (shouldDisplay) {
    CGContextRef context = UIGraphicsGetCurrentContext();

    // support cornerRadius
    if (clipsToBounds) {
      if (cornerRadius) {
        [[UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:cornerRadius] addClip];
      } else {
        CGContextClipToRect(context, bounds);
      }
    }

    // Fill background if any.
    CGColorRef backgroundCGColor = backgroundColor.CGColor;
    if (backgroundColor && CGColorGetAlpha(backgroundCGColor) > 0.0) {
      CGContextSetFillColorWithColor(context, backgroundCGColor);
      CGContextFillRect(context, bounds);
    }

    drawBlock();
  }
}

- (NSObject *)drawParameters
{
  __instanceLock__.lock();
  BOOL implementsDrawParameters = _flags.implementsDrawParameters;
  __instanceLock__.unlock();

  if (implementsDrawParameters) {
    return [self drawParametersForAsyncLayer:self.asyncLayer];
  } else {
    return nil;
  }
}
@end
