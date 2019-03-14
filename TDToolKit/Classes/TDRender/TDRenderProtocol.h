//
//  TDRenderProtocol.h
//  Pods
//
//  Created by tiandy on 2019/3/6.
//

@import Foundation;
@import UIKit;

@protocol TDRenderProtocol <NSObject>

-(void)setVideoLayer:(CALayer *)layer;
-(void)clearVideoLayer;

-(void)renderPixelBuffer:(CVPixelBufferRef)frameBuffer;
-(void)renderImage:(UIImage *)image;

@end

