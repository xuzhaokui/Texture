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

@interface ASDisplayNode (DrawAtScale)

typedef void(^asyncdisplaykit_draw_block_t)(void);

- (void)drawAtScale:(CGFloat)scale isCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock;

@end
