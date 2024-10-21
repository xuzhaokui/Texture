//
//  ASDisplayNode+Draw.h
//  AsyncDisplayKit
//
//  Created by xuzhaokui on 2024/10/20.
//  Copyright © 2024 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASGraphicsContext.h>

/**
 Design: https://github.com/xuzhaokui/Gatherana/issues/143
 */

@interface ASDisplayNode (DrawWithIsCancelledBlock)

typedef void(^asyncdisplaykit_draw_block_t)(void);

/**
 * Completely finish all the layout spec computes and build all subnodes relation potentially(which layoutIfNeeded does not ensure).
 * Can be called from any thread.
 */
- (void)completeLayoutIfNeeded;

/**
 * Recursively draw the whole nodes' content to the CGContext on the current thread.
 * Must ensure completeLayoutIfNeeded be called first, and this function can be called from any thread.
 */
- (void)drawWithIsCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock;

@end
